/**
 * index.js  –  Cricyy Backend Entry Point
 *
 * What this file does:
 *   1. Loads environment variables from .env
 *   2. Connects to MongoDB
 *   3. Creates and configures the Express application
 *   4. Mounts all API routes
 *   5. Starts the HTTP server
 *
 * Run with:   node index.js
 * Dev mode:   npx nodemon index.js   (auto-restarts on file changes)
 */

'use strict';

// Step 1: Load .env FIRST – before any other require()
require('dotenv').config();

const express = require('express');
const cors    = require('cors');
const morgan  = require('morgan');
const path    = require('path');

const connectDB         = require('./config/db');
const { notFound, errorHandler } = require('./middleware/errorMiddleware');

// ── Route imports ────────────────────────────────────────────────────────────
const playerRoutes   = require('./routes/playerRoutes');
const teamRoutes     = require('./routes/teamRoutes');
const matchRoutes    = require('./routes/matchRoutes');
const inningsRoutes  = require('./routes/inningsRoutes');
const deliveryRoutes = require('./routes/deliveryRoutes');
const scorecardRoutes= require('./routes/scorecardRoutes');

// ── Connect to MongoDB ────────────────────────────────────────────────────────
connectDB();

// ── Create Express app ────────────────────────────────────────────────────────
const app = express();

// ── Global Middleware ─────────────────────────────────────────────────────────

// Allow cross-origin requests (Flutter app on a different port/device)
app.use(cors());

// Parse incoming JSON request bodies
app.use(express.json());

// Parse URL-encoded bodies (for form submissions)
app.use(express.urlencoded({ extended: false }));

// HTTP request logging – 'dev' format is colorful and readable during development
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

// Serve uploaded files (player/team images) as static files
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ── Health Check ──────────────────────────────────────────────────────────────
// Visiting GET /api/health tells you the server is alive.
app.get('/api/health', (req, res) => {
  res.json({
    status : 'ok',
    message: 'Cricyy backend is running',
    time   : new Date().toISOString(),
  });
});

// ── API Routes ────────────────────────────────────────────────────────────────
app.use('/api/players',  playerRoutes);
app.use('/api/teams',    teamRoutes);
app.use('/api/matches',  matchRoutes);
app.use('/api/matches',  inningsRoutes);   // /api/matches/:id/innings
app.use('/api/matches',  deliveryRoutes);  // /api/matches/:id/deliveries
app.use('/api/matches',  scorecardRoutes); // /api/matches/:id/scorecard

// ── Error Handling Middleware (must be LAST) ───────────────────────────────────
app.use(notFound);
app.use(errorHandler);

// ── Start Server ──────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 5000;

const server = app.listen(PORT, () => {
  console.log(`\n✅ Cricyy backend running on http://localhost:${PORT}`);
  console.log(`   Environment : ${process.env.NODE_ENV || 'development'}`);
  console.log(`   Health check: http://localhost:${PORT}/api/health\n`);
});

// Graceful shutdown – close DB connection when the process is stopped
process.on('SIGTERM', () => {
  console.log('SIGTERM received. Closing server...');
  server.close(() => process.exit(0));
});

module.exports = app; // exported so Jest test files can import the app
