import { MIME_TYPES, FILE_SIZE_UNITS } from '../config/constants.js';

/**
 * Sanitize filename by removing invalid characters
 * @param {string} filename - Original filename
 * @returns {string} Sanitized filename
 */
export function sanitizeFilename(filename) {
  return filename
    .replace(/[<>:"/\\|?*]/g, '_')
    .replace(/\s+/g, '_')
    .replace(/_{2,}/g, '_');
}

/**
 * Format bytes to human-readable format
 * @param {number} bytes - File size in bytes
 * @param {number} decimals - Number of decimal places
 * @returns {string} Formatted file size
 */
export function formatBytes(bytes, decimals = 2) {
  if (bytes === 0) return '0 Bytes';
  
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + FILE_SIZE_UNITS[i];
}

/**
 * Get MIME type based on file extension
 * @param {string} extension - File extension (e.g., '.mp4')
 * @returns {string} MIME type
 */
export function getMimeType(extension) {
  return MIME_TYPES[extension.toLowerCase()] || 'application/octet-stream';
}

/**
 * Generate progress ID for tracking downloads
 * @param {string} infoHash - Torrent info hash
 * @param {number} fileIndex - File index
 * @returns {string} Progress ID
 */
export function generateProgressId(infoHash, fileIndex) {
  return `${infoHash}_${fileIndex}`;
}

/**
 * Parse comma-separated indices string to array of numbers
 * @param {string} indicesString - Comma-separated indices
 * @returns {number[]} Array of valid indices
 */
export function parseIndices(indicesString) {
  if (!indicesString) return [];
  
  return indicesString
    .split(',')
    .map(i => parseInt(i.trim()))
    .filter(i => !isNaN(i) && i >= 0);
}

/**
 * Validate file indices against torrent files
 * @param {number[]} indices - Array of file indices
 * @param {Array} files - Torrent files array
 * @returns {Object} Validation result
 */
export function validateIndices(indices, files) {
  const invalidIndices = indices.filter(idx => !files[idx]);
  
  return {
    isValid: invalidIndices.length === 0,
    invalidIndices,
    maxIndex: files.length - 1
  };
}
