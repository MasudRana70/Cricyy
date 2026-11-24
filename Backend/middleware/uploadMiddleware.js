/**
 * middleware/uploadMiddleware.js  –  File Upload Configuration
 *
 * Uses Multer to handle multipart/form-data file uploads.
 * Uploaded files are stored in the /uploads directory.
 */

'use strict';

const multer = require('multer');
const path   = require('path');

const MAX_SIZE_BYTES = (parseInt(process.env.MAX_FILE_SIZE_MB || '5')) * 1024 * 1024;

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, '..', process.env.UPLOAD_DIR || 'uploads'));
  },
  filename: (req, file, cb) => {
    // Generate a unique filename: timestamp + original extension
    const ext      = path.extname(file.originalname).toLowerCase();
    const filename = `${Date.now()}-${Math.random().toString(36).slice(2)}${ext}`;
    cb(null, filename);
  },
});

const fileFilter = (req, file, cb) => {
  const allowed = ['.jpg', '.jpeg', '.png', '.webp'];
  const ext     = path.extname(file.originalname).toLowerCase();
  if (allowed.includes(ext)) {
    cb(null, true);
  } else {
    cb(new Error('Only jpg, jpeg, png and webp files are allowed'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: MAX_SIZE_BYTES },
});

module.exports = upload;
