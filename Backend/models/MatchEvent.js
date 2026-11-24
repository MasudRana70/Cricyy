/**
 * models/MatchEvent.js  –  Special Match Events
 *
 * Records non-delivery events such as:
 *   - Penalty runs awarded by the umpire
 *   - Score corrections
 *   - Innings declarations
 *   - Match abandoned / no-result decisions
 *
 * Keeps an audit trail of everything that affects the score
 * but doesn't map to a single delivery.
 */

'use strict';

const mongoose = require('mongoose');

const EVENT_TYPES = {
  PENALTY_RUNS      : 'penalty_runs',
  SCORE_CORRECTION  : 'score_correction',
  INNINGS_DECLARED  : 'innings_declared',
  MATCH_ABANDONED   : 'match_abandoned',
  INNINGS_COMPLETED : 'innings_completed',
  MATCH_COMPLETED   : 'match_completed',
  SUPER_OVER_START  : 'super_over_start',
  OTHER             : 'other',
};

const matchEventSchema = new mongoose.Schema(
  {
    matchId  : { type: mongoose.Schema.Types.ObjectId, ref: 'Match',  required: true },
    inningsId: { type: mongoose.Schema.Types.ObjectId, ref: 'Innings',default: null },

    eventType: {
      type    : String,
      enum    : Object.values(EVENT_TYPES),
      required: true,
    },

    // The team that benefits from (or caused) the event
    affectedTeamId: { type: mongoose.Schema.Types.ObjectId, ref: 'Team', default: null },

    // Extra/penalty runs awarded
    runs: { type: Number, default: 0 },

    // Human-readable description for the scorer
    description: { type: String, trim: true, maxlength: 500, default: null },

    // For score corrections: snapshot of before/after values
    correctionDetails: {
      fieldChanged: { type: String, default: null },
      oldValue    : { type: mongoose.Schema.Types.Mixed, default: null },
      newValue    : { type: mongoose.Schema.Types.Mixed, default: null },
    },
  },
  {
    timestamps: true,
  }
);

matchEventSchema.index({ matchId: 1, createdAt: 1 });
matchEventSchema.index({ inningsId: 1 });

module.exports = mongoose.model('MatchEvent', matchEventSchema);
// Export event types so other files can use them without magic strings
module.exports.EVENT_TYPES = EVENT_TYPES;
