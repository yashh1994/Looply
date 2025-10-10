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
      "/torrent-info?magnet=<magnet_link>": "Get torrent metadata",
      "/download?magnet=<magnet_link>&index=<file_index>": "Download specific file",
      "/download-all?magnet=<magnet_link>": "Download all files",
      "/progress?torrent_id=<id>": "Get download progress",
      "/list": "List all active torrents"
    }
  });
});

// Get torrent metadata: files, size, etc.
app.get('/torrent-info', (req, res) => {
  console.log("Request for torrent info");
  const { magnet } = req.query;
  
  if (!magnet) {
    return res.status(400).json({ error: 'Missing magnet link parameter' });
  }

  // Check if torrent is already cached
  if (torrents.has(magnet)) {
    console.log('Using cached torrent info');
    return res.json(torrents.get(magnet));
  }

  // Add torrent to get metadata
  client.add(magnet, { path: downloadsDir }, (torrent) => {
    const torrentInfo = {
      name: torrent.name,
      infoHash: torrent.infoHash,
      size: torrent.length,
      files: torrent.files.map((file, index) => ({
        index,
        name: file.name,
        size: file.length,
        path: file.path,
        type: path.extname(file.name).toLowerCase()
      }))
    };

    // Cache the torrent info
    torrents.set(magnet, torrentInfo);
    
    console.log(`Torrent added: ${torrent.name}`);
    console.log(`Files: ${torrent.files.length}`);
    
    res.json(torrentInfo);
  });
});

// Download specific file by index
app.get('/download', (req, res) => {
  const { magnet, index } = req.query;
  console.log(`Download request - Index: ${index}`);
  
  if (!magnet || index === undefined) {
    return res.status(400).json({ error: 'Missing magnet link or file index' });
  }

  const fileIndex = parseInt(index);
  let torrent = client.get(magnet);

  const handleDownload = (torrent) => {
    if (!torrent.files || !torrent.files[fileIndex]) {
      return res.status(400).json({ error: 'Invalid file index' });
    }

    const file = torrent.files[fileIndex];
    const sanitizedFileName = sanitizeFilename(file.name);
    const outputPath = path.join(downloadsDir, sanitizedFileName);

    // Check if file already exists
    if (fs.existsSync(outputPath)) {
      console.log(`File already exists: ${sanitizedFileName}`);
      return res.json({ 
        message: 'File already downloaded',
        url: `/static/${sanitizedFileName}`,
        filename: sanitizedFileName,
        size: file.length
      });
    }

    const progressId = `${torrent.infoHash}_${fileIndex}`;
    const totalSize = file.length;
    let downloaded = 0;

    // Initialize progress tracking
    downloadProgress.set(progressId, {
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
        filename: file.name,
        downloaded,
        total: totalSize,
        percentage: parseFloat(percentage),
        status: 'downloading'
      });

      // Log progress to console
      process.stdout.write(`\rDownloading [${file.name}]: ${(downloaded / 1e6).toFixed(1)}MB / ${(totalSize / 1e6).toFixed(1)}MB (${percentage}%)`);
    });

    readStream.on('error', (err) => {
      console.error('\nRead error:', err);
      downloadProgress.set(progressId, { status: 'error', error: err.message });
      if (!res.headersSent) {
        res.status(500).json({ error: 'Error reading torrent file' });
      }
    });

    writeStream.on('error', (err) => {
      console.error('\nWrite error:', err);
      downloadProgress.set(progressId, { status: 'error', error: err.message });
      if (!res.headersSent) {
        res.status(500).json({ error: 'Error writing file to disk' });
      }
    });

    writeStream.on('finish', () => {
      console.log(`\nDownload completed: ${file.name}`);
      
      downloadProgress.set(progressId, {
        filename: file.name,
        downloaded: totalSize,
        total: totalSize,
        percentage: 100,
        status: 'completed'
      });

      if (!res.headersSent) {
        res.json({
          message: 'Download completed',
          filename: sanitizedFileName,
          url: `/static/${sanitizedFileName}`,
          size: totalSize
        });
      }
    });

    readStream.pipe(writeStream);

    // Return initial response with progress ID
    if (!res.headersSent) {
      res.json({
        message: 'Download started',
        progressId,
        filename: file.name,
        size: totalSize
      });
    }
  };

  if (!torrent) {
    // Add torrent if not already added
    client.add(magnet, { path: downloadsDir }, (torrent) => {
      torrent.on('ready', () => handleDownload(torrent));
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
  const { magnet } = req.query;
  console.log("Download all files request");
  
  if (!magnet) {
    return res.status(400).json({ error: 'Missing magnet link' });
  }

  let torrent = client.get(magnet);

  const handleDownloadAll = (torrent) => {
    const downloadPromises = torrent.files.map((file, index) => {
      return new Promise((resolve, reject) => {
        const sanitizedFileName = sanitizeFilename(file.name);
        const outputPath = path.join(downloadsDir, sanitizedFileName);

        // Skip if file already exists
        if (fs.existsSync(outputPath)) {
          console.log(`Skipping existing file: ${sanitizedFileName}`);
          return resolve({
            index,
            filename: sanitizedFileName,
            status: 'already_exists',
            url: `/static/${sanitizedFileName}`
          });
        }

        const progressId = `${torrent.infoHash}_${index}`;
        const totalSize = file.length;
        let downloaded = 0;

        downloadProgress.set(progressId, {
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
            filename: file.name,
            downloaded,
            total: totalSize,
            percentage: parseFloat(percentage),
            status: 'downloading'
          });
        });

        readStream.on('error', reject);
        writeStream.on('error', reject);

        writeStream.on('finish', () => {
          downloadProgress.set(progressId, {
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
            size: totalSize
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
    client.add(magnet, { path: downloadsDir }, (torrent) => {
      torrent.on('ready', () => {
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
    downloadSpeed: (torrent.downloadSpeed / 1e6).toFixed(2) + ' MB/s',
    uploadSpeed: (torrent.uploadSpeed / 1e6).toFixed(2) + ' MB/s',
    numPeers: torrent.numPeers,
    files: torrent.files.length,
    size: (torrent.length / 1e9).toFixed(2) + ' GB'
  }));

  res.json({
    totalTorrents: activeTorrents.length,
    torrents: activeTorrents
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

