import torrentService from '../services/torrentService.js';
import downloadService from '../services/downloadService.js';
import { parseIndices, formatBytes } from '../utils/fileHelpers.js';
import { logger } from '../utils/logger.js';

class TorrentController {
  /**
   * Get torrent information
   * @param {Object} req - Express request
   * @param {Object} res - Express response
   */
  async getTorrentInfo(req, res) {
    try {
      const { url } = req.query;
      
      if (!url) {
        return res.status(400).json({ 
          error: 'Missing url parameter (magnet link or torrent URL)' 
        });
      }

      logger.info('Request for torrent info');
      
      const torrentInfo = await torrentService.getTorrentInfo(
        url, 
        req.app.locals.downloadsDir
      );
      
      res.json(torrentInfo);
    } catch (error) {
      logger.error('Error getting torrent info:', error.message);
      res.status(500).json({ 
        error: 'Failed to get torrent information',
        message: error.message 
      });
    }
  }

  /**
   * Download specific files by indices
   * @param {Object} req - Express request
   * @param {Object} res - Express response
   */
  async downloadFiles(req, res) {
    try {
      const { url, indices } = req.query;
      
      if (!url) {
        return res.status(400).json({ 
          error: 'Missing url parameter (magnet link or torrent URL)' 
        });
      }

      if (!indices) {
        return res.status(400).json({ 
          error: 'Missing indices parameter (comma-separated file indices, e.g., "0,1,2")' 
        });
      }

      const fileIndices = parseIndices(indices);
      
      if (fileIndices.length === 0) {
        return res.status(400).json({ 
          error: 'Invalid indices format. Use comma-separated numbers (e.g., "0,1,2")' 
        });
      }

      logger.download(`Download request - Indices: ${indices}`);

      const torrent = await torrentService.getTorrent(
        url, 
        req.app.locals.downloadsDir
      );

      // Send immediate response
      res.json({
        message: 'Download started',
        torrentName: torrent.name,
        requestedFiles: fileIndices.length,
        files: fileIndices.map(idx => ({
          index: idx,
          name: torrent.files[idx].name,
          size: torrent.files[idx].length,
          sizeFormatted: formatBytes(torrent.files[idx].length),
          progressId: `${torrent.infoHash}_${idx}`
        }))
      });

      // Start downloads in background
      downloadService.downloadMultipleFiles(
        torrent, 
        fileIndices, 
        req.app.locals.downloadsDir
      ).catch(error => {
        if (error.statusCode) {
          logger.error('Download validation error:', error.error);
        } else {
          logger.error('Download error:', error.message);
        }
      });

    } catch (error) {
      logger.error('Error starting download:', error.message);
      res.status(500).json({ 
        error: 'Failed to start download',
        message: error.message 
      });
    }
  }

  /**
   * Download all files from torrent
   * @param {Object} req - Express request
   * @param {Object} res - Express response
   */
  async downloadAllFiles(req, res) {
    try {
      const { url } = req.query;
      
      if (!url) {
        return res.status(400).json({ 
          error: 'Missing url parameter (magnet link or torrent URL)' 
        });
      }

      logger.download('Download all files request');

      const torrent = await torrentService.getTorrent(
        url, 
        req.app.locals.downloadsDir
      );

      // Send immediate response
      res.json({ 
        message: 'Batch download started', 
        torrentName: torrent.name,
        fileCount: torrent.files.length 
      });

      // Start downloads in background
      const results = await downloadService.downloadAllFiles(
        torrent, 
        req.app.locals.downloadsDir
      );

      logger.info(`Batch download completed: ${results.successful.length}/${results.total} files`);

    } catch (error) {
      logger.error('Error starting batch download:', error.message);
      res.status(500).json({ 
        error: 'Failed to start batch download',
        message: error.message 
      });
    }
  }

  /**
   * Get download progress
   * @param {Object} req - Express request
   * @param {Object} res - Express response
   */
  getProgress(req, res) {
    try {
      const { torrent_id } = req.query;
      
      const progress = torrentService.getProgress(torrent_id);
      
      if (torrent_id && !progress) {
        return res.status(404).json({ error: 'Progress ID not found' });
      }

      res.json(progress);
    } catch (error) {
      logger.error('Error getting progress:', error.message);
      res.status(500).json({ 
        error: 'Failed to get progress',
        message: error.message 
      });
    }
  }

  /**
   * List all active torrents
   * @param {Object} req - Express request
   * @param {Object} res - Express response
   */
  listTorrents(req, res) {
    try {
      const activeTorrents = torrentService.getActiveTorrents();
      
      res.json({
        totalTorrents: activeTorrents.length,
        torrents: activeTorrents
      });
    } catch (error) {
      logger.error('Error listing torrents:', error.message);
      res.status(500).json({ 
        error: 'Failed to list torrents',
        message: error.message 
      });
    }
  }

  /**
   * Cancel/Remove a torrent
   * @param {Object} req - Express request
   * @param {Object} res - Express response
   */
  async cancelTorrent(req, res) {
    try {
      const { torrent_id } = req.query;
      
      if (!torrent_id) {
        return res.status(400).json({ error: 'Missing torrent_id parameter' });
      }

      const result = await torrentService.cancelTorrent(torrent_id);
      res.json(result);
    } catch (error) {
      logger.error('Error cancelling torrent:', error.message);
      
      if (error.message === 'Torrent not found') {
        return res.status(404).json({ error: error.message });
      }
      
      res.status(500).json({ 
        error: 'Failed to cancel torrent',
        message: error.message 
      });
    }
  }
}

export default new TorrentController();
