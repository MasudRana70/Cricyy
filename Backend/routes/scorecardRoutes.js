/**
 * routes/scorecardRoutes.js
 */

'use strict';

const express = require('express');
const ctrl = require('../controllers/scorecardController');

const router = express.Router({ mergeParams: true });

router.get('/:id/scorecard', ctrl.getScorecard);

module.exports = router;
