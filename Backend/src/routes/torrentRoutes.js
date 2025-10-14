import express from 'express';
import torrentController from '../controllers/torrentController.js';

const router = express.Router();

/**
 * @route   GET /api/torrent-info
 * @desc    Get torrent metadata and file list
 * @access  Public
 */
router.get('/torrent-info', torrentController.getTorrentInfo);

/**
 * @route   GET /api/download
 * @desc    Download specific files by indices
 * @access  Public
 */
router.get('/download', torrentController.downloadFiles);

/**
 * @route   GET /api/download-all
 * @desc    Download all files from torrent
 * @access  Public
 */
router.get('/download-all', torrentController.downloadAllFiles);

/**
 * @route   GET /api/progress
 * @desc    Get download progress
 * @access  Public
 */
router.get('/progress', torrentController.getProgress);

/**
 * @route   GET /api/list
 * @desc    List all active torrents
 * @access  Public
 */
router.get('/list', torrentController.listTorrents);

/**
 * @route   GET /api/cancel
 * @desc    Cancel/Remove a torrent download
 * @access  Public
 */
router.get('/cancel', torrentController.cancelTorrent);

export default router;
