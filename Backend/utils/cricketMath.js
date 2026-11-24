/**
 * utils/cricketMath.js  –  Reusable Cricket Mathematics Helpers
 *
 * Small, pure functions that are used by multiple services.
 */

'use strict';

/**
 * formatOvers
 * Converts a legal-ball count to the standard over notation string.
 * e.g. 16 balls → "2.4" (2 complete overs + 4 balls)
 *
 * @param {number} legalBalls
 * @param {number} overLength  – balls per over (default 6)
 * @returns {string}  e.g. "2.4"
 */
function formatOvers(legalBalls, overLength = 6) {
  const completed = Math.floor(legalBalls / overLength);
  const remaining = legalBalls % overLength;
  return `${completed}.${remaining}`;
}

/**
 * parseOversToLegalBalls
 * Inverse of formatOvers.
 * "3.4" → 22 legal balls
 *
 * @param {string|number} overs – e.g. "3.4" or 3.4
 * @param {number} overLength
 * @returns {number}
 */
function parseOversToLegalBalls(overs, overLength = 6) {
  const str    = String(overs);
  const parts  = str.split('.');
  const full   = parseInt(parts[0], 10) || 0;
  const extra  = parseInt(parts[1], 10) || 0;
  return full * overLength + extra;
}

/**
 * safeAverage
 * Returns numerator/denominator, or null if denominator is 0.
 */
function safeAverage(numerator, denominator, decimalPlaces = 2) {
  if (denominator === 0) return null;
  return parseFloat((numerator / denominator).toFixed(decimalPlaces));
}

/**
 * safeRate
 * Like safeAverage but returns 0 instead of null when denominator is 0.
 */
function safeRate(numerator, denominator, decimalPlaces = 2) {
  if (denominator === 0) return 0;
  return parseFloat((numerator / denominator).toFixed(decimalPlaces));
}

module.exports = { formatOvers, parseOversToLegalBalls, safeAverage, safeRate };
