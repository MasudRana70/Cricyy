/**
 * middleware/errorMiddleware.js  –  Centralised Error Handling
 *
 * Express looks for middleware functions with FOUR parameters (err, req, res, next)
 * and treats them as error handlers.  Any call to next(error) anywhere in the
 * application ends up here.
 *
 * Two middleware functions are exported:
 *   notFound    – called when no route matched (404)
 *   errorHandler – called when any route throws or calls next(err)
 */

'use strict';

/**
 * notFound
 * Called when Express has gone through all routes and found no match.
 * Creates a 404 error and passes it to the error handler below.
 */
const notFound = (req, res, next) => {
  const error = new Error(`Route not found: ${req.method} ${req.originalUrl}`);
  res.status(404);
  next(error); // pass to errorHandler
};

/**
 * errorHandler
 * The single place that sends error responses to the client.
 *
 * Always returns JSON – the Flutter app always expects JSON.
 */
const errorHandler = (err, req, res, next) => { // eslint-disable-line no-unused-vars
  // Sometimes a 200 status has been set before an error was thrown.
  // In that case, force it to 500.
  const statusCode = res.statusCode !== 200 ? res.statusCode : 500;

  res.status(statusCode).json({
    success: false,
    message: err.message || 'Internal Server Error',
    // Show the full error stack only during development – never in production
    stack: process.env.NODE_ENV === 'production' ? undefined : err.stack,
  });
};

module.exports = { notFound, errorHandler };
