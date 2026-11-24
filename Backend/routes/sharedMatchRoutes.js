/**
 * routes/sharedMatchRoutes.js
 */

'use strict';

const express = require('express');
const ctrl = require('../controllers/sharedMatchController');

const router = express.Router();

router.get('/',     ctrl.getSharedMatches);
router.post('/',    ctrl.upsertSharedMatch);
router.get('/:id',  ctrl.getSharedMatchById);
router.put('/:id',  ctrl.upsertSharedMatch);
router.delete('/:id', ctrl.deleteSharedMatch);

module.exports = router;
