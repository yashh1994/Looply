import WebTorrent from 'webtorrent';
import path from 'path';
import { 
  sanitizeFilename, 
  formatBytes, 
  getMimeType, 
  generateProgressId 
} from '../utils/fileHelpers.js';
import { logger } from '../utils/logger.js';

class TorrentService {
  constructor() {
    this.client = new WebTorrent();
    this.torrentsCache = new Map();
    this.downloadProgress = new Map();
  }

  /**
   * Get or add torrent
   * @param {string} url - Magnet link or torrent URL
   * @param {string} downloadsDir - Downloads directory path
   * @returns {Promise<Object>} Torrent object
   */
  async getTorrent(url, downloadsDir) {
    return new Promise((resolve, reject) => {
      let torrent = this.client.get(url);

      if (torrent) {
        if (torrent.ready) {
          resolve(torrent);
        } else {
          torrent.once('ready', () => resolve(torrent));
        }
      } else {
        logger.info('Adding new torrent...');
        this.client.add(url, { path: downloadsDir }, (torrent) => {
          torrent.once('ready', () => {
            logger.success('Torrent ready!');
            resolve(torrent);
          });
          
          torrent.on('error', (err) => {
            logger.error('Torrent error:', err.message);
            reject(err);
          });
        });
      }
    });
  }

  /**
   * Get torrent metadata
   * @param {string} url - Magnet link or torrent URL
   * @param {string} downloadsDir - Downloads directory path
   * @returns {Promise<Object>} Torrent info
   */
  async getTorrentInfo(url, downloadsDir) {
    // Check cache first
    if (this.torrentsCache.has(url)) {
      logger.info('Using cached torrent info');
      return this.torrentsCache.get(url);
    }

    const torrent = await this.getTorrent(url, downloadsDir);

    const torrentInfo = {
      name: torrent.name,
      infoHash: torrent.infoHash,
      totalSize: torrent.length,
      totalSizeFormatted: formatBytes(torrent.length),
      fileCount: torrent.files.length,
      files: torrent.files.map((file, index) => {
        const extension = path.extname(file.name);
        return {
          index,
          name: file.name,
          nameWithoutExtension: path.basename(file.name, extension),
          extension: extension,
          size: file.length,
          sizeFormatted: formatBytes(file.length),
          path: file.path,
          mimeType: getMimeType(extension)
        };
      })
    };

    // Cache the torrent info
    this.torrentsCache.set(url, torrentInfo);
    
    logger.success(`Torrent: ${torrent.name}`);
    logger.info(`Files: ${torrent.files.length}`);

    return torrentInfo;
  }

  /**
   * Get all active torrents
   * @returns {Array} List of active torrents
   */
  getActiveTorrents() {
    return this.client.torrents.map(torrent => ({
      infoHash: torrent.infoHash,
      name: torrent.name,
      progress: (torrent.progress * 100).toFixed(2) + '%',
      downloadSpeed: formatBytes(torrent.downloadSpeed) + '/s',
      uploadSpeed: formatBytes(torrent.uploadSpeed) + '/s',
      numPeers: torrent.numPeers,
      files: torrent.files.length,
      size: formatBytes(torrent.length)
    }));
  }

  /**
   * Cancel/Remove a torrent
   * @param {string} torrentId - Torrent info hash
   * @returns {Promise<Object>} Result
   */
  async cancelTorrent(torrentId) {
    return new Promise((resolve, reject) => {
      const torrent = this.client.torrents.find(t => t.infoHash === torrentId);
      
      if (!torrent) {
        return reject(new Error('Torrent not found'));
      }

      const torrentName = torrent.name;
      
      torrent.destroy(() => {
        logger.warning(`Torrent removed: ${torrentName}`);
        
        // Clean up progress entries
        const keysToDelete = [];
        this.downloadProgress.forEach((value, key) => {
          if (key.startsWith(torrentId)) {
            keysToDelete.push(key);
          }
        });
        
        keysToDelete.forEach(key => this.downloadProgress.delete(key));
        
        resolve({
          message: 'Torrent cancelled and removed',
          torrentName,
          infoHash: torrentId
        });
      });
    });
  }

  /**
   * Get download progress
   * @param {string} progressId - Progress ID (optional)
   * @returns {Object} Progress data
   */
  getProgress(progressId = null) {
    if (progressId) {
      return this.downloadProgress.get(progressId) || null;
    }

    const allProgress = {};
    this.downloadProgress.forEach((value, key) => {
      allProgress[key] = value;
    });

    return allProgress;
  }

  /**
   * Set download progress
   * @param {string} progressId - Progress ID
   * @param {Object} progressData - Progress data
   */
  setProgress(progressId, progressData) {
    this.downloadProgress.set(progressId, progressData);
  }

  /**
   * Get WebTorrent client
   * @returns {WebTorrent} WebTorrent client instance
   */
  getClient() {
    return this.client;
  }
}

// Singleton instance
export default new TorrentService();
