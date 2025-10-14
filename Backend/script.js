import express from 'express';
import WebTorrent from 'webtorrent';
import cors from 'cors';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const client = new WebTorrent();
app.use(cors());
app.use(express.json());

// Create downloads folder if not exists
const downloadsDir = path.join(__dirname, 'downloads');
if (!fs.existsSync(downloadsDir)) fs.mkdirSync(downloadsDir);

// Serve static files
app.use('/static', express.static(downloadsDir));

// Cache and progress tracking
const torrents = new Map();
const downloadProgress = new Map();

// Utility function to sanitize filenames
function sanitizeFilename(filename) {
  return filename.replace(/[<>:"/\\|?*]/g, '_').replace(/\s+/g, '_');
}

// Root route
app.get('/', (req, res) => {
  res.json({
    message: "🎬 Torrent Movie Downloader API",
    endpoints: {
      "/": "This help page",
      "/torrent-info?url=<magnet_or_torrent_url>": "Get all files from torrent with details (name, extension, size, index)",
      "/download?url=<magnet_or_torrent_url>&indices=<comma_separated_indices>": "Download specific files by indices",
      "/download-all?url=<magnet_or_torrent_url>": "Download all files from torrent",
      "/progress?torrent_id=<id>": "Get download progress for specific download",
      "/progress": "Get all download progress",
      "/list": "List all active torrents",
      "/cancel?torrent_id=<id>": "Cancel a download"
    }
  });
});

// Get torrent metadata: files, size, extension, etc.
app.get('/torrent-info', (req, res) => {
  console.log("📋 Request for torrent info");
  const { url } = req.query;
  
  if (!url) {
    return res.status(400).json({ error: 'Missing url parameter (magnet link or torrent URL)' });
  }

  // Check if torrent is already cached
  if (torrents.has(url)) {
    console.log('✅ Using cached torrent info');
    return res.json(torrents.get(url));
  }

  // Add torrent to get metadata
  client.add(url, { path: downloadsDir }, (torrent) => {
    const torrentInfo = {
      name: torrent.name,
      infoHash: torrent.infoHash,
      totalSize: torrent.length,
      totalSizeFormatted: (torrent.length / (1024 * 1024 * 1024)).toFixed(2) + ' GB',
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
    torrents.set(url, torrentInfo);
    
    console.log(`✅ Torrent added: ${torrent.name}`);
    console.log(`📁 Files: ${torrent.files.length}`);
    
    res.json(torrentInfo);
  });
});

// Helper function to format bytes
function formatBytes(bytes) {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// Helper function to get MIME type
function getMimeType(extension) {
  const mimeTypes = {
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
    '.pdf': 'application/pdf',
    '.zip': 'application/zip',
    '.rar': 'application/x-rar-compressed',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.gif': 'image/gif',
    '.txt': 'text/plain',
    '.srt': 'text/plain',
    '.sub': 'text/plain'
  };
  return mimeTypes[extension.toLowerCase()] || 'application/octet-stream';
}

// Download specific files by indices (comma-separated)
app.get('/download', (req, res) => {
  const { url, indices } = req.query;
  console.log(`📥 Download request - Indices: ${indices}`);
  
  if (!url) {
    return res.status(400).json({ error: 'Missing url parameter (magnet link or torrent URL)' });
  }

  if (!indices) {
    return res.status(400).json({ error: 'Missing indices parameter (comma-separated file indices, e.g., "0,1,2")' });
  }

  // Parse indices
  const fileIndices = indices.split(',').map(i => parseInt(i.trim())).filter(i => !isNaN(i));
  
  if (fileIndices.length === 0) {
    return res.status(400).json({ error: 'Invalid indices format. Use comma-separated numbers (e.g., "0,1,2")' });
  }

  let torrent = client.get(url);

  const handleDownload = (torrent) => {
    // Validate all indices
    const invalidIndices = fileIndices.filter(idx => !torrent.files[idx]);
    if (invalidIndices.length > 0) {
      return res.status(400).json({ 
        error: 'Invalid file indices', 
        invalidIndices,
        maxIndex: torrent.files.length - 1
      });
    }

    // Prepare download tasks
    const downloadTasks = fileIndices.map(fileIndex => {
      return new Promise((resolve, reject) => {
        const file = torrent.files[fileIndex];
        const sanitizedFileName = sanitizeFilename(file.name);
        const outputPath = path.join(downloadsDir, sanitizedFileName);

        // Check if file already exists
        if (fs.existsSync(outputPath)) {
          console.log(`✅ File already exists: ${sanitizedFileName}`);
          return resolve({
            index: fileIndex,
            filename: sanitizedFileName,
            status: 'already_exists',
            url: `/static/${sanitizedFileName}`,
            size: file.length,
            sizeFormatted: formatBytes(file.length)
          });
        }

        const progressId = `${torrent.infoHash}_${fileIndex}`;
        const totalSize = file.length;
        let downloaded = 0;

        // Initialize progress tracking
        downloadProgress.set(progressId, {
          index: fileIndex,
          filename: file.name,
          downloaded: 0,
          total: totalSize,
          percentage: 0,
          status: 'downloading'
        });

        const readStream = file.createReadStream();
        const writeStream = fs.createWriteStream(outputPath);

        readStream.on('data', (chunk) => {
          downloaded += chunk.length;
          const percentage = ((downloaded / totalSize) * 100).toFixed(2);
          
          // Update progress
          downloadProgress.set(progressId, {
            index: fileIndex,
            filename: file.name,
            downloaded,
            total: totalSize,
            percentage: parseFloat(percentage),
            status: 'downloading'
          });

          // Log progress to console
          process.stdout.write(`\r📥 Downloading [${file.name}]: ${formatBytes(downloaded)} / ${formatBytes(totalSize)} (${percentage}%)`);
        });

        readStream.on('error', (err) => {
          console.error(`\n❌ Read error for ${file.name}:`, err);
          downloadProgress.set(progressId, { 
            index: fileIndex,
            filename: file.name,
            status: 'error', 
            error: err.message 
          });
          reject({ index: fileIndex, filename: file.name, error: err.message });
        });

        writeStream.on('error', (err) => {
          console.error(`\n❌ Write error for ${file.name}:`, err);
          downloadProgress.set(progressId, { 
            index: fileIndex,
            filename: file.name,
            status: 'error', 
            error: err.message 
          });
          reject({ index: fileIndex, filename: file.name, error: err.message });
        });

        writeStream.on('finish', () => {
          console.log(`\n✅ Download completed: ${file.name}`);
          
          downloadProgress.set(progressId, {
            index: fileIndex,
            filename: file.name,
            downloaded: totalSize,
            total: totalSize,
            percentage: 100,
            status: 'completed'
          });

          resolve({
            index: fileIndex,
            filename: sanitizedFileName,
            status: 'completed',
            url: `/static/${sanitizedFileName}`,
            size: totalSize,
            sizeFormatted: formatBytes(totalSize),
            progressId
          });
        });

        readStream.pipe(writeStream);
      });
    });

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

    // Execute downloads in background
    Promise.allSettled(downloadTasks).then(results => {
      const successful = results.filter(r => r.status === 'fulfilled').map(r => r.value);
      const failed = results.filter(r => r.status === 'rejected').map(r => r.reason);

      console.log(`\n📊 Download Summary: ${successful.length} successful, ${failed.length} failed`);
    });
  };

  if (!torrent) {
    // Add torrent if not already added
    console.log('🔄 Adding new torrent...');
    client.add(url, { path: downloadsDir }, (torrent) => {
      torrent.on('ready', () => {
        console.log('✅ Torrent ready!');
        handleDownload(torrent);
      });
    });
  } else {
    if (torrent.ready) {
      handleDownload(torrent);
    } else {
      torrent.on('ready', () => handleDownload(torrent));
    }
  }
});

// Download all files from torrent
app.get('/download-all', (req, res) => {
  const { url } = req.query;
  console.log("📥 Download all files request");
  
  if (!url) {
    return res.status(400).json({ error: 'Missing url parameter (magnet link or torrent URL)' });
  }

  let torrent = client.get(url);

  const handleDownloadAll = (torrent) => {
    const downloadPromises = torrent.files.map((file, index) => {
      return new Promise((resolve, reject) => {
        const sanitizedFileName = sanitizeFilename(file.name);
        const outputPath = path.join(downloadsDir, sanitizedFileName);

        // Skip if file already exists
        if (fs.existsSync(outputPath)) {
          console.log(`⏭️ Skipping existing file: ${sanitizedFileName}`);
          return resolve({
            index,
            filename: sanitizedFileName,
            status: 'already_exists',
            url: `/static/${sanitizedFileName}`,
            size: file.length,
            sizeFormatted: formatBytes(file.length)
          });
        }

        const progressId = `${torrent.infoHash}_${index}`;
        const totalSize = file.length;
        let downloaded = 0;

        downloadProgress.set(progressId, {
          index,
          filename: file.name,
          downloaded: 0,
          total: totalSize,
          percentage: 0,
          status: 'downloading'
        });

        const readStream = file.createReadStream();
        const writeStream = fs.createWriteStream(outputPath);

        readStream.on('data', (chunk) => {
          downloaded += chunk.length;
          const percentage = ((downloaded / totalSize) * 100).toFixed(2);
          
          downloadProgress.set(progressId, {
            index,
            filename: file.name,
            downloaded,
            total: totalSize,
            percentage: parseFloat(percentage),
            status: 'downloading'
          });
        });

        readStream.on('error', (err) => {
          downloadProgress.set(progressId, {
            index,
            filename: file.name,
            status: 'error',
            error: err.message
          });
          reject(err);
        });

        writeStream.on('error', (err) => {
          downloadProgress.set(progressId, {
            index,
            filename: file.name,
            status: 'error',
            error: err.message
          });
          reject(err);
        });

        writeStream.on('finish', () => {
          downloadProgress.set(progressId, {
            index,
            filename: file.name,
            downloaded: totalSize,
            total: totalSize,
            percentage: 100,
            status: 'completed'
          });

          resolve({
            index,
            filename: sanitizedFileName,
            status: 'completed',
            url: `/static/${sanitizedFileName}`,
            size: totalSize,
            sizeFormatted: formatBytes(totalSize)
          });
        });

        readStream.pipe(writeStream);
      });
    });

    Promise.allSettled(downloadPromises).then(results => {
      const successful = results.filter(r => r.status === 'fulfilled').map(r => r.value);
      const failed = results.filter(r => r.status === 'rejected').map(r => r.reason);

      res.json({
        message: 'Batch download completed',
        successful,
        failed: failed.length,
        total: torrent.files.length
      });
    });
  };

  if (!torrent) {
    console.log('🔄 Adding new torrent...');
    client.add(url, { path: downloadsDir }, (torrent) => {
      torrent.on('ready', () => {
        console.log('✅ Torrent ready!');
        res.json({ 
          message: 'Batch download started', 
          torrentName: torrent.name,
          fileCount: torrent.files.length 
        });
        handleDownloadAll(torrent);
      });
    });
  } else {
    if (torrent.ready) {
      res.json({ 
        message: 'Batch download started', 
        torrentName: torrent.name,
        fileCount: torrent.files.length 
      });
      handleDownloadAll(torrent);
    } else {
      torrent.on('ready', () => {
        res.json({ 
          message: 'Batch download started', 
          torrentName: torrent.name,
          fileCount: torrent.files.length 
        });
        handleDownloadAll(torrent);
      });
    }
  }
});

// Get download progress
app.get('/progress', (req, res) => {
  const { torrent_id } = req.query;
  
  if (torrent_id) {
    const progress = downloadProgress.get(torrent_id);
    if (!progress) {
      return res.status(404).json({ error: 'Progress ID not found' });
    }
    return res.json(progress);
  }

  // Return all progress if no specific ID
  const allProgress = {};
  downloadProgress.forEach((value, key) => {
    allProgress[key] = value;
  });

  res.json(allProgress);
});

// List all active torrents
app.get('/list', (req, res) => {
  const activeTorrents = client.torrents.map(torrent => ({
    infoHash: torrent.infoHash,
    name: torrent.name,
    progress: (torrent.progress * 100).toFixed(2) + '%',
    downloadSpeed: formatBytes(torrent.downloadSpeed) + '/s',
    uploadSpeed: formatBytes(torrent.uploadSpeed) + '/s',
    numPeers: torrent.numPeers,
    files: torrent.files.length,
    size: formatBytes(torrent.length)
  }));

  res.json({
    totalTorrents: activeTorrents.length,
    torrents: activeTorrents
  });
});

// Cancel/Remove a torrent download
app.get('/cancel', (req, res) => {
  const { torrent_id } = req.query;
  
  if (!torrent_id) {
    return res.status(400).json({ error: 'Missing torrent_id parameter' });
  }

  const torrent = client.torrents.find(t => t.infoHash === torrent_id);
  
  if (!torrent) {
    return res.status(404).json({ error: 'Torrent not found' });
  }

  const torrentName = torrent.name;
  
  torrent.destroy(() => {
    console.log(`🗑️ Torrent removed: ${torrentName}`);
    
    // Clean up progress entries for this torrent
    const keysToDelete = [];
    downloadProgress.forEach((value, key) => {
      if (key.startsWith(torrent_id)) {
        keysToDelete.push(key);
      }
    });
    
    keysToDelete.forEach(key => downloadProgress.delete(key));
    
    res.json({
      message: 'Torrent cancelled and removed',
      torrentName,
      infoHash: torrent_id
    });
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🎬 Torrent Movie Downloader Server running on http://0.0.0.0:${PORT}`);
  console.log(`📁 Downloads will be saved to: ${downloadsDir}`);
});

