/**
 * services/scoringService.js  –  Cricket Scoring Engine
 *
 * ════════════════════════════════════════════════════════════════════════
 *  THE SINGLE SOURCE OF AUTHORITY FOR ALL SCORING CALCULATIONS
 * ════════════════════════════════════════════════════════════════════════
 *
 * This module is intentionally kept PURE – it does NOT import Mongoose models
 * or talk to the database directly.  It receives plain JavaScript objects,
 * validates them against cricket rules, and returns a plain result object.
 *
 * The calling service (inningsService.js) is responsible for saving the result.
 *
 * Rules reference:
 *   MCC Laws of Cricket – effective 1 October 2026
 *   https://www.lords.org/mcc/the-laws-of-cricket/
 *
 * Key laws implemented:
 *   Law 18  – Scoring runs
 *   Law 20  – Lost ball
 *   Law 21  – No ball
 *   Law 22  – Wide ball
 *   Law 23  – Bye and Leg bye
 *   Law 24  – Penalty runs
 *   Law 25  – Unused (placeholder)
 *   Law 26  – Batter's innings
 *   Law 29  – Batters out of their ground
 *   Law 32–41 – Dismissals
 *   Law 42  – Player conduct (penalty runs)
 */

'use strict';

const {
  EXTRA_TYPES,
  DISMISSAL_TYPES,
  BOWLER_CREDITED_DISMISSALS,
  ILLEGAL_ON_NO_BALL,
  LEGAL_ON_WIDE,
} = require('../config/constants');

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 1 – DELIVERY VALIDATION
// ─────────────────────────────────────────────────────────────────────────────

/**
 * validateDelivery
 *
 * Checks that the submitted delivery object is internally consistent
 * according to cricket rules BEFORE any database writes happen.
 *
 * @param {Object} delivery   – Raw delivery input from the API
 * @param {Object} matchRules – Rules config from the Match document
 * @returns {string[]}        – Array of error messages (empty = valid)
 */
