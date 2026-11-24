/**
 * models/Delivery.js  –  Ball-by-Ball Delivery Schema
 *
 * Every single delivery bowled is saved as one document.
 * This is the PRIMARY SOURCE OF TRUTH for all scoring calculations.
 *
 * Rules reference: MCC Laws of Cricket (effective 1 October 2026)
 */

'use strict';

const mongoose = require('mongoose');
const { EXTRA_TYPES, DISMISSAL_TYPES } = require('../config/constants');

// ── Embedded: Wicket Detail ───────────────────────────────────────────────────
const wicketSchema = new mongoose.Schema(
  {
    dismissalType: {
      type    : String,
      enum    : Object.values(DISMISSAL_TYPES),
      required: true,
    },
    dismissedPlayerId  : { type: mongoose.Schema.Types.ObjectId, ref: 'Player', required: true },
    dismissedPlayerName: { type: String, required: true }, // snapshot
    // Fielder who took the catch / effected the run-out / stumped
    fielderPlayerId  : { type: mongoose.Schema.Types.ObjectId, ref: 'Player', default: null },
    fielderPlayerName: { type: String, default: null },
    // Second fielder (some run-out situations)
    fielder2PlayerId  : { type: mongoose.Schema.Types.ObjectId, ref: 'Player', default: null },
    fielder2PlayerName: { type: String, default: null },
    // Does the bowler receive credit for this wicket?
    bowlerCredit: { type: Boolean, required: true },
    // For run-out: how many runs were completed before the dismissal
    runsCompleted: { type: Number, default: 0 },
  },
  { _id: false }
);

// ── Main Delivery Schema ──────────────────────────────────────────────────────
const deliverySchema = new mongoose.Schema(
  {
    matchId  : { type: mongoose.Schema.Types.ObjectId, ref: 'Match',  required: true, index: true },
    inningsId: { type: mongoose.Schema.Types.ObjectId, ref: 'Innings',required: true, index: true },

    // ── Delivery Position ─────────────────────────────────────────────────────
    // Sequence number within the innings (1, 2, 3, ...) – includes no-balls/wides
    deliverySequence: { type: Number, required: true },

    // Over number (0-indexed: over 0 = first over, over 1 = second, ...)
    overNumber: { type: Number, required: true },

    // Ball number within this over (1-indexed legal balls: 1-6)
    // For illegal deliveries this is the same as the previous legal ball
    ballNumber: { type: Number, required: true },

    // Is this a legal delivery? (not a wide or no ball)
    isLegal: { type: Boolean, required: true, default: true },

    // ── Players ───────────────────────────────────────────────────────────────
    strikerId     : { type: mongoose.Schema.Types.ObjectId, ref: 'Player', required: true },
    strikerName   : { type: String, required: true },
    nonStrikerId  : { type: mongoose.Schema.Types.ObjectId, ref: 'Player', required: true },
    nonStrikerName: { type: String, required: true },
    bowlerId      : { type: mongoose.Schema.Types.ObjectId, ref: 'Player', required: true },
    bowlerName    : { type: String, required: true },

    // ── Runs ──────────────────────────────────────────────────────────────────
    // Runs scored by the batter off the bat (does NOT include extras)
    batterRuns: { type: Number, required: true, min: 0, default: 0 },

    // Type of extra (if any)
    extraType: {
      type   : String,
      enum   : Object.values(EXTRA_TYPES),
      default: EXTRA_TYPES.NONE,
    },

    // Extra runs awarded (penalty, wide penalty, etc.)
    extraRuns: { type: Number, default: 0, min: 0 },

    // Total runs added to the team score from this delivery
    // = batterRuns + extraRuns (but NOT byes/leg-byes that go to extras column only)
    totalRuns: { type: Number, required: true, default: 0 },

    // ── Boundary Flags ────────────────────────────────────────────────────────
    isFour: { type: Boolean, default: false },
    isSix : { type: Boolean, default: false },

    // ── Wicket ────────────────────────────────────────────────────────────────
    isWicket: { type: Boolean, default: false },
    wicket  : { type: wicketSchema, default: null },

    // ── Strike Change ─────────────────────────────────────────────────────────
    // Calculated and stored so undo is deterministic
    strikerChangedAfter: { type: Boolean, default: false }, // end-of-over swap
    strikeRotated      : { type: Boolean, default: false }, // odd runs

    // ── State Snapshot (after this delivery) ─────────────────────────────────
    // Cached to make undo O(1): restore previous snapshot instead of replaying
    snapshotAfter: {
      totalRuns     : { type: Number },
      totalWickets  : { type: Number },
      completedOvers: { type: Number },
      ballInOver    : { type: Number },
      strikerId     : { type: mongoose.Schema.Types.ObjectId },
      nonStrikerId  : { type: mongoose.Schema.Types.ObjectId },
      currentBowlerId: { type: mongoose.Schema.Types.ObjectId },
    },

    // ── Soft-delete for Undo ──────────────────────────────────────────────────
    isUndone: { type: Boolean, default: false },

    // Notes / umpire comments
    notes: { type: String, default: null },
  },
  {
    timestamps: true,
    toJSON    : { virtuals: true },
    toObject  : { virtuals: true },
  }
);

// ── Indexes ───────────────────────────────────────────────────────────────────
// Most common query: "give me all deliveries for this innings in order"
deliverySchema.index({ inningsId: 1, deliverySequence: 1 });
deliverySchema.index({ matchId: 1, deliverySequence: 1 });
deliverySchema.index({ strikerId: 1 });
deliverySchema.index({ bowlerId: 1 });

// ── Virtual: Over notation (e.g. "3.4") ──────────────────────────────────────
deliverySchema.virtual('overNotation').get(function () {
  return `${this.overNumber}.${this.ballNumber}`;
});

module.exports = mongoose.model('Delivery', deliverySchema);
