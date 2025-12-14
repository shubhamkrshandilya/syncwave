const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const { parseFile } = require('music-metadata');
const chokidar = require('chokidar');

const app = express();
const PORT = process.env.PORT || 3456; // Local server port

// Production: CORS whitelist (configure for your deployment)
const ALLOWED_ORIGINS = [
  'http://localhost:3456',
  'http://127.0.0.1:3456',
  /^http:\/\/localhost:\d+$/,     // Allow any localhost port (dev)
  /^http:\/\/127\.0\.0\.1:\d+$/, // Allow any 127.0.0.1 port (dev)
  // Add production domains here:
  // 'https://yourdomain.com',
];

// Music library configuration
const MUSIC_DIRECTORIES = [
  path.join(require('os').homedir(), 'Music'),
  // Add more directories as needed
];

// Enable CORS for Flutter web app (production-safe)
app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, curl, etc.)
    if (!origin) return callback(null, true);
    
    // Check against whitelist
    const isAllowed = ALLOWED_ORIGINS.some(allowed => {
      if (typeof allowed === 'string') return allowed === origin;
      if (allowed instanceof RegExp) return allowed.test(origin);
      return false;
    });
    
    if (isAllowed) {
      callback(null, true);
    } else {
      console.warn(`CORS blocked: ${origin}`);
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true
}));

// Enable compression for better performance
const compression = require('compression');
app.use(compression());

app.use(express.json());

// In-memory cache of music library
let musicLibrary = [];
let isScanning = false;

// Supported audio formats
const AUDIO_EXTENSIONS = ['.mp3', '.m4a', '.flac', '.wav', '.ogg', '.aac', '.opus'];

// Scan music directories
async function scanMusicLibrary() {
  if (isScanning) {
    console.log('Scan already in progress...');
    return;
  }

  isScanning = true;
  musicLibrary = [];
  console.log('🔍 Scanning music library...');

  for (const dir of MUSIC_DIRECTORIES) {
    if (!fs.existsSync(dir)) {
      console.log(`⚠️  Directory not found: ${dir}`);
      continue;
    }

    await scanDirectory(dir);
  }

  isScanning = false;
  console.log(`✅ Scan complete! Found ${musicLibrary.length} songs`);
}

// Recursive directory scanner
async function scanDirectory(dir) {
  try {
    const entries = fs.readdirSync(dir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);

      if (entry.isDirectory()) {
        // Skip hidden directories and system folders
        if (!entry.name.startsWith('.') && entry.name !== 'node_modules') {
          await scanDirectory(fullPath);
        }
      } else if (entry.isFile()) {
        const ext = path.extname(entry.name).toLowerCase();
        if (AUDIO_EXTENSIONS.includes(ext)) {
          await addSongToLibrary(fullPath);
        }
      }
    }
  } catch (error) {
    console.error(`Error scanning ${dir}:`, error.message);
  }
}

// Extract metadata and add song
async function addSongToLibrary(filePath) {
  try {
    const metadata = await parseFile(filePath);
    const stats = fs.statSync(filePath);

    const song = {
      id: Buffer.from(filePath).toString('base64'), // Unique ID from path
      title: metadata.common.title || path.basename(filePath, path.extname(filePath)),
      artist: metadata.common.artist || metadata.common.albumartist || 'Unknown Artist',
      album: metadata.common.album || 'Unknown Album',
      duration: metadata.format.duration || 0,
      filePath: filePath,
      fileSize: stats.size,
      format: path.extname(filePath).substring(1).toUpperCase(),
      coverArt: metadata.common.picture?.[0] ? true : false
    };

    musicLibrary.push(song);
  } catch (error) {
    // Silently skip files with metadata errors
    console.warn(`⚠️  Could not read metadata: ${path.basename(filePath)}`);
  }
}

// Watch for file system changes
function watchMusicDirectories() {
  const watcher = chokidar.watch(MUSIC_DIRECTORIES, {
    ignored: /(^|[\/\\])\../, // ignore dotfiles
    persistent: true,
    ignoreInitial: true
  });

  watcher
    .on('add', async (filePath) => {
      const ext = path.extname(filePath).toLowerCase();
      if (AUDIO_EXTENSIONS.includes(ext)) {
        console.log(`➕ New file detected: ${path.basename(filePath)}`);
        await addSongToLibrary(filePath);
      }
    })
    .on('unlink', (filePath) => {
      const id = Buffer.from(filePath).toString('base64');
      musicLibrary = musicLibrary.filter(song => song.id !== id);
      console.log(`➖ File removed: ${path.basename(filePath)}`);
    });

  console.log('👀 Watching for file changes...');
}

