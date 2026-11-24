/**
 * services/playerService.js  –  Player CRUD helpers
 */

'use strict';

const Player = require('../models/Player');

async function getAllPlayers(query = {}) {
  const { search, page = 1, limit = 20 } = query;
  const filter = { isActive: true };

  if (search) {
    filter.$text = { $search: search };
  }

  const skip = (parseInt(page) - 1) * parseInt(limit);

  const [players, total] = await Promise.all([
    Player.find(filter).skip(skip).limit(parseInt(limit)).sort({ name: 1 }),
    Player.countDocuments(filter),
  ]);

  return {
    players,
    pagination: {
      page  : parseInt(page),
      limit : parseInt(limit),
      total,
      totalPages: Math.ceil(total / parseInt(limit)),
    },
  };
}

async function getPlayerById(id) {
  const player = await Player.findById(id);
  if (!player || !player.isActive) throw new Error('Player not found');
  return player;
}

async function createPlayer(data) {
  const player = await Player.create(data);
  return player;
}

async function updatePlayer(id, data) {
  const player = await Player.findByIdAndUpdate(id, data, { new: true, runValidators: true });
  if (!player) throw new Error('Player not found');
  return player;
}

async function deletePlayer(id) {
  // Soft-delete
  const player = await Player.findByIdAndUpdate(id, { isActive: false }, { new: true });
  if (!player) throw new Error('Player not found');
  return player;
}

module.exports = { getAllPlayers, getPlayerById, createPlayer, updatePlayer, deletePlayer };
