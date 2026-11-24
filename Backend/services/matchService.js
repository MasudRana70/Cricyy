/**
 * services/matchService.js  –  Match Lifecycle Management
 *
 * Handles creating matches, setting up innings, and completing matches.
 */

'use strict';

const mongoose   = require('mongoose');
const Match      = require('../models/Match');
const Team       = require('../models/Team');
const Innings    = require('../models/Innings');
const MatchPlayer= require('../models/MatchPlayer');
const {
  MATCH_STATUS,
  INNINGS_STATUS,
  FORMAT_OVERS,
  DEFAULT_MAX_BOWLER_OVERS_FRACTION,
  DEFAULT_RULESET,
} = require('../config/constants');
const scoring = require('./scoringService');

/**
 * createMatch
 * Sets up a new match document and the MatchPlayer roster snapshot.
 */
async function createMatch(data) {
  const {
    team1Id, team2Id,
    format, totalOvers,
    playersPerSide = 11,
    maxOversPerBowler,
    toss,
    battingFirstTeamId,
    matchDate,
    venue,
    ruleset,
    team1Players, // [{ playerId, playerName, battingOrder, role, isWicketKeeper, isCaptain }]
    team2Players,
  } = data;

  // ── Validate teams exist ──────────────────────────────────────────────────
  const [team1, team2] = await Promise.all([
    Team.findById(team1Id),
    Team.findById(team2Id),
  ]);
  if (!team1) throw new Error('Team 1 not found');
  if (!team2) throw new Error('Team 2 not found');
  if (team1Id.toString() === team2Id.toString()) throw new Error('A team cannot play against itself');

  // ── Determine overs ───────────────────────────────────────────────────────
  const overs = totalOvers || FORMAT_OVERS[format];
  if (!overs) throw new Error('totalOvers is required for CUSTOM format');

  // ── Determine bowler over limit ───────────────────────────────────────────
  const bowlerLimit = maxOversPerBowler !== undefined
    ? maxOversPerBowler
    : Math.ceil(overs * DEFAULT_MAX_BOWLER_OVERS_FRACTION);

  // ── Validate batting-first team ───────────────────────────────────────────
  if (
    battingFirstTeamId &&
    battingFirstTeamId.toString() !== team1Id.toString() &&
    battingFirstTeamId.toString() !== team2Id.toString()
  ) {
    throw new Error('battingFirstTeamId must be one of the two teams');
  }

  // ── Create Match document ─────────────────────────────────────────────────
  const session = await mongoose.startSession();
  let match;
  try {
    await session.withTransaction(async () => {
      match = await Match.create([{
        team1Id,
        team2Id,
        team1Name: team1.name,
        team2Name: team2.name,
        format,
        totalOvers: overs,
        toss: toss || null,
        battingFirstTeamId: battingFirstTeamId || null,
        rules: {
          ruleset          : ruleset || DEFAULT_RULESET,
          maxOversPerBowler: bowlerLimit,
          playersPerSide,
          overLength       : 6,
        },
        status   : MATCH_STATUS.SETUP,
        matchDate: matchDate || new Date(),
        venue    : venue || null,
      }], { session });
      match = match[0];

      // ── Save roster snapshots ──────────────────────────────────────────────
      const allPlayers = [
        ...(team1Players || []).map(p => ({ ...p, teamId: team1Id })),
        ...(team2Players || []).map(p => ({ ...p, teamId: team2Id })),
      ].map(p => ({
        matchId       : match._id,
        teamId        : p.teamId,
        playerId      : p.playerId,
        playerName    : p.playerName,
        battingOrder  : p.battingOrder || null,
        role          : p.role || 'unknown',
        isWicketKeeper: p.isWicketKeeper || false,
        isCaptain     : p.isCaptain || false,
      }));

      if (allPlayers.length > 0) {
        await MatchPlayer.insertMany(allPlayers, { session });
      }
    });
  } finally {
    await session.endSession();
  }

  return match;
}

/**
 * startInnings
 * Creates an Innings document and sets its initial batters + current bowler.
 */
async function startInnings(matchId, inningsNumber, openingBatters, openingBowler) {
  const match = await Match.findById(matchId);
  if (!match) throw new Error('Match not found');

  if (!match.battingFirstTeamId) {
    throw new Error('battingFirstTeamId is not set on the match');
  }

  // Determine which team bats in this innings
  const battingTeamId = inningsNumber === 1
    ? match.battingFirstTeamId
    : (match.battingFirstTeamId.toString() === match.team1Id.toString()
        ? match.team2Id : match.team1Id);

  const bowlingTeamId = battingTeamId.toString() === match.team1Id.toString()
    ? match.team2Id : match.team1Id;

  const battingTeamName = battingTeamId.toString() === match.team1Id.toString()
    ? match.team1Name : match.team2Name;
  const bowlingTeamName = battingTeamId.toString() === match.team1Id.toString()
    ? match.team2Name : match.team1Name;

  // Build initial current batters (striker + non-striker)
  if (!openingBatters || openingBatters.length !== 2) {
    throw new Error('Exactly 2 opening batters are required to start an innings');
  }
  if (!openingBowler) {
    throw new Error('An opening bowler is required to start an innings');
  }

  const currentBatters = [
    {
      playerId  : openingBatters[0].playerId,
      playerName: openingBatters[0].playerName,
      runs      : 0, balls: 0, fours: 0, sixes: 0,
      isOut     : false, isStriker: true,
    },
    {
      playerId  : openingBatters[1].playerId,
      playerName: openingBatters[1].playerName,
      runs      : 0, balls: 0, fours: 0, sixes: 0,
      isOut     : false, isStriker: false,
    },
  ];

  // Target for 2nd innings
  let target = null;
  if (inningsNumber === 2) {
    const firstInnings = await Innings.findOne({ matchId, inningsNumber: 1 });
    if (firstInnings) {
      target = firstInnings.totalRuns + 1; // must BEAT the first innings total
    }
  }

  const innings = await Innings.create({
    matchId,
    inningsNumber,
    battingTeamId,
    battingTeamName,
    bowlingTeamId,
    bowlingTeamName,
    target,
    status        : INNINGS_STATUS.IN_PROGRESS,
    currentBatters,
    battersUsed   : [...currentBatters],
    bowlersUsed   : [{
      playerId  : openingBowler.playerId,
      playerName: openingBowler.playerName,
      isCurrent : true,
    }],
  });

  // Update match status
  await Match.findByIdAndUpdate(matchId, { status: MATCH_STATUS.IN_PROGRESS });

  return innings;
}

/**
 * completeMatch
 * Sets the match status to COMPLETED and saves the result.
 */
async function completeMatch(matchId) {
  const [match, innings1, innings2] = await Promise.all([
    Match.findById(matchId),
    Innings.findOne({ matchId, inningsNumber: 1 }),
    Innings.findOne({ matchId, inningsNumber: 2 }),
  ]);

  if (!match)   throw new Error('Match not found');
  if (!innings2) throw new Error('Second innings has not started yet');

  const result = scoring.calculateMatchResult(innings1, innings2, match);

  match.status = MATCH_STATUS.COMPLETED;
  match.result = result;
  await match.save();

  return match;
}

module.exports = { createMatch, startInnings, completeMatch };
