/**
 * tests/scoringService.test.js
 *
 * Comprehensive unit tests for the Cricket Scoring Engine.
 *
 * Run with:   npm test
 *
 * These tests verify that every scoring scenario is handled correctly
 * BEFORE any database interaction.  The scoring engine is a pure module
 * so we can test it without connecting to MongoDB.
 */

'use strict';

const scoring = require('../services/scoringService');
const {
  EXTRA_TYPES,
  DISMISSAL_TYPES,
} = require('../config/constants');

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 1 – DELIVERY VALIDATION
// ─────────────────────────────────────────────────────────────────────────────

describe('validateDelivery', () => {
  const baseRules = { overLength: 6, totalOvers: 20, playersPerSide: 11 };

  test('valid normal delivery – no errors', () => {
    const delivery = { batterRuns: 1, extraRuns: 0, extraType: EXTRA_TYPES.NONE, isWicket: false };
    expect(scoring.validateDelivery(delivery, baseRules)).toHaveLength(0);
  });

  test('valid dot ball – no errors', () => {
    const delivery = { batterRuns: 0, extraRuns: 0, extraType: EXTRA_TYPES.NONE, isWicket: false };
    expect(scoring.validateDelivery(delivery, baseRules)).toHaveLength(0);
  });

  test('valid four – no errors', () => {
    const delivery = { batterRuns: 4, extraRuns: 0, extraType: EXTRA_TYPES.NONE, isFour: true, isWicket: false };
    expect(scoring.validateDelivery(delivery, baseRules)).toHaveLength(0);
  });

  test('valid six – no errors', () => {
    const delivery = { batterRuns: 6, extraRuns: 0, extraType: EXTRA_TYPES.NONE, isSix: true, isWicket: false };
    expect(scoring.validateDelivery(delivery, baseRules)).toHaveLength(0);
  });

  // ── Wide validation ───────────────────────────────────────────────────────
  test('wide with 0 extra runs is invalid', () => {
    const delivery = { batterRuns: 0, extraRuns: 0, extraType: EXTRA_TYPES.WIDE, isWicket: false };
    const errors = scoring.validateDelivery(delivery, baseRules);
    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0]).toMatch(/at least 1 extra run/i);
  });

  test('wide with 1 extra run is valid', () => {
    const delivery = { batterRuns: 0, extraRuns: 1, extraType: EXTRA_TYPES.WIDE, isWicket: false };
    expect(scoring.validateDelivery(delivery, baseRules)).toHaveLength(0);
  });

  test('wide with bat runs is invalid', () => {
    const delivery = { batterRuns: 2, extraRuns: 1, extraType: EXTRA_TYPES.WIDE, isWicket: false };
    const errors = scoring.validateDelivery(delivery, baseRules);
    expect(errors.some(e => /bat runs.*wide/i.test(e))).toBe(true);
  });

  test('bowled off a wide is invalid', () => {
    const delivery = {
      batterRuns: 0, extraRuns: 1, extraType: EXTRA_TYPES.WIDE,
      isWicket: true,
      wicket: { dismissalType: DISMISSAL_TYPES.BOWLED, dismissedPlayerId: 'abc123', bowlerCredit: true },
    };
    const errors = scoring.validateDelivery(delivery, baseRules);
    expect(errors.some(e => /wide/i.test(e))).toBe(true);
  });

  test('stumped off a wide is valid (MCC Law 22.1)', () => {
    const delivery = {
      batterRuns: 0, extraRuns: 1, extraType: EXTRA_TYPES.WIDE,
      isWicket: true,
      wicket: { dismissalType: DISMISSAL_TYPES.STUMPED, dismissedPlayerId: 'abc123', fielderPlayerId: 'wk1', bowlerCredit: true },
    };
    expect(scoring.validateDelivery(delivery, baseRules)).toHaveLength(0);
  });

  test('run-out off a wide is valid', () => {
    const delivery = {
      batterRuns: 0, extraRuns: 1, extraType: EXTRA_TYPES.WIDE,
      isWicket: true,
      wicket: { dismissalType: DISMISSAL_TYPES.RUN_OUT, dismissedPlayerId: 'abc123', bowlerCredit: false, runsCompleted: 0 },
    };
    expect(scoring.validateDelivery(delivery, baseRules)).toHaveLength(0);
  });

  // ── No Ball validation ────────────────────────────────────────────────────
  test('no ball with 0 extra runs is invalid', () => {
    const delivery = { batterRuns: 0, extraRuns: 0, extraType: EXTRA_TYPES.NO_BALL, isWicket: false };
    const errors = scoring.validateDelivery(delivery, baseRules);
    expect(errors.length).toBeGreaterThan(0);
  });

  test('no ball with 1 extra run is valid', () => {
    const delivery = { batterRuns: 0, extraRuns: 1, extraType: EXTRA_TYPES.NO_BALL, isWicket: false };
    expect(scoring.validateDelivery(delivery, baseRules)).toHaveLength(0);
  });

  test('no ball with bat runs is valid (batter can score off a no ball)', () => {
    const delivery = { batterRuns: 4, extraRuns: 1, extraType: EXTRA_TYPES.NO_BALL, isFour: true, isWicket: false };
    expect(scoring.validateDelivery(delivery, baseRules)).toHaveLength(0);
  });

  test('bowled off a no ball is invalid (Law 21.11)', () => {
    const delivery = {
      batterRuns: 0, extraRuns: 1, extraType: EXTRA_TYPES.NO_BALL,
      isWicket: true,
      wicket: { dismissalType: DISMISSAL_TYPES.BOWLED, dismissedPlayerId: 'p1', bowlerCredit: false },
    };
    const errors = scoring.validateDelivery(delivery, baseRules);
    expect(errors.some(e => /no ball/i.test(e))).toBe(true);
  });

  test('LBW off a no ball is invalid', () => {
    const delivery = {
      batterRuns: 0, extraRuns: 1, extraType: EXTRA_TYPES.NO_BALL,
      isWicket: true,
      wicket: { dismissalType: DISMISSAL_TYPES.LBW, dismissedPlayerId: 'p1', bowlerCredit: false },
    };
    expect(scoring.validateDelivery(delivery, baseRules).length).toBeGreaterThan(0);
  });

  test('run-out off a no ball is valid', () => {
    const delivery = {
      batterRuns: 1, extraRuns: 1, extraType: EXTRA_TYPES.NO_BALL,
      isWicket: true,
      wicket: { dismissalType: DISMISSAL_TYPES.RUN_OUT, dismissedPlayerId: 'p1', bowlerCredit: false, runsCompleted: 1 },
    };
    expect(scoring.validateDelivery(delivery, baseRules)).toHaveLength(0);
  });

  // ── Bye / Leg Bye validation ───────────────────────────────────────────────
  test('bye with bat runs is invalid', () => {
    const delivery = { batterRuns: 1, extraRuns: 2, extraType: EXTRA_TYPES.BYE, isWicket: false };
    expect(scoring.validateDelivery(delivery, baseRules).length).toBeGreaterThan(0);
  });

  test('leg bye with 0 extra runs is invalid', () => {
    const delivery = { batterRuns: 0, extraRuns: 0, extraType: EXTRA_TYPES.LEG_BYE, isWicket: false };
    expect(scoring.validateDelivery(delivery, baseRules).length).toBeGreaterThan(0);
  });

  // ── Wicket validation ─────────────────────────────────────────────────────
  test('isWicket true with no wicket details is invalid', () => {
    const delivery = { batterRuns: 0, extraRuns: 0, extraType: EXTRA_TYPES.NONE, isWicket: true, wicket: null };
    expect(scoring.validateDelivery(delivery, baseRules).length).toBeGreaterThan(0);
  });

  test('caught dismissal without fielder is invalid', () => {
    const delivery = {
      batterRuns: 0, extraRuns: 0, extraType: EXTRA_TYPES.NONE,
      isWicket: true,
      wicket: { dismissalType: DISMISSAL_TYPES.CAUGHT, dismissedPlayerId: 'p1', fielderPlayerId: null },
    };
    expect(scoring.validateDelivery(delivery, baseRules).some(e => /fielder/i.test(e))).toBe(true);
  });

  test('caught dismissal with fielder is valid', () => {
    const delivery = {
      batterRuns: 0, extraRuns: 0, extraType: EXTRA_TYPES.NONE,
      isWicket: true,
      wicket: { dismissalType: DISMISSAL_TYPES.CAUGHT, dismissedPlayerId: 'p1', fielderPlayerId: 'f1' },
    };
    expect(scoring.validateDelivery(delivery, baseRules)).toHaveLength(0);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 2 – LEGAL DELIVERY
// ─────────────────────────────────────────────────────────────────────────────

describe('isLegalDelivery', () => {
  test('normal delivery is legal', () => {
    expect(scoring.isLegalDelivery(EXTRA_TYPES.NONE)).toBe(true);
  });
  test('bye is legal', () => {
    expect(scoring.isLegalDelivery(EXTRA_TYPES.BYE)).toBe(true);
  });
  test('leg bye is legal', () => {
    expect(scoring.isLegalDelivery(EXTRA_TYPES.LEG_BYE)).toBe(true);
  });
  test('wide is NOT legal', () => {
    expect(scoring.isLegalDelivery(EXTRA_TYPES.WIDE)).toBe(false);
  });
  test('no ball is NOT legal', () => {
    expect(scoring.isLegalDelivery(EXTRA_TYPES.NO_BALL)).toBe(false);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 3 – RUN CALCULATIONS
// ─────────────────────────────────────────────────────────────────────────────

describe('calculateTotalRuns', () => {
  test('dot ball = 0', () => {
    expect(scoring.calculateTotalRuns({ batterRuns: 0, extraRuns: 0 })).toBe(0);
  });
  test('1 batter run = 1', () => {
    expect(scoring.calculateTotalRuns({ batterRuns: 1, extraRuns: 0 })).toBe(1);
  });
  test('wide = extra runs only', () => {
    expect(scoring.calculateTotalRuns({ batterRuns: 0, extraRuns: 1, extraType: EXTRA_TYPES.WIDE })).toBe(1);
  });
  test('no ball + bat runs', () => {
    expect(scoring.calculateTotalRuns({ batterRuns: 4, extraRuns: 1, extraType: EXTRA_TYPES.NO_BALL })).toBe(5);
  });
  test('bye = extra runs counted in total', () => {
    expect(scoring.calculateTotalRuns({ batterRuns: 0, extraRuns: 4, extraType: EXTRA_TYPES.BYE })).toBe(4);
  });
});

describe('calculateBowlerRuns', () => {
  test('dot ball – 0 against bowler', () => {
    expect(scoring.calculateBowlerRuns({ batterRuns: 0, extraRuns: 0, extraType: EXTRA_TYPES.NONE })).toBe(0);
  });
  test('bat runs charged to bowler', () => {
    expect(scoring.calculateBowlerRuns({ batterRuns: 4, extraRuns: 0, extraType: EXTRA_TYPES.NONE })).toBe(4);
  });
  test('wide charged to bowler', () => {
    expect(scoring.calculateBowlerRuns({ batterRuns: 0, extraRuns: 1, extraType: EXTRA_TYPES.WIDE })).toBe(1);
  });
  test('no ball charged to bowler', () => {
    expect(scoring.calculateBowlerRuns({ batterRuns: 0, extraRuns: 1, extraType: EXTRA_TYPES.NO_BALL })).toBe(1);
  });
  test('bye NOT charged to bowler', () => {
    expect(scoring.calculateBowlerRuns({ batterRuns: 0, extraRuns: 4, extraType: EXTRA_TYPES.BYE })).toBe(0);
  });
  test('leg bye NOT charged to bowler', () => {
    expect(scoring.calculateBowlerRuns({ batterRuns: 0, extraRuns: 2, extraType: EXTRA_TYPES.LEG_BYE })).toBe(0);
  });
  test('no ball + bat runs both charged', () => {
    expect(scoring.calculateBowlerRuns({ batterRuns: 4, extraRuns: 1, extraType: EXTRA_TYPES.NO_BALL })).toBe(5);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 4 – STRIKE ROTATION
// ─────────────────────────────────────────────────────────────────────────────

describe('shouldRotateStrike', () => {
  test('0 runs – no rotation', () => {
    expect(scoring.shouldRotateStrike({ batterRuns: 0, extraRuns: 0, extraType: EXTRA_TYPES.NONE })).toBe(false);
  });
  test('1 run – rotate', () => {
    expect(scoring.shouldRotateStrike({ batterRuns: 1, extraRuns: 0, extraType: EXTRA_TYPES.NONE })).toBe(true);
  });
  test('2 runs – no rotate', () => {
    expect(scoring.shouldRotateStrike({ batterRuns: 2, extraRuns: 0, extraType: EXTRA_TYPES.NONE })).toBe(false);
  });
  test('3 runs – rotate', () => {
    expect(scoring.shouldRotateStrike({ batterRuns: 3, extraRuns: 0, extraType: EXTRA_TYPES.NONE })).toBe(true);
  });
  test('4 runs – no rotate', () => {
    expect(scoring.shouldRotateStrike({ batterRuns: 4, extraRuns: 0, extraType: EXTRA_TYPES.NONE })).toBe(false);
  });
  test('6 runs – no rotate', () => {
    expect(scoring.shouldRotateStrike({ batterRuns: 6, extraRuns: 0, extraType: EXTRA_TYPES.NONE })).toBe(false);
  });

  // Wide: runs crossed = extraRuns - 1
  test('wide 1 extra = 0 runs crossed – no rotate', () => {
    expect(scoring.shouldRotateStrike({ batterRuns: 0, extraRuns: 1, extraType: EXTRA_TYPES.WIDE })).toBe(false);
  });
  test('wide 2 extras = 1 run crossed – rotate', () => {
    expect(scoring.shouldRotateStrike({ batterRuns: 0, extraRuns: 2, extraType: EXTRA_TYPES.WIDE })).toBe(true);
  });
  test('wide 3 extras = 2 runs crossed – no rotate', () => {
    expect(scoring.shouldRotateStrike({ batterRuns: 0, extraRuns: 3, extraType: EXTRA_TYPES.WIDE })).toBe(false);
  });

  // Bye/Leg bye
  test('1 bye – rotate', () => {
    expect(scoring.shouldRotateStrike({ batterRuns: 0, extraRuns: 1, extraType: EXTRA_TYPES.BYE })).toBe(true);
  });
  test('2 leg byes – no rotate', () => {
    expect(scoring.shouldRotateStrike({ batterRuns: 0, extraRuns: 2, extraType: EXTRA_TYPES.LEG_BYE })).toBe(false);
  });

  // Run-out: uses runsCompleted
  test('run-out 0 runs completed – no rotate', () => {
    expect(scoring.shouldRotateStrike({
      batterRuns: 0, extraRuns: 0, extraType: EXTRA_TYPES.NONE,
      isWicket: true,
      wicket: { dismissalType: DISMISSAL_TYPES.RUN_OUT, runsCompleted: 0 },
    })).toBe(false);
  });
  test('run-out 1 run completed – rotate', () => {
    expect(scoring.shouldRotateStrike({
      batterRuns: 1, extraRuns: 0, extraType: EXTRA_TYPES.NONE,
      isWicket: true,
      wicket: { dismissalType: DISMISSAL_TYPES.RUN_OUT, runsCompleted: 1 },
    })).toBe(true);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 5 – WICKET PROCESSING
// ─────────────────────────────────────────────────────────────────────────────

describe('processWicket', () => {
  test('bowled – bowler credit, counts as wicket', () => {
    const result = scoring.processWicket({ dismissalType: DISMISSAL_TYPES.BOWLED });
    expect(result.bowlerCredit).toBe(true);
    expect(result.countsAsWicket).toBe(true);
  });
  test('caught – bowler credit, counts as wicket', () => {
    const result = scoring.processWicket({ dismissalType: DISMISSAL_TYPES.CAUGHT });
    expect(result.bowlerCredit).toBe(true);
    expect(result.countsAsWicket).toBe(true);
  });
  test('LBW – bowler credit, counts as wicket', () => {
    const result = scoring.processWicket({ dismissalType: DISMISSAL_TYPES.LBW });
    expect(result.bowlerCredit).toBe(true);
    expect(result.countsAsWicket).toBe(true);
  });
  test('stumped – bowler credit, counts as wicket', () => {
    const result = scoring.processWicket({ dismissalType: DISMISSAL_TYPES.STUMPED });
    expect(result.bowlerCredit).toBe(true);
    expect(result.countsAsWicket).toBe(true);
  });
  test('run-out – NO bowler credit, counts as wicket', () => {
    const result = scoring.processWicket({ dismissalType: DISMISSAL_TYPES.RUN_OUT });
    expect(result.bowlerCredit).toBe(false);
    expect(result.countsAsWicket).toBe(true);
  });
  test('retired hurt – NO bowler credit, does NOT count as wicket', () => {
    const result = scoring.processWicket({ dismissalType: DISMISSAL_TYPES.RETIRED_HURT });
    expect(result.bowlerCredit).toBe(false);
    expect(result.countsAsWicket).toBe(false);
  });
  test('retired out – NO bowler credit, counts as wicket', () => {
    const result = scoring.processWicket({ dismissalType: DISMISSAL_TYPES.RETIRED_OUT });
    expect(result.bowlerCredit).toBe(false);
    expect(result.countsAsWicket).toBe(true);
  });
  test('hit wicket – bowler credit', () => {
    const result = scoring.processWicket({ dismissalType: DISMISSAL_TYPES.HIT_WICKET });
    expect(result.bowlerCredit).toBe(true);
    expect(result.countsAsWicket).toBe(true);
  });
  test('obstructing field – bowler credit', () => {
    const result = scoring.processWicket({ dismissalType: DISMISSAL_TYPES.OBSTRUCTING_FIELD });
    expect(result.bowlerCredit).toBe(true);
    expect(result.countsAsWicket).toBe(true);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 6 – OVER MANAGEMENT
// ─────────────────────────────────────────────────────────────────────────────

describe('calculateOverProgress', () => {
  const baseInnings = { completedOvers: 0, currentBallInOver: 0 };

  test('ball 1 of first over – not complete', () => {
    const result = scoring.calculateOverProgress(baseInnings, true, 6);
    expect(result.newCompletedOvers).toBe(0);
    expect(result.newBallInOver).toBe(1);
    expect(result.overJustCompleted).toBe(false);
  });

  test('6th legal ball completes the over', () => {
    const innings = { completedOvers: 0, currentBallInOver: 5 };
    const result = scoring.calculateOverProgress(innings, true, 6);
    expect(result.newCompletedOvers).toBe(1);
    expect(result.newBallInOver).toBe(0);
    expect(result.overJustCompleted).toBe(true);
  });

  test('wide does NOT advance ball count', () => {
    const innings = { completedOvers: 0, currentBallInOver: 3 };
    const result = scoring.calculateOverProgress(innings, false, 6); // isLegal = false
    expect(result.newBallInOver).toBe(3);
    expect(result.overJustCompleted).toBe(false);
  });

  test('no ball does NOT advance ball count', () => {
    const innings = { completedOvers: 1, currentBallInOver: 2 };
    const result = scoring.calculateOverProgress(innings, false, 6);
    expect(result.newBallInOver).toBe(2);
    expect(result.newCompletedOvers).toBe(1);
  });

  test('over 7 of T20 – counting continues', () => {
    const innings = { completedOvers: 6, currentBallInOver: 5 };
    const result = scoring.calculateOverProgress(innings, true, 6);
    expect(result.newCompletedOvers).toBe(7);
    expect(result.overJustCompleted).toBe(true);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 7 – MAIDEN OVER
// ─────────────────────────────────────────────────────────────────────────────

describe('isMaidenOver', () => {
  test('all dot balls = maiden', () => {
    const overs = Array(6).fill({ batterRuns: 0, extraRuns: 0, extraType: EXTRA_TYPES.NONE });
    expect(scoring.isMaidenOver(overs)).toBe(true);
  });

  test('one run = not maiden', () => {
    const overs = [
      { batterRuns: 1, extraRuns: 0, extraType: EXTRA_TYPES.NONE },
      ...Array(5).fill({ batterRuns: 0, extraRuns: 0, extraType: EXTRA_TYPES.NONE }),
    ];
    expect(scoring.isMaidenOver(overs)).toBe(false);
  });

  test('wide = not maiden (wide counts against bowler)', () => {
    const overs = [
      { batterRuns: 0, extraRuns: 1, extraType: EXTRA_TYPES.WIDE },
      ...Array(6).fill({ batterRuns: 0, extraRuns: 0, extraType: EXTRA_TYPES.NONE }),
    ];
    expect(scoring.isMaidenOver(overs)).toBe(false);
  });

  test('bye = maiden (bye NOT charged to bowler)', () => {
    const overs = [
      { batterRuns: 0, extraRuns: 4, extraType: EXTRA_TYPES.BYE },
      ...Array(5).fill({ batterRuns: 0, extraRuns: 0, extraType: EXTRA_TYPES.NONE }),
    ];
    expect(scoring.isMaidenOver(overs)).toBe(true);
  });

  test('leg bye = maiden', () => {
    const overs = [
      { batterRuns: 0, extraRuns: 1, extraType: EXTRA_TYPES.LEG_BYE },
      ...Array(5).fill({ batterRuns: 0, extraRuns: 0, extraType: EXTRA_TYPES.NONE }),
    ];
    expect(scoring.isMaidenOver(overs)).toBe(true);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 8 – INNINGS COMPLETION
// ─────────────────────────────────────────────────────────────────────────────

describe('isInningsComplete', () => {
  const rules = { totalOvers: 20, playersPerSide: 11 };

  test('no wickets, no overs – not complete', () => {
    const innings = { totalWickets: 0, completedOvers: 0, totalRuns: 0, target: null };
    expect(scoring.isInningsComplete(innings, rules).complete).toBe(false);
  });

  test('10 wickets = all out', () => {
    const innings = { totalWickets: 10, completedOvers: 10, totalRuns: 100, target: null };
    const result = scoring.isInningsComplete(innings, rules);
    expect(result.complete).toBe(true);
    expect(result.reason).toBe('all_out');
  });

  test('20 overs completed = complete', () => {
    const innings = { totalWickets: 3, completedOvers: 20, totalRuns: 150, target: null };
    const result = scoring.isInningsComplete(innings, rules);
    expect(result.complete).toBe(true);
    expect(result.reason).toBe('overs_complete');
  });

  test('target reached in 2nd innings', () => {
    const innings = { totalWickets: 2, completedOvers: 15, totalRuns: 160, target: 160 };
    const result = scoring.isInningsComplete(innings, rules);
    expect(result.complete).toBe(true);
    expect(result.reason).toBe('target_reached');
  });

  test('target NOT yet reached', () => {
    const innings = { totalWickets: 2, completedOvers: 15, totalRuns: 100, target: 160 };
    expect(scoring.isInningsComplete(innings, rules).complete).toBe(false);
  });

  test('7-player team, 6 wickets = all out', () => {
    const r = { totalOvers: 10, playersPerSide: 7 };
    const innings = { totalWickets: 6, completedOvers: 5, totalRuns: 50, target: null };
    const result = scoring.isInningsComplete(innings, r);
    expect(result.complete).toBe(true);
    expect(result.reason).toBe('all_out');
  });
});

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 9 – MATCH RESULT
// ─────────────────────────────────────────────────────────────────────────────

describe('calculateMatchResult', () => {
  const fakeMatch = {
    rules: { playersPerSide: 11 },
    team1Id: 'team1',
    team2Id: 'team2',
  };

  test('team batting second chases – win by wickets', () => {
    const innings1 = { totalRuns: 150, battingTeamId: 'team1', battingTeamName: 'Team A' };
    const innings2 = { totalRuns: 151, totalWickets: 4, battingTeamId: 'team2', battingTeamName: 'Team B', target: 151 };
    const result = scoring.calculateMatchResult(innings1, innings2, fakeMatch);
    expect(result.type).toBe('win_by_wickets');
    expect(result.winnerTeamId).toBe('team2');
    // (playersPerSide-1) - wickets = 10 - 4 = 6 wickets in hand
    expect(result.marginWickets).toBe(6);
  });

  test('team batting first defends – win by runs', () => {
    const innings1 = { totalRuns: 180, battingTeamId: 'team1', battingTeamName: 'Team A' };
    const innings2 = { totalRuns: 160, totalWickets: 10, battingTeamId: 'team2', battingTeamName: 'Team B', target: 181 };
    const result = scoring.calculateMatchResult(innings1, innings2, fakeMatch);
    expect(result.type).toBe('win_by_runs');
    expect(result.winnerTeamId).toBe('team1');
    expect(result.marginRuns).toBe(20);
  });

  test('equal scores = tie', () => {
    const innings1 = { totalRuns: 150, battingTeamId: 'team1', battingTeamName: 'Team A' };
    const innings2 = { totalRuns: 150, totalWickets: 10, battingTeamId: 'team2', battingTeamName: 'Team B', target: 151 };
    const result = scoring.calculateMatchResult(innings1, innings2, fakeMatch);
    expect(result.type).toBe('tie');
  });
});

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 10 – RUN RATES
// ─────────────────────────────────────────────────────────────────────────────

describe('run rate calculations', () => {
  test('current run rate – 60 runs in 60 balls = 6.00', () => {
    expect(scoring.calculateCurrentRunRate(60, 60)).toBe(6);
  });
  test('current run rate – 0 balls = 0', () => {
    expect(scoring.calculateCurrentRunRate(0, 0)).toBe(0);
  });
  test('required run rate – 60 needed in 60 balls = 6.00', () => {
    expect(scoring.calculateRequiredRunRate(60, 60)).toBe(6);
  });
  test('required run rate – 0 balls remaining = Infinity', () => {
    expect(scoring.calculateRequiredRunRate(10, 0)).toBe(Infinity);
  });
  test('required run rate – 1 needed in 6 balls = 1.00', () => {
    expect(scoring.calculateRequiredRunRate(1, 6)).toBe(1);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 11 – EXTRAS BREAKDOWN
// ─────────────────────────────────────────────────────────────────────────────

describe('categoriseExtras', () => {
  test('wide goes to wides', () => {
    const result = scoring.categoriseExtras({ extraType: EXTRA_TYPES.WIDE, extraRuns: 1 });
    expect(result.wides).toBe(1);
    expect(result.noBalls).toBe(0);
  });
  test('no ball goes to noBalls', () => {
    const result = scoring.categoriseExtras({ extraType: EXTRA_TYPES.NO_BALL, extraRuns: 1 });
    expect(result.noBalls).toBe(1);
    expect(result.wides).toBe(0);
  });
  test('bye goes to byes', () => {
    const result = scoring.categoriseExtras({ extraType: EXTRA_TYPES.BYE, extraRuns: 4 });
    expect(result.byes).toBe(4);
  });
  test('leg bye goes to legByes', () => {
    const result = scoring.categoriseExtras({ extraType: EXTRA_TYPES.LEG_BYE, extraRuns: 2 });
    expect(result.legByes).toBe(2);
  });
  test('penalty goes to penalty', () => {
    const result = scoring.categoriseExtras({ extraType: EXTRA_TYPES.PENALTY, extraRuns: 5 });
    expect(result.penalty).toBe(5);
  });
  test('normal delivery – all zeros', () => {
    const result = scoring.categoriseExtras({ extraType: EXTRA_TYPES.NONE, extraRuns: 0 });
    expect(Object.values(result).every(v => v === 0)).toBe(true);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION 12 – BOWLER OVER LIMIT
// ─────────────────────────────────────────────────────────────────────────────

describe('isBowlerAllowedToBowl', () => {
  test('bowler has bowled 3 of 4 max – allowed', () => {
    const result = scoring.isBowlerAllowedToBowl({ overs: 3, playerName: 'Ali' }, 4);
    expect(result.allowed).toBe(true);
  });
  test('bowler has bowled 4 of 4 max – not allowed', () => {
    const result = scoring.isBowlerAllowedToBowl({ overs: 4, playerName: 'Ali' }, 4);
    expect(result.allowed).toBe(false);
  });
  test('no over limit – always allowed', () => {
    const result = scoring.isBowlerAllowedToBowl({ overs: 100, playerName: 'Ali' }, null);
    expect(result.allowed).toBe(true);
  });
});