function validateDelivery(delivery, matchRules) {
  const errors = [];
  const { extraType, batterRuns, extraRuns, isWicket, wicket } = delivery;

  // ── Basic required fields ──────────────────────────────────────────────────
  if (typeof batterRuns !== 'number' || batterRuns < 0) {
    errors.push('batterRuns must be a non-negative number');
  }
  if (typeof extraRuns !== 'number' || extraRuns < 0) {
    errors.push('extraRuns must be a non-negative number');
  }

  // ── Wide rules (MCC Law 22) ───────────────────────────────────────────────
  if (extraType === EXTRA_TYPES.WIDE) {
    if (batterRuns > 0) {
      errors.push('A batter cannot score bat runs off a wide (Law 22)');
    }
    // Extra runs off a wide include the wide penalty (1) + any overthrows
    if (extraRuns < 1) {
      errors.push('A wide must carry at least 1 extra run (the wide penalty)');
    }
    // Wicket off a wide: only run-out, stumped, obstructing, timed out, retired
    if (isWicket && wicket) {
      if (!LEGAL_ON_WIDE.has(wicket.dismissalType)) {
        errors.push(
          `Dismissal type "${wicket.dismissalType}" is not possible off a wide ball (Law 22.1)`
        );
      }
    }
  }

  // ── No Ball rules (MCC Law 21) ────────────────────────────────────────────
  if (extraType === EXTRA_TYPES.NO_BALL) {
    // A no ball carries a 1-run penalty as an extra (can be more with overthrows)
    if (extraRuns < 1) {
      errors.push('A no ball must carry at least 1 extra run (the no-ball penalty)');
    }
    // Some dismissals are illegal off a no ball
    if (isWicket && wicket) {
      if (ILLEGAL_ON_NO_BALL.has(wicket.dismissalType)) {
        errors.push(
          `Dismissal type "${wicket.dismissalType}" is not possible off a no ball (Law 21.11)`
        );
      }
    }
  }

  // ── Bye / Leg Bye (MCC Law 23) ────────────────────────────────────────────
  if (extraType === EXTRA_TYPES.BYE || extraType === EXTRA_TYPES.LEG_BYE) {
    if (batterRuns > 0) {
      errors.push(`Batter cannot score bat runs on a ${extraType} (Law 23)`);
    }
    if (extraRuns < 1) {
      errors.push(`A ${extraType} must carry at least 1 extra run`);
    }
  }

  // ── Wicket validation ─────────────────────────────────────────────────────
  if (isWicket) {
    if (!wicket) {
      errors.push('isWicket is true but no wicket details were provided');
    } else {
      if (!wicket.dismissalType) {
        errors.push('wicket.dismissalType is required');
      }
      if (!wicket.dismissedPlayerId) {
        errors.push('wicket.dismissedPlayerId is required');
      }
      // Caught requires a fielder
      if (wicket.dismissalType === DISMISSAL_TYPES.CAUGHT && !wicket.fielderPlayerId) {
        errors.push('A caught dismissal requires a fielder (wicket.fielderPlayerId)');
      }
      // Stumped requires a fielder (wicket-keeper)
      if (wicket.dismissalType === DISMISSAL_TYPES.STUMPED && !wicket.fielderPlayerId) {
        errors.push('A stumped dismissal requires a wicket-keeper (wicket.fielderPlayerId)');
      }
      // Retired Hurt is NOT a wicket in the bowling sense
      if (wicket.dismissalType === DISMISSAL_TYPES.RETIRED_HURT) {
        // This is handled separately but allowed through here for record-keeping
      }
    }
  }

  return errors;
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 2 – LEGAL DELIVERY CHECK
// ─────────────────────────────────────────────────────────────────────────────

/**
 * isLegalDelivery
 * Returns true if this delivery counts as a legal ball (advances the over).
 * Wides and No Balls are ILLEGAL deliveries.
 *
 * @param {string} extraType
 * @returns {boolean}
 */
function isLegalDelivery(extraType) {
  return extraType !== EXTRA_TYPES.WIDE && extraType !== EXTRA_TYPES.NO_BALL;
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 3 – RUN CALCULATION
// ─────────────────────────────────────────────────────────────────────────────

/**
 * calculateTotalRuns
 *
 * Returns how many runs to ADD TO THE TEAM SCORE for this delivery.
 *
 * Key rules:
 *   - Byes and Leg Byes go to Extras (not to the batter's tally), but
 *     they DO add to the team total.
 *   - Wide penalty goes to extras and the team total.
 *   - No Ball penalty goes to extras and the team total.
 *   - Bat runs off a no ball go to the BATTER'S tally AND the team total.
 *
 * @param {Object} delivery
 * @returns {number}
 */
function calculateTotalRuns(delivery) {
  const { batterRuns = 0, extraRuns = 0 } = delivery;
  return batterRuns + extraRuns;
}

/**
 * calculateBowlerRuns
 *
 * How many runs the BOWLER concedes on this delivery.
 *
 * Rules (MCC Law 24 / scoring conventions):
 *   - Byes and Leg Byes do NOT count against the bowler.
 *   - Wides, No Balls, bat runs, and overthrows DO count against the bowler.
 *
 * @param {Object} delivery
 * @returns {number}
 */
function calculateBowlerRuns(delivery) {
  const { batterRuns = 0, extraRuns = 0, extraType } = delivery;

  if (extraType === EXTRA_TYPES.BYE || extraType === EXTRA_TYPES.LEG_BYE) {
    // Byes/leg-byes: charged to extras, NOT the bowler
    return 0;
  }

  // Everything else (bat runs + wide penalty + no-ball penalty + overthrows)
  // is charged to the bowler
  return batterRuns + extraRuns;
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 4 – STRIKE ROTATION
// ─────────────────────────────────────────────────────────────────────────────

/**
 * shouldRotateStrike
 *
 * Returns true if the striker and non-striker should swap ends DURING the over
 * (i.e., as a result of runs scored on this delivery – not the end-of-over swap).
 *
 * Rules:
 *   - Odd number of COMPLETED runs = strike changes
 *   - Even number = no change
 *   - For run-outs, runsCompleted (before the dismissal) determines the swap
 *
 * @param {Object} delivery
 * @returns {boolean}
 */
function shouldRotateStrike(delivery) {
  const { batterRuns = 0, extraType, extraRuns = 0, isWicket, wicket } = delivery;

  // ── Run Out: use runs completed BEFORE the wicket ─────────────────────────
  if (isWicket && wicket && wicket.dismissalType === DISMISSAL_TYPES.RUN_OUT) {
    const runsCompleted = wicket.runsCompleted || 0;
    return runsCompleted % 2 !== 0;
  }

  // ── Byes / Leg Byes: runs scored count for strike rotation ────────────────
  if (extraType === EXTRA_TYPES.BYE || extraType === EXTRA_TYPES.LEG_BYE) {
    return extraRuns % 2 !== 0;
  }

  // ── Wide: extra runs count for strike rotation ────────────────────────────
  // (the batter doesn't face the ball but can run)
  if (extraType === EXTRA_TYPES.WIDE) {
    // Wide extras (minus the 1-run penalty) are run by the batters
    // The penalty always goes to the bowling side, not the batting end
    // Runs CROSSED = extraRuns - 1 (the extra 1 is the penalty, not a run)
    const runsCrossed = extraRuns - 1;
    return runsCrossed % 2 !== 0;
  }

  // ── Normal delivery / No Ball ─────────────────────────────────────────────
  return batterRuns % 2 !== 0;
}

/**
 * shouldSwapAtEndOfOver
 *
 * At the end of a completed over the non-striker becomes the striker.
 * This is the ALWAYS-swap rule (MCC Law 18.11).
 * Returns true unconditionally – the caller decides whether the over just ended.
 *
 * @returns {boolean}
 */
function shouldSwapAtEndOfOver() {
  return true;
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 5 – WICKET PROCESSING
// ─────────────────────────────────────────────────────────────────────────────

/**
 * processWicket
 *
 * Given a wicket object, determines:
 *   1. Whether the bowler receives credit
 *   2. Whether this counts as a wicket in the scorecard (retired hurt does not)
 *   3. Any special strike-rotation effects
 *
 * @param {Object} wicket  – The wicket sub-document from the delivery
 * @returns {Object}       – { bowlerCredit, countsAsWicket, note }
 */
function processWicket(wicket) {
  const { dismissalType } = wicket;

  // Retired Hurt: batter leaves the field but CAN return; NOT a wicket
  if (dismissalType === DISMISSAL_TYPES.RETIRED_HURT) {
    return {
      bowlerCredit  : false,
      countsAsWicket: false,
      note          : 'Retired Hurt – batter may return; wicket NOT counted',
    };
  }

  // Retired Out: a wicket, but no bowler credit
  if (dismissalType === DISMISSAL_TYPES.RETIRED_OUT) {
    return {
      bowlerCredit  : false,
      countsAsWicket: true,
      note          : 'Retired Out – counted as a wicket, no bowler credit',
    };
  }

  const bowlerCredit = BOWLER_CREDITED_DISMISSALS.has(dismissalType);

  return {
    bowlerCredit,
    countsAsWicket: true,
    note          : null,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 6 – OVER MANAGEMENT
// ─────────────────────────────────────────────────────────────────────────────

/**
 * calculateOverProgress
 *
 * Given the current innings state, returns the new over-progress values
 * after recording a delivery.
 *
 * @param {Object} innings      – Current innings state
 * @param {boolean} isLegal     – Whether this delivery is a legal ball
 * @param {number}  overLength  – Balls per over (default 6)
 * @returns {Object} { newCompletedOvers, newBallInOver, overJustCompleted }
 */
function calculateOverProgress(innings, isLegal, overLength = 6) {
  let { completedOvers, currentBallInOver } = innings;

  if (!isLegal) {
    // Wide / No Ball: does NOT advance the ball count
    return {
      newCompletedOvers: completedOvers,
      newBallInOver    : currentBallInOver,
      overJustCompleted: false,
    };
  }

  // Legal ball: advance
  currentBallInOver += 1;

  if (currentBallInOver >= overLength) {
    // This legal ball COMPLETES the over
    return {
      newCompletedOvers: completedOvers + 1,
      newBallInOver    : 0,
      overJustCompleted: true,
    };
  }

  return {
    newCompletedOvers: completedOvers,
    newBallInOver    : currentBallInOver,
    overJustCompleted: false,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 7 – MAIDEN OVER DETECTION
// ─────────────────────────────────────────────────────────────────────────────

/**
 * isMaidenOver
 *
 * An over is a maiden if the bowler conceded zero runs FROM THEIR OWN DELIVERIES
 * (bat runs + wides + no-balls counted against the bowler).
 * Byes and leg-byes do NOT break a maiden.
 *
 * @param {Object[]} overDeliveries – All deliveries in the just-completed over
 * @returns {boolean}
 */
function isMaidenOver(overDeliveries) {
  const runsAgainstBowler = overDeliveries.reduce((total, d) => {
    return total + calculateBowlerRuns(d);
  }, 0);
  return runsAgainstBowler === 0;
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 8 – INNINGS COMPLETION CHECK
// ─────────────────────────────────────────────────────────────────────────────

/**
 * isInningsComplete
 *
 * Returns true + reason if the innings should end.
 * Checks:
 *   1. All wickets fallen (10 wickets in standard cricket)
 *   2. Overs completed
 *   3. Target reached (second innings only)
 *
 * @param {Object} innings      – Current innings state
 * @param {Object} matchRules   – { totalOvers, playersPerSide }
 * @returns {{ complete: boolean, reason: string|null }}
 */
function isInningsComplete(innings, matchRules) {
  const { totalOvers, playersPerSide = 11 } = matchRules;
  const maxWickets = playersPerSide - 1; // e.g. 10 wickets for 11 players

  // All out
  if (innings.totalWickets >= maxWickets) {
    return { complete: true, reason: 'all_out' };
  }

  // Overs completed
  if (innings.completedOvers >= totalOvers) {
    return { complete: true, reason: 'overs_complete' };
  }

  // Target reached (2nd innings)
  if (innings.target !== null && innings.totalRuns >= innings.target) {
    return { complete: true, reason: 'target_reached' };
  }

  return { complete: false, reason: null };
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 9 – MATCH RESULT CALCULATION
// ─────────────────────────────────────────────────────────────────────────────

/**
 * calculateMatchResult
 *
 * Determines the winner after both innings are complete.
 *
 * @param {Object} innings1 – First innings
 * @param {Object} innings2 – Second innings
 * @param {Object} match    – Match document (team IDs etc.)
 * @returns {Object} result – { type, winnerTeamId, marginRuns, marginWickets, description }
 */
function calculateMatchResult(innings1, innings2, match) {
  const { MATCH_RESULT_TYPE } = require('../config/constants');

  const score1 = innings1.totalRuns;
  const score2 = innings2.totalRuns;

  if (score1 === score2) {
    return {
      type         : MATCH_RESULT_TYPE.TIE,
      winnerTeamId : null,
      marginRuns   : null,
      marginWickets: null,
      description  : 'Match tied',
    };
  }

  if (score2 >= innings2.target) {
    // Second innings team chased successfully – won by wickets
    const wicketsRemaining =
      (match.rules.playersPerSide - 1) - innings2.totalWickets;
    const winnerTeamId = innings2.battingTeamId;
    const winnerName   = innings2.battingTeamName;
    return {
      type         : MATCH_RESULT_TYPE.WIN_WICKETS,
      winnerTeamId,
      marginRuns   : null,
      marginWickets: wicketsRemaining,
      description  : `${winnerName} won by ${wicketsRemaining} wicket${wicketsRemaining !== 1 ? 's' : ''}`,
    };
  } else {
    // First innings team defended – won by runs
    const margin       = score1 - score2;
    const winnerTeamId = innings1.battingTeamId;
    const winnerName   = innings1.battingTeamName;
    return {
      type         : MATCH_RESULT_TYPE.WIN_RUNS,
      winnerTeamId,
      marginRuns   : margin,
      marginWickets: null,
      description  : `${winnerName} won by ${margin} run${margin !== 1 ? 's' : ''}`,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 10 – BOWLER OVER LIMIT CHECK
// ─────────────────────────────────────────────────────────────────────────────

/**
 * isBowlerAllowedToBowl
 *
 * Checks if a bowler has not exceeded the maximum overs allowed.
 *
 * @param {Object} bowlerState  – From innings.bowlersUsed
 * @param {number} maxOvers     – Maximum overs allowed (from matchRules)
 * @returns {{ allowed: boolean, reason: string|null }}
 */
function isBowlerAllowedToBowl(bowlerState, maxOvers) {
  if (!maxOvers) return { allowed: true, reason: null }; // no limit

  if (bowlerState.overs >= maxOvers) {
    return {
      allowed: false,
      reason : `${bowlerState.playerName} has bowled their maximum ${maxOvers} overs`,
    };
  }

  return { allowed: true, reason: null };
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 11 – REQUIRED RUN RATE CALCULATION
// ─────────────────────────────────────────────────────────────────────────────

/**
 * calculateRequiredRunRate
 *
 * @param {number} runsNeeded     – Runs still needed
 * @param {number} ballsRemaining – Legal balls remaining
 * @returns {number}              – Required run rate (runs per over)
 */
function calculateRequiredRunRate(runsNeeded, ballsRemaining) {
  if (ballsRemaining <= 0) return Infinity;
  const oversRemaining = ballsRemaining / 6;
  return parseFloat((runsNeeded / oversRemaining).toFixed(2));
}

/**
 * calculateCurrentRunRate
 *
 * @param {number} totalRuns      – Runs scored so far
 * @param {number} totalLegalBalls – Legal deliveries faced
 * @returns {number}              – Current run rate (runs per over)
 */
function calculateCurrentRunRate(totalRuns, totalLegalBalls) {
  if (totalLegalBalls === 0) return 0;
  const overs = totalLegalBalls / 6;
  return parseFloat((totalRuns / overs).toFixed(2));
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 12 – EXTRAS BREAKDOWN
// ─────────────────────────────────────────────────────────────────────────────

/**
 * categoriseExtras
 *
 * Returns an object describing how to update the extras breakdown
 * in the innings document for a single delivery.
 *
 * @param {Object} delivery
 * @returns {Object} { wides, noBalls, byes, legByes, penalty }
 */
function categoriseExtras(delivery) {
  const { extraType, extraRuns = 0 } = delivery;

  const result = { wides: 0, noBalls: 0, byes: 0, legByes: 0, penalty: 0 };

  switch (extraType) {
    case EXTRA_TYPES.WIDE    : result.wides   = extraRuns; break;
    case EXTRA_TYPES.NO_BALL : result.noBalls = extraRuns; break;
    case EXTRA_TYPES.BYE     : result.byes    = extraRuns; break;
    case EXTRA_TYPES.LEG_BYE : result.legByes = extraRuns; break;
    case EXTRA_TYPES.PENALTY : result.penalty = extraRuns; break;
    default: break; // EXTRA_TYPES.NONE – nothing to add
  }

  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
//  PUBLIC API
// ─────────────────────────────────────────────────────────────────────────────

module.exports = {
  // Validation
  validateDelivery,

  // Delivery type
  isLegalDelivery,

  // Run calculations
  calculateTotalRuns,
  calculateBowlerRuns,

  // Strike rotation
  shouldRotateStrike,
  shouldSwapAtEndOfOver,

  // Wicket
  processWicket,

  // Over management
  calculateOverProgress,
  isMaidenOver,

  // Innings
  isInningsComplete,

  // Match result
  calculateMatchResult,

  // Bowler limit
  isBowlerAllowedToBowl,

  // Run rates
  calculateRequiredRunRate,
  calculateCurrentRunRate,

  // Extras
  categoriseExtras,
};
