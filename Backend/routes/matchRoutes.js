/**
 * routes/matchRoutes.js
 */

'use strict';

const express = require('express');
const { body } = require('express-validator');
const ctrl = require('../controllers/matchController');
const { MATCH_FORMATS } = require('../config/constants');

const router = express.Router();

const matchValidation = [
  body('team1Id').isMongoId().withMessage('Invalid team1Id'),
  body('team2Id').isMongoId().withMessage('Invalid team2Id'),
  body('format').isIn(Object.values(MATCH_FORMATS)).withMessage('Invalid match format'),
];

router.get ('/',          ctrl.getMatches);
router.post('/', matchValidation, ctrl.createMatch);
router.get ('/:id',       ctrl.getMatchById);
router.put ('/:id',       ctrl.updateMatch);
router.post('/:id/complete', ctrl.completeMatch);

module.exports = router;
