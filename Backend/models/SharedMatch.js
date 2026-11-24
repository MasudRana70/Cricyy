/**
 * models/SharedMatch.js  –  Synchronized Multi-User Match Document
 *
 * Stores complete match snapshots (match metadata, toss, rules, innings1, innings2, result)
 * keyed by `clientMatchId` so any user on any device can create, score, and watch matches live.
 */

'use strict';

const mongoose = require('mongoose');

const sharedMatchSchema = new mongoose.Schema(
  {
    clientMatchId: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      index: true,
    },
    team1Id:    { type: String, default: 'team_1' },
    team2Id:    { type: String, default: 'team_2' },
    team1Name:  { type: String, required: true, trim: true },
    team2Name:  { type: String, required: true, trim: true },
    format:     { type: String, default: 'T20' },
    totalOvers: { type: Number, required: true, min: 1 },
    status:     { type: String, default: 'in_progress', index: true },
    matchDate:  { type: Date, default: Date.now, index: true },
    venue:      { type: String, default: null },
    result:     { type: mongoose.Schema.Types.Mixed, default: null },
    toss:       { type: mongoose.Schema.Types.Mixed, default: null },
    rules:      { type: mongoose.Schema.Types.Mixed, default: () => ({}) },
    innings1:   { type: mongoose.Schema.Types.Mixed, default: null },
    innings2:   { type: mongoose.Schema.Types.Mixed, default: null },
    syncVersion:{ type: Number, default: 1 },
  },
  {
    timestamps: true,
    minimize: false,
  }
);

sharedMatchSchema.index({ matchDate: -1, updatedAt: -1 });

/**
 * Formats a plain/lean SharedMatch document for the Flutter MatchModel.fromJson().
 */
sharedMatchSchema.statics.formatForClient = function (doc) {
  if (!doc) return null;
  const obj = typeof doc.toObject === 'function' ? doc.toObject() : doc;
  return {
    _id:         obj.clientMatchId,
    team1Id:     obj.team1Id ?? 'team_1',
    team2Id:     obj.team2Id ?? 'team_2',
    team1Name:   obj.team1Name ?? '',
    team2Name:   obj.team2Name ?? '',
    format:      obj.format ?? 'T20',
    totalOvers:  obj.totalOvers ?? 20,
    status:      obj.status ?? 'in_progress',
    matchDate:   obj.matchDate ? new Date(obj.matchDate).toISOString() : new Date().toISOString(),
    venue:       obj.venue ?? null,
    result:      obj.result ?? null,
    toss:        obj.toss ?? null,
    rules:       obj.rules ?? {},
    innings1:    obj.innings1 ?? null,
    innings2:    obj.innings2 ?? null,
    syncVersion: obj.syncVersion ?? 1,
    updatedAt:   obj.updatedAt ? new Date(obj.updatedAt).toISOString() : null,
  };
};

module.exports = mongoose.model('SharedMatch', sharedMatchSchema);
