/**
 * Application Constants
 */

export const APP_CONFIG = {
  PORT: process.env.PORT || 3000,
  HOST: '0.0.0.0',
  DOWNLOADS_DIR: 'downloads',
  APP_NAME: 'Torrent Movie Downloader API'
};

export const MIME_TYPES = {
  '.mp4': 'video/mp4',
  '.mkv': 'video/x-matroska',
  '.avi': 'video/x-msvideo',
  '.mov': 'video/quicktime',
  '.wmv': 'video/x-ms-wmv',
  '.flv': 'video/x-flv',
  '.webm': 'video/webm',
  '.mp3': 'audio/mpeg',
  '.wav': 'audio/wav',
  '.flac': 'audio/flac',
  '.aac': 'audio/aac',
  '.ogg': 'audio/ogg',
  '.m4a': 'audio/mp4',
  '.pdf': 'application/pdf',
  '.zip': 'application/zip',
  '.rar': 'application/x-rar-compressed',
  '.7z': 'application/x-7z-compressed',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.gif': 'image/gif',
  '.bmp': 'image/bmp',
  '.svg': 'image/svg+xml',
  '.txt': 'text/plain',
  '.srt': 'text/plain',
  '.sub': 'text/plain',
  '.vtt': 'text/vtt'
};

export const FILE_SIZE_UNITS = ['Bytes', 'KB', 'MB', 'GB', 'TB'];

export const DOWNLOAD_STATUS = {
  DOWNLOADING: 'downloading',
  COMPLETED: 'completed',
  ERROR: 'error',
  ALREADY_EXISTS: 'already_exists'
};
