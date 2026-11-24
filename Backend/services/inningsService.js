/**
 * services/inningsService.js  –  Innings & Delivery Orchestration
 *
 * This service:
 *   1. Takes a validated delivery input
 *   2. Calls the scoring engine (scoringService.js) for all calculations
 *   3. Saves the Delivery document
 *   4. Updates the Innings document (live cache)
 *   5. Returns the updated innings state
 *
 * It uses MongoDB sessions (transactions) so that if any step fails,
 * none of the partial writes are saved.
 */

'use strict';

const mongoose       = require('mongoose');
const Innings        = require('../models/Innings');
const Delivery       = require('../models/Delivery');
const MatchEvent     = require('../models/MatchEvent');
const scoring        = require('./scoringService');
const { INNINGS_STATUS, EXTRA_TYPES } = require('../config/constants');

// ─────────────────────────────────────────────────────────────────────────────
//  Helper: find a batter in the currentBatters array by player ID
// ─────────────────────────────────────────────────────────────────────────────
function findBatter(batters, playerId) {
  return batters.find(b => b.playerId.toString() === playerId.toString());
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helper: find or create bowler state in bowlersUsed
// ─────────────────────────────────────────────────────────────────────────────
function getOrCreateBowlerState(innings, bowlerId, bowlerName) {
  let bowler = innings.bowlersUsed.find(
    b => b.playerId.toString() === bowlerId.toString()
  );
  if (!bowler) {
    innings.bowlersUsed.push({
      playerId  : bowlerId,
      playerName: bowlerName,
      overs     : 0,
      balls     : 0,
      maidens   : 0,
      runs      : 0,
      wickets   : 0,
      wides     : 0,
      noBalls   : 0,
      isCurrent : true,
    });
    bowler = innings.bowlersUsed[innings.bowlersUsed.length - 1];
  }
  return bowler;
}

// ─────────────────────────────────────────────────────────────────────────────
//  recordDelivery  –  THE MAIN FUNCTION
// ─────────────────────────────────────────────────────────────────────────────

/**
 * recordDelivery
 *
 * Processes a single delivery and persists all resulting changes.
 *
 * @param {string} inningsId   – Innings MongoDB ObjectId
 * @param {Object} deliveryInput – Raw input from the API controller
 * @param {Object} matchRules  – Rules from the Match document
 * @returns {Object}           – { innings, delivery, inningsComplete, reason }
 */
async function recordDelivery(inningsId, deliveryInput, matchRules) {
  // ── 1. Load the innings ──────────────────────────────────────────────────
  const innings = await Innings.findById(inningsId);
  if (!innings) throw new Error('Innings not found');
  if (innings.status === INNINGS_STATUS.COMPLETED) {
    throw new Error('This innings is already completed');
  }

  // ── 2. Validate the delivery against cricket rules ───────────────────────
  const errors = scoring.validateDelivery(deliveryInput, matchRules);
  if (errors.length > 0) {
    const err = new Error(errors.join('; '));
    err.statusCode = 400;
    throw err;
  }

  // ── 3. Determine delivery legality ───────────────────────────────────────
  const legal = scoring.isLegalDelivery(deliveryInput.extraType);

  // ── 4. Calculate over progress ────────────────────────────────────────────
  const overLength = matchRules.overLength || 6;
  const { newCompletedOvers, newBallInOver, overJustCompleted } =
    scoring.calculateOverProgress(innings, legal, overLength);

  // ── 5. Calculate runs ─────────────────────────────────────────────────────
  const totalRuns   = scoring.calculateTotalRuns(deliveryInput);
  const bowlerRuns  = scoring.calculateBowlerRuns(deliveryInput);
  const extraBreakdown = scoring.categoriseExtras(deliveryInput);

  // ── 6. Update extras in innings ───────────────────────────────────────────
  innings.extras.wides   += extraBreakdown.wides;
  innings.extras.noBalls += extraBreakdown.noBalls;
  innings.extras.byes    += extraBreakdown.byes;
  innings.extras.legByes += extraBreakdown.legByes;
  innings.extras.penalty += extraBreakdown.penalty;
  innings.extras.total   += (deliveryInput.extraRuns || 0);

  // ── 7. Find the striker (batter facing this ball) ─────────────────────────
  const striker = innings.currentBatters.find(b => b.isStriker);
  if (!striker) throw new Error('No striker found in innings state');

  const nonStriker = innings.currentBatters.find(b => !b.isStriker);
  if (!nonStriker) throw new Error('No non-striker found in innings state');

  // ── 8. Update batter statistics ───────────────────────────────────────────
  // Find the batter in battersUsed (the full record)
  let strikerRecord = innings.battersUsed.find(
    b => b.playerId.toString() === striker.playerId.toString()
  );
  if (!strikerRecord) {
    innings.battersUsed.push({ ...striker.toObject(), isStriker: true });
    strikerRecord = innings.battersUsed[innings.battersUsed.length - 1];
  }

  const isWide = deliveryInput.extraType === EXTRA_TYPES.WIDE;

  if (!isWide) {
    // A wide ball is not faced by the batter – don't add to their balls faced
    strikerRecord.balls   += legal ? 1 : 1; // No ball IS faced by the batter
    // For wides: no ball added
  }
  // Bat runs
  strikerRecord.runs += deliveryInput.batterRuns || 0;
  if (deliveryInput.isFour) strikerRecord.fours += 1;
  if (deliveryInput.isSix)  strikerRecord.sixes += 1;

  // Also update the currentBatters entry (live cache)
  striker.runs  = strikerRecord.runs;
  striker.balls = strikerRecord.balls;
  striker.fours = strikerRecord.fours;
  striker.sixes = strikerRecord.sixes;

  // ── 9. Wicket processing ──────────────────────────────────────────────────
  let countsAsWicket = false;
  let bowlerCredit   = false;

  if (deliveryInput.isWicket && deliveryInput.wicket) {
    const wicketResult = scoring.processWicket(deliveryInput.wicket);
    countsAsWicket = wicketResult.countsAsWicket;
    bowlerCredit   = wicketResult.bowlerCredit;

    if (countsAsWicket) {
      innings.totalWickets += 1;

      // Record fall of wicket
      innings.fallOfWickets.push({
        wicketNumber: innings.totalWickets,
        score       : innings.totalRuns + totalRuns,
        playerId    : deliveryInput.wicket.dismissedPlayerId,
        playerName  : deliveryInput.wicket.dismissedPlayerName,
        overNumber  : innings.completedOvers,
        ballNumber  : newBallInOver,
      });

      // Mark batter as out
      const dismissedRecord = innings.battersUsed.find(
        b => b.playerId.toString() === deliveryInput.wicket.dismissedPlayerId.toString()
      );
      if (dismissedRecord) {
        dismissedRecord.isOut = true;
      }

      // Remove from currentBatters
      const dismissedIdx = innings.currentBatters.findIndex(
        b => b.playerId.toString() === deliveryInput.wicket.dismissedPlayerId.toString()
      );
      if (dismissedIdx !== -1) {
        innings.currentBatters.splice(dismissedIdx, 1);
      }
    }
  }

  // ── 10. Update bowler statistics ──────────────────────────────────────────
  const bowlerState = getOrCreateBowlerState(
    innings,
    deliveryInput.bowlerId,
    deliveryInput.bowlerName
  );

  bowlerState.runs += bowlerRuns;
  if (bowlerCredit) bowlerState.wickets += 1;

  if (legal) {
    bowlerState.balls += 1;
    if (bowlerState.balls >= overLength) {
      bowlerState.overs += 1;
      bowlerState.balls  = 0;
    }
  }

  if (deliveryInput.extraType === EXTRA_TYPES.WIDE)    bowlerState.wides   += 1;
  if (deliveryInput.extraType === EXTRA_TYPES.NO_BALL) bowlerState.noBalls += 1;

  // ── 11. Maiden over check ─────────────────────────────────────────────────
  if (overJustCompleted) {
    // Fetch all deliveries in the just-completed over to check for maiden
    const overDeliveries = await Delivery.find({
      inningsId,
      overNumber: innings.completedOvers,
      isUndone  : false,
    });

    // Include this delivery (not saved yet) in the check
    if (scoring.isMaidenOver([...overDeliveries, deliveryInput])) {
      bowlerState.maidens += 1;
      // Record in overSummaries
    }

    // Record over summary
    innings.overSummaries.push({
      overNumber: innings.completedOvers,
      bowlerId  : deliveryInput.bowlerId,
      bowlerName: deliveryInput.bowlerName,
      runs      : 0, // TODO: sum properly from overDeliveries
      wickets   : countsAsWicket ? 1 : 0,
      isMaiden  : scoring.isMaidenOver([...overDeliveries, deliveryInput]),
      balls     : [], // notation built by delivery controller
    });
  }

  // ── 12. Update innings totals ─────────────────────────────────────────────
  innings.totalRuns        += totalRuns;
  innings.completedOvers    = newCompletedOvers;
  innings.currentBallInOver = newBallInOver;
  if (legal) innings.totalLegalBalls += 1;

  // ── 13. Strike rotation ───────────────────────────────────────────────────
  const rotateStrike  = scoring.shouldRotateStrike(deliveryInput);
  const swapEndOfOver = overJustCompleted && scoring.shouldSwapAtEndOfOver();

  // Apply mid-delivery strike rotation FIRST, then end-of-over swap.
  // Net result: if BOTH are true they cancel out (back to original ends).
  let strikeChanged = false;
  if (rotateStrike) {
    // Swap striker/non-striker
    striker.isStriker    = false;
    nonStriker.isStriker = true;
    strikeChanged = true;
  }
  if (swapEndOfOver) {
    // Swap again at end of over
    const curStriker    = innings.currentBatters.find(b => b.isStriker);
    const curNonStriker = innings.currentBatters.find(b => !b.isStriker);
    if (curStriker && curNonStriker) {
      curStriker.isStriker    = false;
      curNonStriker.isStriker = true;
    }
  }

  // ── 14. Check innings completion ─────────────────────────────────────────
  const { complete, reason } = scoring.isInningsComplete(innings, matchRules);
  if (complete) {
    innings.status = INNINGS_STATUS.COMPLETED;
  }

  // ── 15. Build the Delivery document ──────────────────────────────────────
  const nextSequence = await Delivery.countDocuments({ inningsId, isUndone: false }) + 1;

  const deliveryDoc = new Delivery({
    matchId          : innings.matchId,
    inningsId        : innings._id,
    deliverySequence : nextSequence,
    overNumber       : innings.completedOvers - (overJustCompleted ? 1 : 0),
    ballNumber       : overJustCompleted ? overLength : newBallInOver,
    isLegal          : legal,

    strikerId      : deliveryInput.strikerId,
    strikerName    : deliveryInput.strikerName,
    nonStrikerId   : deliveryInput.nonStrikerId,
    nonStrikerName : deliveryInput.nonStrikerName,
    bowlerId       : deliveryInput.bowlerId,
    bowlerName     : deliveryInput.bowlerName,

    batterRuns : deliveryInput.batterRuns || 0,
    extraType  : deliveryInput.extraType  || EXTRA_TYPES.NONE,
    extraRuns  : deliveryInput.extraRuns  || 0,
    totalRuns,

    isFour : deliveryInput.isFour  || false,
    isSix  : deliveryInput.isSix   || false,

    isWicket: deliveryInput.isWicket || false,
    wicket  : deliveryInput.isWicket ? {
      ...deliveryInput.wicket,
      bowlerCredit,
    } : null,

    strikeRotated      : rotateStrike,
    strikerChangedAfter: swapEndOfOver,

    // Snapshot of state AFTER this delivery (for undo support)
    snapshotAfter: {
      totalRuns     : innings.totalRuns,
      totalWickets  : innings.totalWickets,
      completedOvers: innings.completedOvers,
      ballInOver    : innings.currentBallInOver,
      strikerId     : innings.currentBatters.find(b => b.isStriker)?.playerId,
      nonStrikerId  : innings.currentBatters.find(b => !b.isStriker)?.playerId,
      currentBowlerId: deliveryInput.bowlerId,
    },

    notes: deliveryInput.notes || null,
  });

  // ── 16. Save everything ───────────────────────────────────────────────────
  // Using a MongoDB session (transaction) so both saves are atomic
  const session = await mongoose.startSession();
  try {
    await session.withTransaction(async () => {
      await deliveryDoc.save({ session });
      await innings.save({ session });
    });
  } finally {
    await session.endSession();
  }

  return {
    delivery       : deliveryDoc,
    innings,
    inningsComplete: complete,
    completionReason: reason,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
//  undoLastDelivery
// ─────────────────────────────────────────────────────────────────────────────

/**
 * undoLastDelivery
 *
 * Soft-deletes the most recent delivery and restores the innings state
 * from the PREVIOUS delivery's snapshotAfter.
 *
 * @param {string} inningsId
 * @returns {Object} – { innings, undoneDelivery }
 */
async function undoLastDelivery(inningsId) {
  const innings = await Innings.findById(inningsId);
  if (!innings) throw new Error('Innings not found');

  // Find the last non-undone delivery
  const lastDelivery = await Delivery.findOne(
    { inningsId, isUndone: false },
    null,
    { sort: { deliverySequence: -1 } }
  );

  if (!lastDelivery) throw new Error('No deliveries to undo');

  // Find the previous delivery to restore from
  const prevDelivery = await Delivery.findOne(
    { inningsId, isUndone: false, deliverySequence: { $lt: lastDelivery.deliverySequence } },
    null,
    { sort: { deliverySequence: -1 } }
  );

  // Mark the last delivery as undone
  lastDelivery.isUndone = true;

  const session = await mongoose.startSession();
  try {
    await session.withTransaction(async () => {
      await lastDelivery.save({ session });

      if (prevDelivery && prevDelivery.snapshotAfter) {
        // Restore innings totals from previous snapshot
        const snap = prevDelivery.snapshotAfter;
        innings.totalRuns         = snap.totalRuns;
        innings.totalWickets      = snap.totalWickets;
        innings.completedOvers    = snap.completedOvers;
        innings.currentBallInOver = snap.ballInOver;
        innings.totalLegalBalls   = await Delivery.countDocuments({
          inningsId, isUndone: false
        });
        // Restore striker position
        innings.currentBatters.forEach(b => {
          b.isStriker = b.playerId.toString() === snap.strikerId?.toString();
        });
      } else {
        // Undo the VERY FIRST delivery – reset innings to zero
        innings.totalRuns         = 0;
        innings.totalWickets      = 0;
        innings.completedOvers    = 0;
        innings.currentBallInOver = 0;
        innings.totalLegalBalls   = 0;
        innings.extras            = { wides:0, noBalls:0, byes:0, legByes:0, penalty:0, total:0 };
        innings.fallOfWickets     = [];
      }

      innings.status = INNINGS_STATUS.IN_PROGRESS;
      await innings.save({ session });
    });
  } finally {
    await session.endSession();
  }

  return { innings, undoneDelivery: lastDelivery };
}

module.exports = { recordDelivery, undoLastDelivery };
