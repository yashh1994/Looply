import express from 'express';
import cors from 'cors';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { APP_CONFIG } from './config/constants.js';
import routes from './routes/index.js';
import { errorHandler, notFoundHandler } from './middleware/errorHandler.js';
import { logger } from './utils/logger.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Initialize Express app
 */
const app = express();

/**
 * Middleware setup
 */
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

/**
 * Create downloads folder if not exists
 */
const downloadsDir = path.join(__dirname, '..', APP_CONFIG.DOWNLOADS_DIR);
if (!fs.existsSync(downloadsDir)) {
  fs.mkdirSync(downloadsDir, { recursive: true });
  logger.success(`Created downloads directory: ${downloadsDir}`);
}

// Store downloads directory in app locals
app.locals.downloadsDir = downloadsDir;

/**
 * Serve static files (downloaded files)
 */
app.use('/static', express.static(downloadsDir));

/**
 * Mount routes
 */
app.use('/', routes);

/**
 * 404 handler
 */
app.use(notFoundHandler);

/**
 * Error handling middleware
 */
app.use(errorHandler);

export default app;
