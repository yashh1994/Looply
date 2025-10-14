import express from 'express';
import torrentRoutes from './torrentRoutes.js';

const router = express.Router();

/**
 * Root route - API documentation
 */
router.get('/', (req, res) => {
  res.json({
    message: "🎬 Torrent Movie Downloader API",
    version: "2.0.0",
    endpoints: {
      "/": "This help page",
      "/api/torrent-info?url=<magnet_or_torrent_url>": "Get all files from torrent with details",
      "/api/download?url=<magnet_or_torrent_url>&indices=<comma_separated_indices>": "Download specific files by indices",
      "/api/download-all?url=<magnet_or_torrent_url>": "Download all files from torrent",
      "/api/progress?torrent_id=<id>": "Get download progress for specific download",
      "/api/progress": "Get all download progress",
      "/api/list": "List all active torrents",
      "/api/cancel?torrent_id=<id>": "Cancel a download"
    },
    examples: {
      getTorrentInfo: "/api/torrent-info?url=magnet:?xt=urn:btih:...",
      downloadSpecific: "/api/download?url=magnet:?xt=urn:btih:...&indices=0,2,5",
      downloadAll: "/api/download-all?url=magnet:?xt=urn:btih:...",
      getProgress: "/api/progress?torrent_id=abc123_0",
      listTorrents: "/api/list",
      cancelTorrent: "/api/cancel?torrent_id=abc123"
    }
  });
});

/**
 * Mount torrent routes
 */
router.use('/api', torrentRoutes);

export default router;
