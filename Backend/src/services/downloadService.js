import fs from 'fs';
import path from 'path';
import { 
  sanitizeFilename, 
  formatBytes, 
  generateProgressId,
  validateIndices 
} from '../utils/fileHelpers.js';
import { DOWNLOAD_STATUS } from '../config/constants.js';
import { logger } from '../utils/logger.js';
import torrentService from './torrentService.js';

class DownloadService {
  /**
   * Download a single file from torrent
   * @param {Object} file - Torrent file object
   * @param {number} fileIndex - File index
   * @param {string} torrentHash - Torrent info hash
   * @param {string} downloadsDir - Downloads directory
   * @returns {Promise<Object>} Download result
   */
  async downloadFile(file, fileIndex, torrentHash, downloadsDir) {
    return new Promise((resolve, reject) => {
      const sanitizedFileName = sanitizeFilename(file.name);
      const outputPath = path.join(downloadsDir, sanitizedFileName);

      // Check if file already exists
      if (fs.existsSync(outputPath)) {
        logger.success(`File already exists: ${sanitizedFileName}`);
        return resolve({
          index: fileIndex,
          filename: sanitizedFileName,
          status: DOWNLOAD_STATUS.ALREADY_EXISTS,
          url: `/static/${sanitizedFileName}`,
          size: file.length,
          sizeFormatted: formatBytes(file.length)
        });
      }

      const progressId = generateProgressId(torrentHash, fileIndex);
      const totalSize = file.length;
      let downloaded = 0;

      // Initialize progress tracking
      torrentService.setProgress(progressId, {
        index: fileIndex,
        filename: file.name,
        downloaded: 0,
        total: totalSize,
        percentage: 0,
        status: DOWNLOAD_STATUS.DOWNLOADING
      });

      const readStream = file.createReadStream();
      const writeStream = fs.createWriteStream(outputPath);

      // Handle data chunks
      readStream.on('data', (chunk) => {
        downloaded += chunk.length;
        const percentage = ((downloaded / totalSize) * 100).toFixed(2);
        
        // Update progress
        torrentService.setProgress(progressId, {
          index: fileIndex,
          filename: file.name,
          downloaded,
          total: totalSize,
          percentage: parseFloat(percentage),
          status: DOWNLOAD_STATUS.DOWNLOADING
        });

        // Log progress
        logger.progress(
          `📥 Downloading [${file.name}]: ${formatBytes(downloaded)} / ${formatBytes(totalSize)} (${percentage}%)`
        );
      });

      // Handle read errors
      readStream.on('error', (err) => {
        logger.error(`Read error for ${file.name}:`, err.message);
        torrentService.setProgress(progressId, { 
          index: fileIndex,
          filename: file.name,
          status: DOWNLOAD_STATUS.ERROR, 
          error: err.message 
        });
        reject({ index: fileIndex, filename: file.name, error: err.message });
      });

      // Handle write errors
      writeStream.on('error', (err) => {
        logger.error(`Write error for ${file.name}:`, err.message);
        torrentService.setProgress(progressId, { 
          index: fileIndex,
          filename: file.name,
          status: DOWNLOAD_STATUS.ERROR, 
          error: err.message 
        });
        reject({ index: fileIndex, filename: file.name, error: err.message });
      });

      // Handle completion
      writeStream.on('finish', () => {
        logger.newLine();
        logger.success(`Download completed: ${file.name}`);
        
        torrentService.setProgress(progressId, {
          index: fileIndex,
          filename: file.name,
          downloaded: totalSize,
          total: totalSize,
          percentage: 100,
          status: DOWNLOAD_STATUS.COMPLETED
        });

        resolve({
          index: fileIndex,
          filename: sanitizedFileName,
          status: DOWNLOAD_STATUS.COMPLETED,
          url: `/static/${sanitizedFileName}`,
          size: totalSize,
          sizeFormatted: formatBytes(totalSize),
          progressId
        });
      });

      readStream.pipe(writeStream);
    });
  }

  /**
   * Download multiple files by indices
   * @param {Object} torrent - Torrent object
   * @param {number[]} fileIndices - Array of file indices
   * @param {string} downloadsDir - Downloads directory
   * @returns {Promise<Object>} Download results
   */
  async downloadMultipleFiles(torrent, fileIndices, downloadsDir) {
    // Validate indices
    const validation = validateIndices(fileIndices, torrent.files);
    if (!validation.isValid) {
      throw {
        statusCode: 400,
        error: 'Invalid file indices',
        invalidIndices: validation.invalidIndices,
        maxIndex: validation.maxIndex
      };
    }

    // Create download tasks
    const downloadTasks = fileIndices.map(fileIndex => 
      this.downloadFile(
        torrent.files[fileIndex], 
        fileIndex, 
        torrent.infoHash, 
        downloadsDir
      )
    );

    // Execute downloads
    const results = await Promise.allSettled(downloadTasks);
    
    const successful = results
      .filter(r => r.status === 'fulfilled')
      .map(r => r.value);
    
    const failed = results
      .filter(r => r.status === 'rejected')
      .map(r => r.reason);

    logger.newLine();
    logger.info(`Download Summary: ${successful.length} successful, ${failed.length} failed`);

    return {
      successful,
      failed,
      total: fileIndices.length
    };
  }

  /**
   * Download all files from torrent
   * @param {Object} torrent - Torrent object
   * @param {string} downloadsDir - Downloads directory
   * @returns {Promise<Object>} Download results
   */
  async downloadAllFiles(torrent, downloadsDir) {
    const allIndices = torrent.files.map((_, index) => index);
    return this.downloadMultipleFiles(torrent, allIndices, downloadsDir);
  }
}

// Singleton instance
export default new DownloadService();
