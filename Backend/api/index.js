/**
 * api/index.js  –  Vercel Serverless Function Entrypoint
 *
 * Routes all incoming Vercel requests into the Express application exported by ../index.js.
 */

'use strict';

module.exports = require('../index');
