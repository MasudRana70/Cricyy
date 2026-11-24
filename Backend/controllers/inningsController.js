/**
 * controllers/inningsController.js
 */

'use strict';

const Innings      = require('../models/Innings');
const matchService = require('../services/matchService');

// POST /api/matches/:id/innings
const startInnings = async (req, res, next) => {
  try {
    const { inningsNumber, openingBatters, openingBowler } = req.body;
    if (!inningsNumber || ![1, 2].includes(Number(inningsNumber))) {
      res.status(400); throw new Error('inningsNumber must be 1 or 2');
    }
    if (!openingBatters || openingBatters.length !== 2) {
      res.status(400); throw new Error('Exactly 2 opening batters are required');
    }
    if (!openingBowler) {
      res.status(400); throw new Error('openingBowler is required');
    }
    const innings = await matchService.startInnings(
      req.params.id,
      Number(inningsNumber),
      openingBatters,
      openingBowler
    );
    res.status(201).json({ success: true, innings });
  } catch (err) { next(err); }
};

// GET /api/matches/:id/innings
const getInnings = async (req, res, next) => {
  try {
    const innings = await Innings.find({ matchId: req.params.id }).sort({ inningsNumber: 1 });
    res.json({ success: true, innings });
  } catch (err) { next(err); }
};

// GET /api/matches/:id/innings/:inningsId
const getInningsById = async (req, res, next) => {
  try {
    const innings = await Innings.findOne({
      _id    : req.params.inningsId,
      matchId: req.params.id,
    });
    if (!innings) { res.status(404); throw new Error('Innings not found'); }
    res.json({ success: true, innings });
  } catch (err) { next(err); }
};

module.exports = { startInnings, getInnings, getInningsById };
