/**
 * controllers/matchController.js
 */

'use strict';

const { validationResult } = require('express-validator');
const Match       = require('../models/Match');
const MatchPlayer = require('../models/MatchPlayer');
const matchService= require('../services/matchService');
const { MATCH_STATUS } = require('../config/constants');

// GET /api/matches
const getMatches = async (req, res, next) => {
  try {
    const { status, team, player, fromDate, toDate, page = 1, limit = 20 } = req.query;
    const filter = {};

    if (status) filter.status = status;
    if (fromDate || toDate) {
      filter.matchDate = {};
      if (fromDate) filter.matchDate.$gte = new Date(fromDate);
      if (toDate)   filter.matchDate.$lte = new Date(toDate);
    }
    if (team) {
      // Search by team name snapshot
      filter.$or = [
        { team1Name: { $regex: team, $options: 'i' } },
        { team2Name: { $regex: team, $options: 'i' } },
      ];
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [matches, total] = await Promise.all([
      Match.find(filter).sort({ matchDate: -1 }).skip(skip).limit(parseInt(limit)),
      Match.countDocuments(filter),
    ]);

    res.json({
      success: true,
      matches,
      pagination: { page: parseInt(page), limit: parseInt(limit), total, totalPages: Math.ceil(total / parseInt(limit)) },
    });
  } catch (err) { next(err); }
};

// POST /api/matches
const createMatch = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) { res.status(400); throw new Error(errors.array().map(e => e.msg).join(', ')); }
    const match = await matchService.createMatch(req.body);
    res.status(201).json({ success: true, match });
  } catch (err) { next(err); }
};

// GET /api/matches/:id
const getMatchById = async (req, res, next) => {
  try {
    const match = await Match.findById(req.params.id);
    if (!match) { res.status(404); throw new Error('Match not found'); }

    // Also fetch the roster
    const players = await MatchPlayer.find({ matchId: req.params.id })
      .populate('playerId', 'name shortName profileImage');

    res.json({ success: true, match, players });
  } catch (err) { next(err); }
};

// PUT /api/matches/:id
const updateMatch = async (req, res, next) => {
  try {
    const match = await Match.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!match) { res.status(404); throw new Error('Match not found'); }
    res.json({ success: true, match });
  } catch (err) { next(err); }
};

// POST /api/matches/:id/complete
const completeMatch = async (req, res, next) => {
  try {
    const match = await matchService.completeMatch(req.params.id);
    res.json({ success: true, match });
  } catch (err) { next(err); }
};

module.exports = { getMatches, createMatch, getMatchById, updateMatch, completeMatch };
