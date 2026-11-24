/**
 * controllers/teamController.js
 */

'use strict';

const { validationResult } = require('express-validator');
const Team   = require('../models/Team');
const Player = require('../models/Player');

// GET /api/teams
const getTeams = async (req, res, next) => {
  try {
    const { search, page = 1, limit = 20 } = req.query;
    const filter = { isActive: true };
    if (search) filter.$text = { $search: search };
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [teams, total] = await Promise.all([
      Team.find(filter).populate('members', 'name shortName profileImage').skip(skip).limit(parseInt(limit)).sort({ name: 1 }),
      Team.countDocuments(filter),
    ]);
    res.json({ success: true, teams, pagination: { page: parseInt(page), limit: parseInt(limit), total, totalPages: Math.ceil(total / parseInt(limit)) } });
  } catch (err) { next(err); }
};

// POST /api/teams
const createTeam = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) { res.status(400); throw new Error(errors.array().map(e => e.msg).join(', ')); }
    const team = await Team.create(req.body);
    res.status(201).json({ success: true, team });
  } catch (err) { next(err); }
};

// GET /api/teams/:id
const getTeamById = async (req, res, next) => {
  try {
    const team = await Team.findById(req.params.id).populate('members', 'name shortName profileImage');
    if (!team) { res.status(404); throw new Error('Team not found'); }
    res.json({ success: true, team });
  } catch (err) { next(err); }
};

// PUT /api/teams/:id
const updateTeam = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) { res.status(400); throw new Error(errors.array().map(e => e.msg).join(', ')); }
    const team = await Team.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!team) { res.status(404); throw new Error('Team not found'); }
    res.json({ success: true, team });
  } catch (err) { next(err); }
};

// POST /api/teams/:id/members – add player to team
const addMember = async (req, res, next) => {
  try {
    const { playerId } = req.body;
    if (!playerId) { res.status(400); throw new Error('playerId is required'); }
    const player = await Player.findById(playerId);
    if (!player) { res.status(404); throw new Error('Player not found'); }
    const team = await Team.findByIdAndUpdate(
      req.params.id,
      { $addToSet: { members: playerId } },
      { new: true }
    ).populate('members', 'name shortName');
    if (!team) { res.status(404); throw new Error('Team not found'); }
    res.json({ success: true, team });
  } catch (err) { next(err); }
};

// DELETE /api/teams/:id/members/:playerId – remove player from team
const removeMember = async (req, res, next) => {
  try {
    const team = await Team.findByIdAndUpdate(
      req.params.id,
      { $pull: { members: req.params.playerId } },
      { new: true }
    ).populate('members', 'name shortName');
    if (!team) { res.status(404); throw new Error('Team not found'); }
    res.json({ success: true, team });
  } catch (err) { next(err); }
};

module.exports = { getTeams, createTeam, getTeamById, updateTeam, addMember, removeMember };
