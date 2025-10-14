# 🎬 Torrent Movie Downloader API

A professional, well-structured backend API for downloading torrent files built with **Express.js** and **WebTorrent**.

## 📁 Project Structure

```
Backend/
├── src/
│   ├── config/
│   │   └── constants.js          # Application constants and configurations
│   ├── controllers/
│   │   └── torrentController.js  # Request handlers for torrent operations
│   ├── services/
│   │   ├── torrentService.js     # Torrent management business logic
│   │   └── downloadService.js    # File download business logic
│   ├── routes/
│   │   ├── index.js              # Main router
│   │   └── torrentRoutes.js      # Torrent-specific routes
│   ├── middleware/
│   │   └── errorHandler.js       # Error handling middleware
│   ├── utils/
│   │   ├── fileHelpers.js        # File utility functions
│   │   └── logger.js             # Logging utility
│   ├── app.js                    # Express app configuration
│   └── server.js                 # Server entry point
├── downloads/                    # Downloaded files (auto-generated)
├── .env                          # Environment variables
├── .env.example                  # Environment variables template
├── .gitignore                    # Git ignore rules
├── package.json                  # NPM dependencies and scripts
└── README.md                     # This file
```

## 🚀 Features

- ✅ **Clean Architecture**: Separation of concerns (MVC pattern)
- ✅ **Modular Design**: Easy to maintain and extend
- ✅ **Error Handling**: Comprehensive error handling middleware
- ✅ **Logging**: Structured logging with emojis
- ✅ **Singleton Services**: Efficient resource management
- ✅ **Progress Tracking**: Real-time download progress
- ✅ **Batch Downloads**: Download multiple files or entire torrents
- ✅ **File Validation**: Validates file indices and formats
- ✅ **Static File Serving**: Access downloaded files via HTTP

## 📦 Installation

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Create environment file:**
   ```bash
   copy .env.example .env
   ```

3. **Start the server:**
   ```bash
   npm start
   ```

   Or for development with auto-reload:
   ```bash
   npm run dev
   ```

## 🔌 API Endpoints

### 1. Get Torrent Information
```http
GET /api/torrent-info?url=<magnet_or_torrent_url>
```

**Response:**
```json
{
  "name": "Movie Collection",
  "infoHash": "abc123...",
  "totalSize": 5368709120,
  "totalSizeFormatted": "5.00 GB",
  "fileCount": 3,
  "files": [
    {
      "index": 0,
      "name": "movie.mp4",
      "nameWithoutExtension": "movie",
      "extension": ".mp4",
      "size": 1073741824,
      "sizeFormatted": "1.00 GB",
      "path": "movie.mp4",
      "mimeType": "video/mp4"
    }
  ]
}
```

### 2. Download Specific Files
```http
GET /api/download?url=<magnet_or_torrent_url>&indices=0,2,5
```

**Response:**
```json
{
  "message": "Download started",
  "torrentName": "Movie Collection",
  "requestedFiles": 3,
  "files": [
    {
      "index": 0,
      "name": "movie.mp4",
      "size": 1073741824,
      "sizeFormatted": "1.00 GB",
      "progressId": "abc123_0"
    }
  ]
}
```

### 3. Download All Files
```http
GET /api/download-all?url=<magnet_or_torrent_url>
```

### 4. Get Download Progress
```http
GET /api/progress?torrent_id=abc123_0
```

**Response:**
```json
{
  "index": 0,
  "filename": "movie.mp4",
  "downloaded": 536870912,
  "total": 1073741824,
  "percentage": 50.0,
  "status": "downloading"
}
```

### 5. List Active Torrents
```http
GET /api/list
```

### 6. Cancel Download
```http
GET /api/cancel?torrent_id=abc123
```

### 7. Access Downloaded Files
```http
GET /static/<filename>
```

## 🏗️ Architecture

### **Controllers** (`src/controllers/`)
Handle HTTP requests and responses. Validate input and delegate to services.

### **Services** (`src/services/`)
Contain business logic. Singleton pattern ensures single instances.
- `torrentService.js`: Manages WebTorrent client and torrent operations
- `downloadService.js`: Handles file download logic

### **Routes** (`src/routes/`)
Define API endpoints and map them to controllers.

### **Middleware** (`src/middleware/`)
Handle cross-cutting concerns like error handling.

### **Utils** (`src/utils/`)
Reusable utility functions for file operations, logging, etc.

### **Config** (`src/config/`)
Application-wide constants and configurations.

## 🛠️ Technologies

- **Express.js**: Web framework
- **WebTorrent**: Torrent client
- **CORS**: Cross-origin resource sharing
- **ES6 Modules**: Modern JavaScript syntax

## 📝 Environment Variables

Create a `.env` file:

```env
PORT=3000
NODE_ENV=development
```

## 🧪 Development

```bash
# Start development server with auto-reload
npm run dev

# Start production server
npm start
```

## 📊 Status Codes

- `200`: Success
- `400`: Bad Request (missing/invalid parameters)
- `404`: Not Found (torrent/file not found)
- `500`: Internal Server Error

## 🔒 Security Notes

- Add authentication middleware for production use
- Implement rate limiting
- Validate and sanitize all user inputs
- Use HTTPS in production

## 📄 License

ISC

## 👨‍💻 Author

Your Name

---

**Made with ❤️ and Node.js**
