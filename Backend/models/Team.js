/**
 * models/Team.js  –  Team Schema
 *
 * A Team is a named group.  The 'members' array is the CURRENT squad.
 * Historical match rosters are stored in MatchPlayer, so changing the squad
 * never corrupts old scorecards.
 */

'use strict';

const mongoose = require('mongoose');

const teamSchema = new mongoose.Schema(
  {
    name: {
      type     : String,
      required : [true, 'Team name is required'],
      trim     : true,
      minlength: [2, 'Team name must be at least 2 characters'],
      maxlength: [80, 'Team name must not exceed 80 characters'],
    },

    shortName: {
      type   : String,
      trim   : true,
      maxlength: 10,
      default: null,
    },

    // Optional team logo file name
    logo: { type: String, default: null },

    // Current squad – array of Player references
    // This is the CURRENT roster only. Historical rosters live in MatchPlayer.
    members: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref : 'Player',
      },
    ],

    isActive: { type: Boolean, default: true },
  },
  {
    timestamps: true,
    toJSON    : { virtuals: true },
    toObject  : { virtuals: true },
  }
);

teamSchema.index({ name: 'text' });
teamSchema.index({ isActive: 1 });

module.exports = mongoose.model('Team', teamSchema);
