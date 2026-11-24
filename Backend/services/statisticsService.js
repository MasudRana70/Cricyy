/**
 * services/statisticsService.js  –  Player Career Statistics Calculator
 *
 * Calculates career and format-filtered stats by AGGREGATING from
 * PlayerMatchStats documents.  Stats are NEVER read from a manually editable field.
 *
 * All stat definitions follow standard cricket scorekeeping conventions.
 */

'use strict';

const PlayerMatchStats = require('../models/PlayerMatchStats');

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 1 – BATTING STATISTICS
// ─────────────────────────────────────────────────────────────────────────────

/**
 * aggregateBattingStats
 *
 * @param {Object[]} records – Array of PlayerMatchStats documents
 * @returns {Object} batting career stats
 */
function aggregateBattingStats(records) {
  const batRecords = records.filter(r => r.batting && r.batting.didBat);

  const totalMatches   = records.length;
  const innings        = batRecords.length;
  const totalRuns      = batRecords.reduce((s, r) => s + r.batting.runs,  0);
  const totalBalls     = batRecords.reduce((s, r) => s + r.batting.balls, 0);
  const totalFours     = batRecords.reduce((s, r) => s + r.batting.fours, 0);
  const totalSixes     = batRecords.reduce((s, r) => s + r.batting.sixes, 0);
  const notOuts        = batRecords.filter(r => r.batting.isNotOut).length;
  const dismissals     = innings - notOuts;
  const highestScore   = batRecords.length
    ? Math.max(...batRecords.map(r => r.batting.runs))
    : 0;

  // Batting Average = Runs / Dismissals (undefined if no dismissals)
  const battingAverage = dismissals > 0
    ? parseFloat((totalRuns / dismissals).toFixed(2))
    : (innings > 0 ? null : 0); // null means "not out every time"

  // Strike Rate = (Runs / Balls) * 100
  const strikeRate = totalBalls > 0
    ? parseFloat(((totalRuns / totalBalls) * 100).toFixed(2))
    : 0;

  const halfCenturies = batRecords.filter(r => r.batting.runs >= 50 && r.batting.runs < 100).length;
  const centuries     = batRecords.filter(r => r.batting.runs >= 100).length;

  return {
    totalMatches,
    battingInnings : innings,
    totalRuns,
    highestScore,
    notOuts,
    battingAverage,
    strikeRate,
    totalBalls,
    totalFours,
    totalSixes,
    halfCenturies,
    centuries,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 2 – BOWLING STATISTICS
// ─────────────────────────────────────────────────────────────────────────────

/**
 * aggregateBowlingStats
 *
 * @param {Object[]} records – Array of PlayerMatchStats documents
 * @returns {Object} bowling career stats
 */
function aggregateBowlingStats(records) {
  const bowlRecords = records.filter(r => r.bowling && r.bowling.didBowl);

  const bowlingMatches  = records.length;
  const bowlingInnings  = bowlRecords.length;
  const totalLegalBalls = bowlRecords.reduce((s, r) => s + r.bowling.legalBalls, 0);
  const totalMaidens    = bowlRecords.reduce((s, r) => s + r.bowling.maidens,    0);
  const totalRuns       = bowlRecords.reduce((s, r) => s + r.bowling.runs,       0);
  const totalWickets    = bowlRecords.reduce((s, r) => s + r.bowling.wickets,    0);
  const totalWides      = bowlRecords.reduce((s, r) => s + r.bowling.wides,      0);
  const totalNoBalls    = bowlRecords.reduce((s, r) => s + r.bowling.noBalls,    0);

  // Overs = legal balls / 6 (expressed as decimal e.g. 10.4 = 10 overs 4 balls)
  const completedOvers  = Math.floor(totalLegalBalls / 6);
  const remainingBalls  = totalLegalBalls % 6;
  const oversFormatted  = parseFloat(`${completedOvers}.${remainingBalls}`);

  // Bowling Average = Runs conceded / Wickets taken
  const bowlingAverage  = totalWickets > 0
    ? parseFloat((totalRuns / totalWickets).toFixed(2))
    : null; // no wickets = average undefined

  // Economy Rate = Runs per over bowled
  const economyRate = totalLegalBalls > 0
    ? parseFloat((totalRuns / (totalLegalBalls / 6)).toFixed(2))
    : 0;

  // Bowling Strike Rate = Balls per wicket
  const bowlingStrikeRate = totalWickets > 0
    ? parseFloat((totalLegalBalls / totalWickets).toFixed(2))
    : null;

  // Best Bowling Figures = best wickets/runs in a single innings
  let bestBowling = null;
  if (bowlRecords.length > 0) {
    const sorted = [...bowlRecords].sort((a, b) => {
      // Sort by wickets desc, then runs asc
      if (b.bowling.wickets !== a.bowling.wickets) return b.bowling.wickets - a.bowling.wickets;
      return a.bowling.runs - b.bowling.runs;
    });
    const best = sorted[0].bowling;
    bestBowling = `${best.wickets}/${best.runs}`;
  }

  const threeWicketHauls = bowlRecords.filter(r => r.bowling.wickets >= 3 && r.bowling.wickets < 4).length;
  const fourWicketHauls  = bowlRecords.filter(r => r.bowling.wickets >= 4 && r.bowling.wickets < 5).length;
  const fiveWicketHauls  = bowlRecords.filter(r => r.bowling.wickets >= 5).length;

  return {
    bowlingMatches,
    bowlingInnings,
    totalLegalBalls,
    overs          : oversFormatted,
    maidens        : totalMaidens,
    totalRunsConceded: totalRuns,
    totalWickets,
    bowlingAverage,
    economyRate,
    bowlingStrikeRate,
    bestBowling,
    threeWicketHauls,
    fourWicketHauls,
    fiveWicketHauls,
    wides          : totalWides,
    noBalls        : totalNoBalls,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 3 – CAREER STATISTICS (PUBLIC API)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * getPlayerCareerStats
 *
 * Returns complete career statistics for a player.
 * Optionally filter by format and/or date range.
 *
 * @param {string} playerId
 * @param {Object} filters  – { format, fromDate, toDate }
 * @returns {Object}
 */
async function getPlayerCareerStats(playerId, filters = {}) {
  const query = { playerId };

  if (filters.format) {
    query.matchFormat = filters.format;
  }
  if (filters.fromDate || filters.toDate) {
    query.matchDate = {};
    if (filters.fromDate) query.matchDate.$gte = new Date(filters.fromDate);
    if (filters.toDate)   query.matchDate.$lte = new Date(filters.toDate);
  }

  const records = await PlayerMatchStats.find(query).lean();

  return {
    batting : aggregateBattingStats(records),
    bowling : aggregateBowlingStats(records),
    filters,
  };
}

/**
 * getPlayerMatchHistory
 *
 * Returns match-by-match performance for a player.
 *
 * @param {string} playerId
 * @param {Object} filters – { format, fromDate, toDate, page, limit }
 * @returns {Object[]}
 */
async function getPlayerMatchHistory(playerId, filters = {}) {
  const query = { playerId };
  if (filters.format)   query.matchFormat = filters.format;
  if (filters.fromDate || filters.toDate) {
    query.matchDate = {};
    if (filters.fromDate) query.matchDate.$gte = new Date(filters.fromDate);
    if (filters.toDate)   query.matchDate.$lte = new Date(filters.toDate);
  }

  const page  = parseInt(filters.page  || 1,  10);
  const limit = parseInt(filters.limit || 20, 10);
  const skip  = (page - 1) * limit;

  const [records, total] = await Promise.all([
    PlayerMatchStats.find(query)
      .sort({ matchDate: -1 })
      .skip(skip)
      .limit(limit)
      .populate('matchId', 'team1Name team2Name matchDate format')
      .lean(),
    PlayerMatchStats.countDocuments(query),
  ]);

  return {
    records,
    pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
  };
}

/**
 * updatePlayerMatchStats
 *
 * Called after every delivery to keep the PlayerMatchStats cache current.
 * Uses upsert so the first call creates the record.
 *
 * @param {Object} params
 * @returns {Promise<void>}
 */
async function updatePlayerMatchStats(params) {
  const {
    playerId, matchId, inningsId, teamId, teamName,
    opponentTeamId, opponentTeamName, matchDate, matchFormat,
    batting, bowling,
  } = params;

  await PlayerMatchStats.findOneAndUpdate(
    { playerId, matchId },
    {
      $set: {
        inningsId, teamId, teamName,
        opponentTeamId, opponentTeamName,
        matchDate, matchFormat,
        batting, bowling,
      },
    },
    { upsert: true, new: true }
  );
}

module.exports = {
  getPlayerCareerStats,
  getPlayerMatchHistory,
  updatePlayerMatchStats,
  aggregateBattingStats,
  aggregateBowlingStats,
};
