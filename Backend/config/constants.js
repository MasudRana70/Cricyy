/**
 * config/constants.js  –  Application-wide Constants
 *
 * Central place for all fixed values used across the backend.
 * Change a value here and it updates everywhere.
 */

'use strict';

// ── Match Formats ─────────────────────────────────────────────────────────────
const MATCH_FORMATS = {
  T10    : 'T10',
  T20    : 'T20',
  ODI    : 'ODI',
  CUSTOM : 'CUSTOM',
};

// Default overs per format
const FORMAT_OVERS = {
  T10    : 10,
  T20    : 20,
  ODI    : 50,
  CUSTOM : null, // user-defined
};

// Default max overs per bowler (fraction of total overs)
const DEFAULT_MAX_BOWLER_OVERS_FRACTION = 0.2; // 20% – e.g. 4 overs in a T20

// ── Delivery Types ────────────────────────────────────────────────────────────
const EXTRA_TYPES = {
  NONE    : 'none',
  WIDE    : 'wide',
  NO_BALL : 'no_ball',
  BYE     : 'bye',
  LEG_BYE : 'leg_bye',
  PENALTY : 'penalty',
};

// ── Dismissal Types ───────────────────────────────────────────────────────────
// Based on MCC Laws of Cricket 2022 (effective 1 October 2022, still current
// for limited-overs matches; 2026 edition retains all dismissal types).
const DISMISSAL_TYPES = {
  BOWLED               : 'bowled',
  CAUGHT               : 'caught',
  LBW                  : 'lbw',
  RUN_OUT              : 'run_out',
  STUMPED              : 'stumped',
  HIT_WICKET           : 'hit_wicket',
  HIT_BALL_TWICE       : 'hit_ball_twice',
  OBSTRUCTING_FIELD    : 'obstructing_field',
  TIMED_OUT            : 'timed_out',
  RETIRED_OUT          : 'retired_out',
  RETIRED_HURT         : 'retired_hurt',  // NOT a wicket – batter may return
};

// Dismissal types where the BOWLER gets credit for the wicket
const BOWLER_CREDITED_DISMISSALS = new Set([
  DISMISSAL_TYPES.BOWLED,
  DISMISSAL_TYPES.CAUGHT,
  DISMISSAL_TYPES.LBW,
  DISMISSAL_TYPES.STUMPED,
  DISMISSAL_TYPES.HIT_WICKET,
  DISMISSAL_TYPES.HIT_BALL_TWICE,
  DISMISSAL_TYPES.OBSTRUCTING_FIELD,
]);

// Dismissal types that are NOT possible off a No Ball
// (MCC Law 41 – a batter cannot be bowled, LBW, caught, or stumped off a no-ball)
const ILLEGAL_ON_NO_BALL = new Set([
  DISMISSAL_TYPES.BOWLED,
  DISMISSAL_TYPES.LBW,
  DISMISSAL_TYPES.CAUGHT,
  DISMISSAL_TYPES.STUMPED,
  DISMISSAL_TYPES.HIT_WICKET,
]);

// Dismissal types that ARE possible off a Wide
// (MCC Law 25 – only run-out and obstructing the field are possible off a wide)
const LEGAL_ON_WIDE = new Set([
  DISMISSAL_TYPES.RUN_OUT,
  DISMISSAL_TYPES.OBSTRUCTING_FIELD,
  DISMISSAL_TYPES.TIMED_OUT,
  DISMISSAL_TYPES.RETIRED_OUT,
  DISMISSAL_TYPES.RETIRED_HURT,
  DISMISSAL_TYPES.STUMPED, // stumped IS out off a wide
]);

// ── Innings Status ────────────────────────────────────────────────────────────
const INNINGS_STATUS = {
  NOT_STARTED : 'not_started',
  IN_PROGRESS : 'in_progress',
  COMPLETED   : 'completed',
  DECLARED    : 'declared',
};

// ── Match Status ──────────────────────────────────────────────────────────────
const MATCH_STATUS = {
  SETUP     : 'setup',
  IN_PROGRESS: 'in_progress',
  COMPLETED : 'completed',
  ABANDONED : 'abandoned',
  NO_RESULT : 'no_result',
  TIE       : 'tie',
};

// ── Match Result ──────────────────────────────────────────────────────────────
const MATCH_RESULT_TYPE = {
  WIN_RUNS   : 'win_by_runs',
  WIN_WICKETS: 'win_by_wickets',
  TIE        : 'tie',
  NO_RESULT  : 'no_result',
};

// ── Ruleset Versions ─────────────────────────────────────────────────────────
// Stored with every match so future rule-change audits are possible.
const RULESETS = {
  MCC_2026       : 'MCC_2026',      // Laws effective 1 October 2026
  ICC_T20I_2024  : 'ICC_T20I_2024', // ICC T20I Playing Conditions (latest)
  ICC_ODI_2024   : 'ICC_ODI_2024',  // ICC ODI Playing Conditions (latest)
  LOCAL          : 'LOCAL',         // Club / tape-ball / casual rules
};

const DEFAULT_RULESET = RULESETS.MCC_2026;

// ── Pagination ────────────────────────────────────────────────────────────────
const DEFAULT_PAGE_LIMIT = 20;

module.exports = {
  MATCH_FORMATS,
  FORMAT_OVERS,
  DEFAULT_MAX_BOWLER_OVERS_FRACTION,
  EXTRA_TYPES,
  DISMISSAL_TYPES,
  BOWLER_CREDITED_DISMISSALS,
  ILLEGAL_ON_NO_BALL,
  LEGAL_ON_WIDE,
  INNINGS_STATUS,
  MATCH_STATUS,
  MATCH_RESULT_TYPE,
  RULESETS,
  DEFAULT_RULESET,
  DEFAULT_PAGE_LIMIT,
};
