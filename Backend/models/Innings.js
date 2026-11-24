/**
 * models/Innings.js  –  Innings Schema
 *
 * One match has at most 2 innings in limited-overs cricket (more for multi-day).
 * Tracks the LIVE running state of an innings.
 *
 * The authoritative score can always be recalculated from Deliveries,
 * but we cache the current state here for fast API reads.
 */

'use strict';

const mongoose = require('mongoose');
const { INNINGS_STATUS } = require('../config/constants');

// ── Embedded: Batting position tracking ──────────────────────────────────────
// Which batter is at which end, and their current stats for this innings
const batterStateSchema = new mongoose.Schema(
  {
    playerId : { type: mongoose.Schema.Types.ObjectId, ref: 'Player', required: true },
    playerName: { type: String, required: true }, // snapshot
    runs     : { type: Number, default: 0 },
    balls    : { type: Number, default: 0 },
    fours    : { type: Number, default: 0 },
    sixes    : { type: Number, default: 0 },
    isOut    : { type: Boolean, default: false },
    isStriker: { type: Boolean, default: false },
  },
  { _id: false }
);

// ── Embedded: Bowler state tracking ──────────────────────────────────────────
const bowlerStateSchema = new mongoose.Schema(
  {
    playerId  : { type: mongoose.Schema.Types.ObjectId, ref: 'Player', required: true },
    playerName: { type: String, required: true }, // snapshot
    overs     : { type: Number, default: 0 },     // completed overs
    balls     : { type: Number, default: 0 },     // legal balls in current over
    maidens   : { type: Number, default: 0 },
    runs      : { type: Number, default: 0 },     // runs conceded
    wickets   : { type: Number, default: 0 },
    wides     : { type: Number, default: 0 },
    noBalls   : { type: Number, default: 0 },
    isCurrent : { type: Boolean, default: false },
  },
  { _id: false }
);

// ── Embedded: Fall of Wicket ──────────────────────────────────────────────────
const wicketFallSchema = new mongoose.Schema(
  {
    wicketNumber: { type: Number, required: true }, // 1st wicket, 2nd, ...
    score       : { type: Number, required: true }, // team score at the fall
    playerId    : { type: mongoose.Schema.Types.ObjectId, ref: 'Player', required: true },
    playerName  : { type: String, required: true },
    overNumber  : { type: Number, required: true },
    ballNumber  : { type: Number, required: true },
  },
  { _id: false }
);

// ── Embedded: Over summary ────────────────────────────────────────────────────
const overSummarySchema = new mongoose.Schema(
  {
    overNumber : { type: Number, required: true }, // 0-indexed
    bowlerId   : { type: mongoose.Schema.Types.ObjectId, ref: 'Player' },
    bowlerName : { type: String },
    runs       : { type: Number, default: 0 },
    wickets    : { type: Number, default: 0 },
    isMaiden   : { type: Boolean, default: false },
    // ball-by-ball notation string array e.g. ["1","W","wd","4","0","2"]
    balls      : [{ type: String }],
  },
  { _id: false }
);

// ── Main Innings Schema ───────────────────────────────────────────────────────
const inningsSchema = new mongoose.Schema(
  {
    matchId       : { type: mongoose.Schema.Types.ObjectId, ref: 'Match',  required: true },
    inningsNumber : { type: Number, required: true, enum: [1, 2] },

    // Batting team
    battingTeamId  : { type: mongoose.Schema.Types.ObjectId, ref: 'Team', required: true },
    battingTeamName: { type: String, required: true },

    // Bowling team
    bowlingTeamId  : { type: mongoose.Schema.Types.ObjectId, ref: 'Team', required: true },
    bowlingTeamName: { type: String, required: true },

    // ── Live Score Cache ──────────────────────────────────────────────────────
    totalRuns      : { type: Number, default: 0 },
    totalWickets   : { type: Number, default: 0 },
    completedOvers : { type: Number, default: 0 },  // full overs bowled
    currentBallInOver: { type: Number, default: 0 }, // 0-5 within current over
    totalLegalBalls: { type: Number, default: 0 },   // total legal deliveries

    // Extras breakdown
    extras: {
      wides  : { type: Number, default: 0 },
      noBalls: { type: Number, default: 0 },
      byes   : { type: Number, default: 0 },
      legByes: { type: Number, default: 0 },
      penalty: { type: Number, default: 0 },
      total  : { type: Number, default: 0 },
    },

    // Target (set after first innings; null for first innings)
    target: { type: Number, default: null },

    // ── Active Player State ───────────────────────────────────────────────────
    // Currently AT THE CREASE batters (striker + non-striker)
    currentBatters: [batterStateSchema],  // max 2 elements

    // ALL batters who have batted or are batting in this innings
    battersUsed: [batterStateSchema],

    // ALL bowlers who have bowled in this innings
    bowlersUsed: [bowlerStateSchema],

    // ── Historical Data ───────────────────────────────────────────────────────
    fallOfWickets: [wicketFallSchema],
    overSummaries: [overSummarySchema],

    // ── Status ───────────────────────────────────────────────────────────────
    status: {
      type   : String,
      enum   : Object.values(INNINGS_STATUS),
      default: INNINGS_STATUS.NOT_STARTED,
    },

    // Over the innings was declared (Test cricket, future use)
    declaredOver: { type: Number, default: null },
  },
  {
    timestamps: true,
    toJSON    : { virtuals: true },
    toObject  : { virtuals: true },
  }
);

// ── Virtuals ──────────────────────────────────────────────────────────────────
inningsSchema.virtual('currentRunRate').get(function () {
  if (this.totalLegalBalls === 0) return 0;
  const overs = this.totalLegalBalls / 6;
  return parseFloat((this.totalRuns / overs).toFixed(2));
});

// ── Indexes ───────────────────────────────────────────────────────────────────
inningsSchema.index({ matchId: 1, inningsNumber: 1 }, { unique: true });
inningsSchema.index({ matchId: 1 });

module.exports = mongoose.model('Innings', inningsSchema);
