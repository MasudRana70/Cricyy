/**
 * routes/playerRoutes.js
 */

'use strict';

const express = require('express');
const { body, param } = require('express-validator');
const ctrl    = require('../controllers/playerController');
const upload  = require('../middleware/uploadMiddleware');

const router = express.Router();

// Validation rules
const playerValidation = [
  body('name').trim().isLength({ min: 2, max: 80 }).withMessage('Name must be 2–80 characters'),
];

router.get ('/',                    ctrl.getPlayers);
router.post('/', playerValidation,  ctrl.createPlayer);
router.get ('/:id',                 ctrl.getPlayerById);
router.put ('/:id', playerValidation, ctrl.updatePlayer);
router.delete('/:id',               ctrl.deletePlayer);
router.get ('/:id/statistics',      ctrl.getPlayerStatistics);
router.get ('/:id/history',         ctrl.getPlayerHistory);

module.exports = router;
