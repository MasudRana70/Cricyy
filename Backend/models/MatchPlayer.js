/**
 * models/MatchPlayer.js  –  Match Roster Snapshot
 *
 * Records WHICH players participated in a specific match for a specific team.
 * This is a snapshot – it is not affected by later changes to the Team.members array.
 *
 * Also stores the batting order and playing role.
 */

'use strict';

const mongoose = require('mongoose');

const matchPlayerSchema = new mongoose.Schema(
  {
    matchId : { type: mongoose.Schema.Types.ObjectId, ref: 'Match',  required: true },
    teamId  : { type: mongoose.Schema.Types.ObjectId, ref: 'Team',   required: true },
    playerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Player', required: true },

    // Player name snapshot – so the scorecard is correct even if the player
    // changes their name later
    playerName: { type: String, required: true },

    // Order in which this player can bat (1 = opener, 11 = last)
    battingOrder: { type: Number, default: null },

    // General role for display (not used for rule enforcement in v1)
    role: {
      type   : String,
      enum   : ['batsman', 'bowler', 'allrounder', 'wicketkeeper', 'unknown'],
      default: 'unknown',
    },

    // Set true if this player is the designated wicket-keeper for this match
    isWicketKeeper: { type: Boolean, default: false },

    // Set true if this player is the designated captain for this match
    isCaptain: { type: Boolean, default: false },
  },
  {
    timestamps: true,
  }
);

// A player can appear only once per team per match
matchPlayerSchema.index({ matchId: 1, teamId: 1, playerId: 1 }, { unique: true });
matchPlayerSchema.index({ matchId: 1, teamId: 1 });
matchPlayerSchema.index({ matchId: 1, playerId: 1 });
matchPlayerSchema.index({ playerId: 1 }); // for career statistics lookups

module.exports = mongoose.model('MatchPlayer', matchPlayerSchema);
