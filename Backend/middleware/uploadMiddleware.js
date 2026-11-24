/**
 * middleware/uploadMiddleware.js  –  File Upload Configuration
 *
 * Uses Multer to handle multipart/form-data file uploads.
 * Automatically writes to /tmp/uploads when running on Vercel serverless (read-only fs).
 */

'use strict';

const fs     = require('fs');
const path   = require('path');
const multer = require('multer');

const MAX_SIZE_BYTES = (parseInt(process.env.MAX_FILE_SIZE_MB || '5', 10)) * 1024 * 1024;

const getUploadDir = () => {
  const dir = process.env.VERCEL
    ? path.join('/tmp', 'cricyy-uploads')
    : path.join(__dirname, '..', process.env.UPLOAD_DIR || 'uploads');
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  return dir;
};

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, getUploadDir());
  },
  filename: (req, file, cb) => {
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
