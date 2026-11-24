/**
 * models/Match.js  –  Match Schema
 *
 * One document per cricket match.
 * Stores teams, format, toss, rules, and high-level result.
 * The detailed scoring lives in Innings and Delivery collections.
 */

'use strict';

const mongoose = require('mongoose');
const {
  MATCH_FORMATS,
  MATCH_STATUS,
  MATCH_RESULT_TYPE,
  RULESETS,
  DEFAULT_RULESET,
} = require('../config/constants');

// ── Embedded: Toss Information ────────────────────────────────────────────────
const tossSchema = new mongoose.Schema(
  {
    winnerTeamId: { type: mongoose.Schema.Types.ObjectId, ref: 'Team', required: true },
    decision    : { type: String, enum: ['bat', 'bowl'], required: true },
  },
  { _id: false }
);

// ── Embedded: Match Result ────────────────────────────────────────────────────
const resultSchema = new mongoose.Schema(
  {
    type         : { type: String, enum: Object.values(MATCH_RESULT_TYPE) },
    winnerTeamId : { type: mongoose.Schema.Types.ObjectId, ref: 'Team', default: null },
    marginRuns   : { type: Number, default: null }, // won by X runs
    marginWickets: { type: Number, default: null }, // won by X wickets
    description  : { type: String, default: null }, // "Team A won by 5 runs"
  },
  { _id: false }
);

// ── Embedded: Bowler-over limits ──────────────────────────────────────────────
const matchRulesSchema = new mongoose.Schema(
  {
    ruleset          : { type: String, enum: Object.values(RULESETS), default: DEFAULT_RULESET },
    maxOversPerBowler: { type: Number, default: null }, // null = no limit
    playersPerSide   : { type: Number, default: 11 },
    overLength       : { type: Number, default: 6 },   // balls per over (usually 6)
    // Add more configurable rule fields here as needed
  },
  { _id: false }
);

// ── Main Match Schema ─────────────────────────────────────────────────────────
const matchSchema = new mongoose.Schema(
  {
    // The two teams
    team1Id: { type: mongoose.Schema.Types.ObjectId, ref: 'Team', required: true },
    team2Id: { type: mongoose.Schema.Types.ObjectId, ref: 'Team', required: true },

    // Names are SNAPSHOT at match creation so renaming a team later
    // doesn't change old scorecards
    team1Name: { type: String, required: true },
    team2Name: { type: String, required: true },

    // Format and overs
    format      : { type: String, enum: Object.values(MATCH_FORMATS), required: true },
    totalOvers  : { type: Number, required: true, min: 1 },

    // Toss
    toss: { type: tossSchema, default: null },

    // Which team bats first
    battingFirstTeamId: { type: mongoose.Schema.Types.ObjectId, ref: 'Team', default: null },

    // Rules applied to this match
    rules: { type: matchRulesSchema, default: () => ({}) },

    // Current match lifecycle state
    status: {
      type   : String,
      enum   : Object.values(MATCH_STATUS),
      default: MATCH_STATUS.SETUP,
    },

    // Filled in when match is completed
    result: { type: resultSchema, default: null },

    // Date the match was actually played (may differ from createdAt)
    matchDate: { type: Date, default: Date.now },

    // Optional venue/location
    venue: { type: String, trim: true, default: null },

    notes: { type: String, trim: true, maxlength: 1000, default: null },
  },
  {
    timestamps: true,
    toJSON    : { virtuals: true },
    toObject  : { virtuals: true },
  }
);

// ── Indexes ───────────────────────────────────────────────────────────────────
matchSchema.index({ status: 1 });
matchSchema.index({ matchDate: -1 });
matchSchema.index({ team1Id: 1, team2Id: 1 });

module.exports = mongoose.model('Match', matchSchema);
