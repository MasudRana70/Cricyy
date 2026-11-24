/**
 * validators/deliveryValidator.js
 *
 * Additional semantic validation for a delivery that express-validator
 * alone cannot perform (e.g. checking that the striker belongs to the
 * batting team for this innings).
 */

'use strict';

const MatchPlayer = require('../models/MatchPlayer');
const Innings     = require('../models/Innings');
const { EXTRA_TYPES, DISMISSAL_TYPES } = require('../config/constants');

/**
 * validateDeliveryPlayers
 *
 * Checks that the striker, non-striker, and bowler are registered
 * for the correct teams in this match.
 *
 * @param {string} inningsId
 * @param {Object} delivery   – { strikerId, nonStrikerId, bowlerId }
 * @returns {string[]}        – error messages (empty = valid)
 */
async function validateDeliveryPlayers(inningsId, delivery) {
  const errors = [];

  const innings = await Innings.findById(inningsId);
  if (!innings) {
    return ['Innings not found'];
  }

  const { strikerId, nonStrikerId, bowlerId } = delivery;

  // Check striker is registered for the batting team
  const strikerRecord = await MatchPlayer.findOne({
    matchId : innings.matchId,
    teamId  : innings.battingTeamId,
    playerId: strikerId,
  });
  if (!strikerRecord) {
    errors.push(`Striker (${strikerId}) is not registered for the batting team in this match`);
  }

  // Check non-striker
  const nonStrikerRecord = await MatchPlayer.findOne({
    matchId : innings.matchId,
    teamId  : innings.battingTeamId,
    playerId: nonStrikerId,
  });
  if (!nonStrikerRecord) {
    errors.push(`Non-striker (${nonStrikerId}) is not registered for the batting team in this match`);
  }

  // Check bowler is registered for the bowling team
  const bowlerRecord = await MatchPlayer.findOne({
    matchId : innings.matchId,
    teamId  : innings.bowlingTeamId,
    playerId: bowlerId,
  });
  if (!bowlerRecord) {
    errors.push(`Bowler (${bowlerId}) is not registered for the bowling team in this match`);
  }

  return errors;
}

module.exports = { validateDeliveryPlayers };
