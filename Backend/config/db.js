/**
 * config/db.js  –  MongoDB Connection
 *
 * Uses Mongoose to connect to MongoDB.
 * The connection string comes from the MONGODB_URI environment variable.
 *
 * Why a separate file?
 *   Keeping the DB connection in its own module means you can import it
 *   from index.js and from test files without duplicating code.
 */

'use strict';

const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const uri = process.env.MONGODB_URI;

    if (!uri) {
      throw new Error('MONGODB_URI is not defined in your .env file');
    }

    const conn = await mongoose.connect(uri, {
      // These options silence deprecation warnings in Mongoose 8+
      // (most are the new defaults, but being explicit is clearer for learners)
    });

    console.log(`✅ MongoDB connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`❌ MongoDB connection error: ${error.message}`);
    // Exit the process with failure code so the problem is immediately visible
    process.exit(1);
  }
};

module.exports = connectDB;
