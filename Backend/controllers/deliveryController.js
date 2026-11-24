/**
 * controllers/deliveryController.js
 *
 * Handles POST /api/matches/:id/deliveries   – record a delivery
 *         POST /api/matches/:id/undo         – undo last delivery
 *         GET  /api/matches/:id/deliveries   – list deliveries
 */

'use strict';

const { validationResult } = require('express-validator');
const Delivery       = require('../models/Delivery');
const Innings        = require('../models/Innings');
const Match          = require('../models/Match');
const inningsService = require('../services/inningsService');

// POST /api/matches/:id/deliveries
const recordDelivery = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) { res.status(400); throw new Error(errors.array().map(e => e.msg).join(', ')); }

    const match = await Match.findById(req.params.id);
    if (!match) { res.status(404); throw new Error('Match not found'); }

    const { inningsId } = req.body;
    if (!inningsId) { res.status(400); throw new Error('inningsId is required'); }

    const result = await inningsService.recordDelivery(inningsId, req.body, match.rules);

    res.status(201).json({
      success         : true,
      delivery        : result.delivery,
      innings         : result.innings,
      inningsComplete : result.inningsComplete,
      completionReason: result.completionReason,
    });
  } catch (err) { next(err); }
};

// GET /api/matches/:id/deliveries
const getDeliveries = async (req, res, next) => {
  try {
    const { inningsId, overNumber } = req.query;
    const filter = { matchId: req.params.id, isUndone: false };
    if (inningsId)  filter.inningsId  = inningsId;
    if (overNumber !== undefined) filter.overNumber = Number(overNumber);

    const deliveries = await Delivery.find(filter).sort({ deliverySequence: 1 });
    res.json({ success: true, deliveries });
  } catch (err) { next(err); }
};

// POST /api/matches/:id/undo
const undoDelivery = async (req, res, next) => {
  try {
    const { inningsId } = req.body;
    if (!inningsId) { res.status(400); throw new Error('inningsId is required'); }
    const result = await inningsService.undoLastDelivery(inningsId);
    res.json({ success: true, ...result });
  } catch (err) { next(err); }
};

// PUT /api/matches/:id/deliveries/:deliveryId
// Correct an already-recorded delivery (soft-delete old, insert new)
const correctDelivery = async (req, res, next) => {
  try {
    const delivery = await Delivery.findOne({
      _id    : req.params.deliveryId,
      matchId: req.params.id,
      isUndone: false,
    });
    if (!delivery) { res.status(404); throw new Error('Delivery not found'); }

    // Check it's the LAST delivery (only last can be corrected simply)
    const lastDelivery = await Delivery.findOne(
      { matchId: req.params.id, isUndone: false },
      null,
      { sort: { deliverySequence: -1 } }
    );
    if (!lastDelivery || lastDelivery._id.toString() !== delivery._id.toString()) {
      res.status(400);
      throw new Error('Only the most recent delivery can be corrected. Use undo first for earlier deliveries.');
    }

    // Undo the last delivery, then record the corrected one
    const match = await Match.findById(req.params.id);
    await inningsService.undoLastDelivery(delivery.inningsId.toString());
    const result = await inningsService.recordDelivery(delivery.inningsId.toString(), req.body, match.rules);

    res.json({ success: true, ...result });
  } catch (err) { next(err); }
};

module.exports = { recordDelivery, getDeliveries, undoDelivery, correctDelivery };
