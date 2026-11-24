/**
 * routes/deliveryRoutes.js
 */

'use strict';

const express = require('express');
const { body } = require('express-validator');
const ctrl = require('../controllers/deliveryController');

const router = express.Router({ mergeParams: true });

const deliveryValidation = [
  body('inningsId').isMongoId().withMessage('Invalid inningsId'),
  body('strikerId').isMongoId().withMessage('Invalid strikerId'),
  body('nonStrikerId').isMongoId().withMessage('Invalid nonStrikerId'),
  body('bowlerId').isMongoId().withMessage('Invalid bowlerId'),
  body('batterRuns').isInt({ min: 0 }).withMessage('batterRuns must be a non-negative integer'),
  body('extraRuns').optional().isInt({ min: 0 }).withMessage('extraRuns must be a non-negative integer'),
];

router.post('/:id/deliveries', deliveryValidation, ctrl.recordDelivery);
router.get ('/:id/deliveries',                     ctrl.getDeliveries);
router.post('/:id/undo',                           ctrl.undoDelivery);
router.put ('/:id/deliveries/:deliveryId',         ctrl.correctDelivery);

module.exports = router;
