/**
 * controllers/scorecardController.js
 *
 * GET /api/matches/:id/scorecard
 * Builds a complete, human-readable scorecard from stored data.
 */

'use strict';

const Match    = require('../models/Match');
const Innings  = require('../models/Innings');
const Delivery = require('../models/Delivery');

// GET /api/matches/:id/scorecard
const getScorecard = async (req, res, next) => {
  try {
    const match = await Match.findById(req.params.id);
    if (!match) { res.status(404); throw new Error('Match not found'); }

    const inningsArr = await Innings.find({ matchId: req.params.id }).sort({ inningsNumber: 1 });

    const inningsScorecards = await Promise.all(inningsArr.map(async (innings) => {
      // Build batting card from battersUsed
      const battingCard = innings.battersUsed.map(b => ({
        playerId    : b.playerId,
        playerName  : b.playerName,
        runs        : b.runs,
        balls       : b.balls,
        fours       : b.fours,
        sixes       : b.sixes,
        isOut       : b.isOut,
        strikeRate  : b.balls > 0 ? parseFloat(((b.runs / b.balls) * 100).toFixed(2)) : 0,
      }));

      // Build bowling card from bowlersUsed
      const bowlingCard = innings.bowlersUsed.map(b => {
        const completedOvers = b.overs;
        const balls = b.balls;
        const oversFormatted = parseFloat(`${completedOvers}.${balls}`);
        const economy = (completedOvers * 6 + balls) > 0
          ? parseFloat((b.runs / ((completedOvers * 6 + balls) / 6)).toFixed(2))
          : 0;
        return {
          playerId : b.playerId,
          bowlerName: b.playerName,
          overs    : oversFormatted,
          maidens  : b.maidens,
          runs     : b.runs,
          wickets  : b.wickets,
          economy,
          wides    : b.wides,
          noBalls  : b.noBalls,
        };
      });

      // Build over-by-over summary from deliveries
      const deliveries = await Delivery.find({ inningsId: innings._id, isUndone: false })
        .sort({ deliverySequence: 1 });

      const overMap = {};
      for (const d of deliveries) {
        const ov = d.overNumber;
        if (!overMap[ov]) overMap[ov] = { runs: 0, wickets: 0, balls: [] };
        overMap[ov].runs    += d.totalRuns;
        if (d.isWicket && d.wicket?.countsAsWicket !== false) overMap[ov].wickets += 1;
        // Ball notation
        let notation = '';
        if (d.extraType === 'wide')    notation = `wd${d.extraRuns > 1 ? '+' + d.batterRuns : ''}`;
        else if (d.extraType === 'no_ball') notation = `nb${d.batterRuns > 0 ? '+' + d.batterRuns : ''}`;
        else if (d.extraType === 'bye')     notation = `b${d.extraRuns}`;
        else if (d.extraType === 'leg_bye') notation = `lb${d.extraRuns}`;
        else if (d.isWicket)                notation = d.batterRuns > 0 ? `${d.batterRuns}W` : 'W';
        else                                notation = String(d.batterRuns || 0);
        overMap[ov].balls.push(notation);
      }

      const overSummary = Object.entries(overMap).map(([over, data]) => ({
        over   : Number(over) + 1, // display as 1-indexed
        runs   : data.runs,
        wickets: data.wickets,
        balls  : data.balls,
      }));

      return {
        inningsNumber  : innings.inningsNumber,
        battingTeamName: innings.battingTeamName,
        bowlingTeamName: innings.bowlingTeamName,
        total          : innings.totalRuns,
        wickets        : innings.totalWickets,
        overs          : `${innings.completedOvers}.${innings.currentBallInOver}`,
        extras         : innings.extras,
        target         : innings.target,
        status         : innings.status,
        battingCard,
        bowlingCard,
        fallOfWickets  : innings.fallOfWickets,
        overSummary,
      };
    }));

    res.json({
      success: true,
      scorecard: {
        matchId   : match._id,
        team1Name : match.team1Name,
        team2Name : match.team2Name,
        format    : match.format,
        totalOvers: match.totalOvers,
        matchDate : match.matchDate,
        venue     : match.venue,
        status    : match.status,
        result    : match.result,
        toss      : match.toss,
        innings   : inningsScorecards,
      },
    });
  } catch (err) { next(err); }
};

module.exports = { getScorecard };