// API Routes

// Health check
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    version: '1.0.0',
    librarySize: musicLibrary.length,
    isScanning
  });
});

// Get all songs
app.get('/api/songs', (req, res) => {
  res.json({
    songs: musicLibrary,
    total: musicLibrary.length
  });
});

// Search songs
app.get('/api/songs/search', (req, res) => {
  const query = (req.query.q || '').toLowerCase();
  
  if (!query) {
    return res.json({ songs: musicLibrary, total: musicLibrary.length });
  }

  const filtered = musicLibrary.filter(song =>
    song.title.toLowerCase().includes(query) ||
    song.artist.toLowerCase().includes(query) ||
    song.album.toLowerCase().includes(query)
  );

  res.json({ songs: filtered, total: filtered.length });
});

// Get song metadata
app.get('/api/songs/:id', (req, res) => {
  const song = musicLibrary.find(s => s.id === req.params.id);
  
  if (!song) {
    return res.status(404).json({ error: 'Song not found' });
  }

  res.json(song);
});

// Stream audio file
app.get('/api/stream/:id', (req, res) => {
  const song = musicLibrary.find(s => s.id === req.params.id);
  
  if (!song || !fs.existsSync(song.filePath)) {
    return res.status(404).json({ error: 'Song not found' });
  }

  const stat = fs.statSync(song.filePath);
  const fileSize = stat.size;
  const range = req.headers.range;

  if (range) {
    // Handle range requests for seeking
    const parts = range.replace(/bytes=/, '').split('-');
    const start = parseInt(parts[0], 10);
    const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;
    const chunksize = (end - start) + 1;
    const file = fs.createReadStream(song.filePath, { start, end });

    res.writeHead(206, {
      'Content-Range': `bytes ${start}-${end}/${fileSize}`,
      'Accept-Ranges': 'bytes',
      'Content-Length': chunksize,
      'Content-Type': 'audio/mpeg',
    });

    file.pipe(res);
  } else {
    // Full file stream
    res.writeHead(200, {
      'Content-Length': fileSize,
      'Content-Type': 'audio/mpeg',
      'Accept-Ranges': 'bytes',
    });

    fs.createReadStream(song.filePath).pipe(res);
  }
});

// Get album art
app.get('/api/cover/:id', async (req, res) => {
  const song = musicLibrary.find(s => s.id === req.params.id);
  
  if (!song || !fs.existsSync(song.filePath)) {
    return res.status(404).json({ error: 'Song not found' });
  }

  try {
    const metadata = await parseFile(song.filePath);
    const picture = metadata.common.picture?.[0];

    if (picture) {
      res.set('Content-Type', picture.format);
      res.send(picture.data);
    } else {
      res.status(404).json({ error: 'No cover art found' });
    }
  } catch (error) {
    res.status(500).json({ error: 'Failed to extract cover art' });
  }
});

// Trigger manual scan
app.post('/api/scan', async (req, res) => {
  if (isScanning) {
    return res.status(409).json({ error: 'Scan already in progress' });
  }

  res.json({ message: 'Scan started' });
  await scanMusicLibrary();
});

// Add custom directory
app.post('/api/directories', (req, res) => {
  const { path: dirPath } = req.body;

  if (!dirPath || !fs.existsSync(dirPath)) {
    return res.status(400).json({ error: 'Invalid directory path' });
  }

  if (!MUSIC_DIRECTORIES.includes(dirPath)) {
    MUSIC_DIRECTORIES.push(dirPath);
    res.json({ message: 'Directory added', directories: MUSIC_DIRECTORIES });
    scanMusicLibrary();
  } else {
    res.status(409).json({ error: 'Directory already exists' });
  }
});

// Get configured directories
app.get('/api/directories', (req, res) => {
  res.json({ directories: MUSIC_DIRECTORIES });
});

// Start server
async function startServer() {
  console.log('🎵 SyncWave Local Server');
  console.log('========================\n');

  // Initial scan
  await scanMusicLibrary();

  // Start watching
  watchMusicDirectories();

  // Start HTTP server
  app.listen(PORT, () => {
    console.log(`\n🚀 Server running at http://localhost:${PORT}`);
    console.log(`📁 Music directories:`);
    MUSIC_DIRECTORIES.forEach(dir => console.log(`   - ${dir}`));
    console.log(`\n💡 Connect your Flutter app to: http://localhost:${PORT}`);
  });
}

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('\n\n👋 Shutting down server...');
  process.exit(0);
});

// Start the server
startServer().catch(console.error);
