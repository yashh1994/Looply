import app from './app.js';
import { APP_CONFIG } from './config/constants.js';
import { logger } from './utils/logger.js';

/**
 * Start server
 */
const server = app.listen(APP_CONFIG.PORT, APP_CONFIG.HOST, () => {
  logger.torrent(`${APP_CONFIG.APP_NAME} running on http://${APP_CONFIG.HOST}:${APP_CONFIG.PORT}`);
  logger.info(`Downloads will be saved to: ${app.locals.downloadsDir}`);
  logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
  logger.newLine();
});

/**
 * Graceful shutdown
 */
process.on('SIGTERM', () => {
  logger.warning('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    logger.success('HTTP server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  logger.warning('SIGINT signal received: closing HTTP server');
  server.close(() => {
    logger.success('HTTP server closed');
    process.exit(0);
  });
});

/**
 * Handle uncaught exceptions
 */
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', error.message);
  console.error(error.stack);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', promise);
  logger.error('Reason:', reason);
});

export default server;
