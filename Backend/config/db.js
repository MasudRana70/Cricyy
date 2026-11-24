/**
 * config/db.js  –  MongoDB Connection (Local + Serverless / Vercel Cached)
 *
 * Uses Mongoose with a global connection cache so Vercel Serverless Functions
 * reuse warm database connections instead of opening a new connection per request.
 */

'use strict';

const mongoose = require('mongoose');

const globalCache = global._cricyyMongoose || (global._cricyyMongoose = { conn: null, promise: null });

const connectDB = async () => {
  if (globalCache.conn && mongoose.connection.readyState === 1) {
    return globalCache.conn;
  }

  const uri = process.env.MONGODB_URI || process.env.MONGO_URI;
  if (!uri) {
    throw new Error('MONGODB_URI is not defined in environment variables');
  }

  if (!globalCache.promise) {
    globalCache.promise = mongoose
      .connect(uri, {
        bufferCommands: false,
        serverSelectionTimeoutMS: 8000,
        maxPoolSize: 10,
      })
      .then((mongooseInstance) => {
        console.log(`✅ MongoDB connected: ${mongooseInstance.connection.host}`);
        return mongooseInstance;
      })
      .catch((err) => {
        globalCache.promise = null;
        console.error(`❌ MongoDB connection error: ${err.message}`);
        throw err;
      });
  }

  globalCache.conn = await globalCache.promise;
  return globalCache.conn;
};

connectDB.isConnected = () => mongoose.connection.readyState === 1;

module.exports = connectDB;
