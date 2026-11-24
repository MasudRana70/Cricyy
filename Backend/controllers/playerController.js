/**
 * controllers/playerController.js
 *
 * Handles HTTP requests for /api/players.
 * Keeps HTTP logic (req/res) separate from business logic (playerService).
 */

'use strict';

const { validationResult } = require('express-validator');
const playerService     = require('../services/playerService');
const statisticsService = require('../services/statisticsService');

// GET /api/players
const getPlayers = async (req, res, next) => {
  try {
    const result = await playerService.getAllPlayers(req.query);
    res.json({ success: true, ...result });
  } catch (err) {
    next(err);
  }
};

// POST /api/players
const createPlayer = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400);
      throw new Error(errors.array().map(e => e.msg).join(', '));
    }
    const player = await playerService.createPlayer(req.body);
    res.status(201).json({ success: true, player });
  } catch (err) {
    next(err);
  }
};

// GET /api/players/:id
const getPlayerById = async (req, res, next) => {
  try {
    const player = await playerService.getPlayerById(req.params.id);
    res.json({ success: true, player });
  } catch (err) {
    next(err);
  }
};

// PUT /api/players/:id
const updatePlayer = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400);
      throw new Error(errors.array().map(e => e.msg).join(', '));
    }
    const player = await playerService.updatePlayer(req.params.id, req.body);
    res.json({ success: true, player });
  } catch (err) {
    next(err);
  }
};

// DELETE /api/players/:id
const deletePlayer = async (req, res, next) => {
  try {
    await playerService.deletePlayer(req.params.id);
    res.json({ success: true, message: 'Player deactivated' });
  } catch (err) {
    next(err);
  }
};

// GET /api/players/:id/statistics
const getPlayerStatistics = async (req, res, next) => {
  try {
    const stats = await statisticsService.getPlayerCareerStats(req.params.id, req.query);
    res.json({ success: true, ...stats });
  } catch (err) {
    next(err);
  }
};

// GET /api/players/:id/history
const getPlayerHistory = async (req, res, next) => {
  try {
    const history = await statisticsService.getPlayerMatchHistory(req.params.id, req.query);
    res.json({ success: true, ...history });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getPlayers,
  createPlayer,
  getPlayerById,
  updatePlayer,
  deletePlayer,
  getPlayerStatistics,
  getPlayerHistory,
};
