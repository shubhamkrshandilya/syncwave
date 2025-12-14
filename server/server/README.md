# SyncWave Local Server

Local file server that enables SyncWave web app to access your music library without uploading files to browser storage.

## Features

✅ **Direct file system access** - No file uploads needed  
✅ **Automatic library scanning** - Finds music in your Music folder  
✅ **Real-time monitoring** - Detects new/removed files automatically  
✅ **Metadata extraction** - Reads ID3 tags, album art  
✅ **Audio streaming** - Range requests for seeking  
✅ **Search & filter** - Find songs by title, artist, album  
✅ **CORS enabled** - Works with Flutter web app  

## Installation

```bash
cd server
npm install
```

## Usage

### Start Server

```bash
npm start
```

The server will:
1. Scan your `~/Music` folder
2. Extract metadata from all audio files
3. Start HTTP server on `http://localhost:3456`
4. Watch for file system changes

### Development Mode (Auto-restart)

```bash
npm run dev
```

## API Endpoints

### GET /api/health
Health check and server status

**Response:**
```json
{
  "status": "ok",
  "version": "1.0.0",
  "librarySize": 1234,
  "isScanning": false
}
```

### GET /api/songs
Get all songs in library

**Response:**
```json
{
  "songs": [
    {
      "id": "base64_encoded_path",
      "title": "Song Title",
      "artist": "Artist Name",
      "album": "Album Name",
      "duration": 245.5,
      "filePath": "/Users/you/Music/song.mp3",
      "fileSize": 5242880,
      "format": "MP3",
      "coverArt": true
    }
  ],
  "total": 1234
}
```

### GET /api/songs/search?q=query
Search songs by title, artist, or album

**Parameters:**
- `q` - Search query (case-insensitive)

### GET /api/stream/:id
Stream audio file (supports range requests for seeking)

**Headers:**
- `Range: bytes=0-1023` (optional)

### GET /api/cover/:id
Get album art for a song

**Response:** Image binary data (JPEG/PNG)

### POST /api/scan
Trigger manual library scan

### GET /api/directories
Get configured music directories

### POST /api/directories
Add custom music directory

**Body:**
```json
{
  "path": "/path/to/music/folder"
}
```

## Configuration

Edit `server.js` to customize:

```javascript
// Port number
const PORT = 3456;

// Music directories to scan
const MUSIC_DIRECTORIES = [
  path.join(require('os').homedir(), 'Music'),
  '/path/to/your/music',
  // Add more directories
];

// Supported audio formats
const AUDIO_EXTENSIONS = ['.mp3', '.m4a', '.flac', '.wav', '.ogg', '.aac', '.opus'];
```

## How It Works

1. **Server scans** your music directories on startup
2. **Extracts metadata** using `music-metadata` library
3. **Builds in-memory index** of all songs
4. **Watches filesystem** for changes (add/remove files)
5. **Flutter web app** connects to `http://localhost:3456`
6. **Streams audio** directly from local files (no upload!)

## Production Deployment

### Option 1: Electron App (Recommended)
Package server + Flutter web app into desktop application using Electron.

### Option 2: System Service
Run as background service:

**macOS (launchd):**
```bash
# Create ~/Library/LaunchAgents/com.syncwave.server.plist
# See deployment guide
```

**Linux (systemd):**
```bash
# Create /etc/systemd/system/syncwave.service
# See deployment guide
```

**Windows (NSSM):**
```powershell
# Install as Windows service using NSSM
# See deployment guide
```

### Option 3: Docker
```bash
docker build -t syncwave-server .
docker run -p 3456:3456 -v ~/Music:/music syncwave-server
```

## Security Notes

⚠️ **Local network only** - Server runs on localhost by default  
⚠️ **No authentication** - Assumes trusted local environment  
⚠️ **File access** - Server can read all files in configured directories  

For public deployment, add:
- Authentication (JWT tokens)
- HTTPS/TLS encryption
- Rate limiting
- Input validation

## Troubleshooting

**No songs found:**
- Check music directory path exists
- Verify audio file formats are supported
- Check console for scanning errors

**Connection refused:**
- Ensure server is running (`npm start`)
- Check port 3456 is not in use
- Verify firewall allows localhost connections

**Metadata errors:**
- Some files may have corrupted tags (skipped automatically)
- Check console warnings for specific files

## License

MIT
