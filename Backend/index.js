/**
 * index.js  –  Cricyy Backend Entry Point (Local Node + Vercel Serverless)
 */

'use strict';

require('dotenv').config();

const express = require('express');
const cors    = require('cors');
const morgan  = require('morgan');
const path    = require('path');

const connectDB = require('./config/db');
const { notFound, errorHandler } = require('./middleware/errorMiddleware');

// ── Route imports ────────────────────────────────────────────────────────────
const playerRoutes      = require('./routes/playerRoutes');
const teamRoutes        = require('./routes/teamRoutes');
const matchRoutes       = require('./routes/matchRoutes');
const inningsRoutes     = require('./routes/inningsRoutes');
const deliveryRoutes    = require('./routes/deliveryRoutes');
const scorecardRoutes   = require('./routes/scorecardRoutes');
const sharedMatchRoutes = require('./routes/sharedMatchRoutes');

// ── Create Express app ────────────────────────────────────────────────────────
const app = express();

// ── Global Middleware ─────────────────────────────────────────────────────────
const corsOptions = {
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Accept', 'Authorization', 'X-Device-Id'],
};
app.use(cors(corsOptions));
app.options('*', cors(corsOptions));

app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: false }));

if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ── Root & Health Check ──────────────────────────────────────────────────────
app.get('/', (req, res) => {
  res.json({
    status: 'ok',
    service: 'Cricyy Backend API',
    endpoints: {
      health: '/api/health',
      sharedMatches: '/api/shared-matches',
      matches: '/api/matches',
      players: '/api/players',
      teams: '/api/teams',
    },
    time: new Date().toISOString(),
  });
});

app.get('/api/health', async (req, res) => {
  let dbConnected = connectDB.isConnected();
  let dbError = null;
  if (!dbConnected && process.env.NODE_ENV !== 'test') {
    try {
      await connectDB();
      dbConnected = connectDB.isConnected();
    } catch (err) {
      dbError = err.message;
    }
  }
  res.json({
    status : 'ok',
    message: 'Cricyy backend is running',
    database: dbConnected ? 'connected' : 'disconnected',
    ...(dbError ? { dbError } : {}),
    time   : new Date().toISOString(),
  });
});

// ── Ensure MongoDB Connection Before API Routes (Serverless-Safe) ────────────
app.use('/api', async (req, res, next) => {
  if (process.env.NODE_ENV === 'test') return next();
  try {
    await connectDB();
    next();
  } catch (err) {
    res.status(503);
    next(new Error(`Database connection failed: ${err.message}`));
  }
});

// ── API Routes ────────────────────────────────────────────────────────────────
app.use('/api/shared-matches', sharedMatchRoutes);
app.use('/api/players',        playerRoutes);
app.use('/api/teams',          teamRoutes);
app.use('/api/matches',        matchRoutes);
app.use('/api/matches',        inningsRoutes);   // /api/matches/:id/innings
app.use('/api/matches',        deliveryRoutes);  // /api/matches/:id/deliveries
app.use('/api/matches',        scorecardRoutes); // /api/matches/:id/scorecard

// ── Error Handling Middleware (must be LAST) ───────────────────────────────────
app.use(notFound);
app.use(errorHandler);

// ── Start Server Only When Run Directly Locally (Not on Vercel Serverless) ───
if (require.main === module && !process.env.VERCEL) {
  const PORT = process.env.PORT || 5000;
  connectDB()
    .catch((err) => {
      console.error('⚠️ Starting HTTP server without active MongoDB:', err.message);
    })
    .finally(() => {
      const server = app.listen(PORT, () => {
        console.log(`\n✅ Cricyy backend running on http://localhost:${PORT}`);
        console.log(`   Environment : ${process.env.NODE_ENV || 'development'}`);
        console.log(`   Health check: http://localhost:${PORT}/api/health\n`);
      });

      process.on('SIGTERM', () => {
        console.log('SIGTERM received. Closing server...');
        server.close(() => process.exit(0));
      });
    });
}

module.exports = app;
