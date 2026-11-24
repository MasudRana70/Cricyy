/**
 * routes/inningsRoutes.js
 */

'use strict';

const express = require('express');
const ctrl = require('../controllers/inningsController');

const router = express.Router({ mergeParams: true });

router.post('/:id/innings',               ctrl.startInnings);
router.get ('/:id/innings',               ctrl.getInnings);
router.get ('/:id/innings/:inningsId',    ctrl.getInningsById);

module.exports = router;
