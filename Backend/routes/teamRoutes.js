/**
 * routes/teamRoutes.js
 */

'use strict';

const express = require('express');
const { body } = require('express-validator');
const ctrl = require('../controllers/teamController');

const router = express.Router();

const teamValidation = [
  body('name').trim().isLength({ min: 2, max: 80 }).withMessage('Team name must be 2–80 characters'),
];

router.get ('/',                   ctrl.getTeams);
router.post('/', teamValidation,   ctrl.createTeam);
router.get ('/:id',                ctrl.getTeamById);
router.put ('/:id', teamValidation, ctrl.updateTeam);
router.post('/:id/members',        ctrl.addMember);
router.delete('/:id/members/:playerId', ctrl.removeMember);

module.exports = router;
