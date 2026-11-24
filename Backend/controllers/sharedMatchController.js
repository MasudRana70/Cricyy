/**
 * controllers/sharedMatchController.js  –  Multi-User Match Sync Handlers
 *
 * Powers real-time-style polling & multi-user match sharing across devices via MongoDB Atlas.
 */

'use strict';

const SharedMatch = require('../models/SharedMatch');

// GET /api/shared-matches
const getSharedMatches = async (req, res, next) => {
  try {
    const { status, limit = 100 } = req.query;
    const filter = {};
    if (status) filter.status = status;

    const maxLimit = Math.min(Math.max(parseInt(limit, 10) || 100, 1), 200);
    const docs = await SharedMatch.find(filter)
      .sort({ matchDate: -1, updatedAt: -1 })
      .limit(maxLimit)
      .lean();

    const matches = docs.map((d) => SharedMatch.formatForClient(d));

    res.json({
      success: true,
      serverTime: new Date().toISOString(),
      count: matches.length,
      matches,
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/shared-matches/:id
const getSharedMatchById = async (req, res, next) => {
  try {
    const doc = await SharedMatch.findOne({ clientMatchId: req.params.id }).lean();
    if (!doc) {
      res.status(404);
      throw new Error('Shared match not found');
    }

    res.json({
      success: true,
      serverTime: new Date().toISOString(),
      match: SharedMatch.formatForClient(doc),
    });
  } catch (err) {
    next(err);
  }
};

// PUT /api/shared-matches/:id  (and POST /api/shared-matches)
const upsertSharedMatch = async (req, res, next) => {
  try {
    const body = req.body || {};
    const clientMatchId = (req.params.id || body._id || body.id || '').toString().trim();

    if (!clientMatchId) {
      res.status(400);
      throw new Error('Match id (_id) is required');
    }
    if (!body.team1Name || !body.team2Name) {
      res.status(400);
      throw new Error('team1Name and team2Name are required');
    }

    const incomingCreatorId = (
      req.headers['x-device-id'] ||
      body.creatorId ||
      ''
    ).toString().trim() || null;

    const updatePayload = {
      clientMatchId,
      team1Id:    body.team1Id ?? 'team_1',
      team2Id:    body.team2Id ?? 'team_2',
      team1Name:  body.team1Name,
      team2Name:  body.team2Name,
      format:     body.format ?? 'T20',
      totalOvers: Number(body.totalOvers) || 20,
      status:     body.status ?? 'in_progress',
      matchDate:  body.matchDate ? new Date(body.matchDate) : new Date(),
      venue:      body.venue ?? null,
      result:     body.result ?? null,
      toss:       body.toss ?? null,
      rules:      body.rules ?? {},
      innings1:   body.innings1 ?? null,
      innings2:   body.innings2 ?? null,
    };

    const doc = await SharedMatch.findOneAndUpdate(
      { clientMatchId },
      {
        $set: updatePayload,
        $setOnInsert: { creatorId: incomingCreatorId },
        $inc: { syncVersion: 1 },
      },
      {
        upsert: true,
        new: true,
        setDefaultsOnInsert: true,
        lean: true,
      }
    );

    const statusCode = req.method === 'POST' ? 201 : 200;
    res.status(statusCode).json({
      success: true,
      serverTime: new Date().toISOString(),
      match: SharedMatch.formatForClient(doc),
    });
  } catch (err) {
    next(err);
  }
};

// DELETE /api/shared-matches/:id
const deleteSharedMatch = async (req, res, next) => {
  try {
    const requesterId = (
      req.headers['x-device-id'] ||
      req.query.creatorId ||
      (req.body && req.body.creatorId) ||
      ''
    ).toString().trim();

    const doc = await SharedMatch.findOne({ clientMatchId: req.params.id }).lean();
    if (!doc) {
      res.status(404);
      throw new Error('Shared match not found');
    }

    if (!doc.creatorId || !requesterId || doc.creatorId !== requesterId) {
      res.status(403);
      throw new Error('Only the match creator can delete this match');
    }

    await SharedMatch.deleteOne({ clientMatchId: req.params.id });
    res.json({ success: true, message: 'Shared match deleted' });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getSharedMatches,
  getSharedMatchById,
  upsertSharedMatch,
  deleteSharedMatch,
};
