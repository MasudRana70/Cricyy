/**
 * models/PlayerMatchStats.js  –  Per-Match Player Performance Cache
 *
 * Stores a player's batting and bowling performance for ONE specific match/innings.
 * This is a CACHE derived from Deliveries – it must always be rebuildable.
 *
 * Career statistics in the Player Profile are aggregated from these records.
 */

'use strict';

const mongoose = require('mongoose');

const playerMatchStatsSchema = new mongoose.Schema(
  {
    playerId : { type: mongoose.Schema.Types.ObjectId, ref: 'Player', required: true },
    matchId  : { type: mongoose.Schema.Types.ObjectId, ref: 'Match',  required: true },
    inningsId: { type: mongoose.Schema.Types.ObjectId, ref: 'Innings',required: true },

    // Which team this player represented in this match
    teamId  : { type: mongoose.Schema.Types.ObjectId, ref: 'Team', required: true },
    teamName: { type: String, required: true }, // snapshot

    // Opponent team (for display in player history)
    opponentTeamId  : { type: mongoose.Schema.Types.ObjectId, ref: 'Team' },
    opponentTeamName: { type: String },

    matchDate  : { type: Date, required: true },
    matchFormat: { type: String, required: true },

    // ── Batting ───────────────────────────────────────────────────────────────
    batting: {
      didBat      : { type: Boolean, default: false },
      runs        : { type: Number, default: 0 },
      balls       : { type: Number, default: 0 },
      fours       : { type: Number, default: 0 },
      sixes       : { type: Number, default: 0 },
      isNotOut    : { type: Boolean, default: false },
      strikeRate  : { type: Number, default: 0 },
      dismissalType: { type: String, default: null },
      dismissedBy : { type: String, default: null }, // bowler name snapshot
      caughtBy    : { type: String, default: null }, // fielder name snapshot
      battingOrder: { type: Number, default: null },
    },

    // ── Bowling ───────────────────────────────────────────────────────────────
    bowling: {
      didBowl    : { type: Boolean, default: false },
      legalBalls : { type: Number, default: 0 },
      overs      : { type: Number, default: 0 }, // decimal e.g. 3.4
      maidens    : { type: Number, default: 0 },
      runs       : { type: Number, default: 0 },
      wickets    : { type: Number, default: 0 },
      wides      : { type: Number, default: 0 },
      noBalls    : { type: Number, default: 0 },
      economy    : { type: Number, default: 0 },
      average    : { type: Number, default: null },
      strikeRate : { type: Number, default: null },
    },
  },
  {
    timestamps: true,
    toJSON    : { virtuals: true },
    toObject  : { virtuals: true },
  }
);

// ── Indexes ───────────────────────────────────────────────────────────────────
playerMatchStatsSchema.index({ playerId: 1, matchDate: -1 }); // career history
playerMatchStatsSchema.index({ matchId: 1, playerId: 1 }, { unique: true });
playerMatchStatsSchema.index({ playerId: 1, matchFormat: 1 }); // format filtering

module.exports = mongoose.model('PlayerMatchStats', playerMatchStatsSchema);
