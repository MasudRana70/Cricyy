/**
 * models/Player.js  –  Player Schema
 *
 * A Player is a persistent identity that survives across all teams and matches.
 * We NEVER delete a player who has match history – we soft-delete with isActive.
 */

'use strict';

const mongoose = require('mongoose');

const playerSchema = new mongoose.Schema(
  {
    name: {
      type    : String,
      required: [true, 'Player name is required'],
      trim    : true,
      minlength: [2, 'Name must be at least 2 characters'],
      maxlength: [80, 'Name must not exceed 80 characters'],
    },

    // Optional short display name / nickname
    shortName: {
      type   : String,
      trim   : true,
      maxlength: 20,
      default: null,
    },

    // Profile image – stored locally in /uploads, referenced by filename
    profileImage: {
      type   : String,
      default: null,
    },

    // Basic demographic info (all optional)
    dateOfBirth: { type: Date, default: null },
    contactInfo: { type: String, trim: true, default: null },
    notes      : { type: String, trim: true, maxlength: 500, default: null },

    // Soft-delete: set false instead of removing from DB
    isActive: { type: Boolean, default: true },
  },
  {
    timestamps: true, // adds createdAt + updatedAt automatically
    // toJSON / toObject virtuals are used to include virtual fields when serializing
    toJSON  : { virtuals: true },
    toObject: { virtuals: true },
  }
);

// ── Indexes ───────────────────────────────────────────────────────────────────
// Speeds up searching players by name
playerSchema.index({ name: 'text' });
playerSchema.index({ isActive: 1 });

// ── Virtual: display name ─────────────────────────────────────────────────────
// Returns shortName if set, otherwise the full name
playerSchema.virtual('displayName').get(function () {
  return this.shortName || this.name;
});

module.exports = mongoose.model('Player', playerSchema);
