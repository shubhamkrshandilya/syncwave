# 🎵 SyncWave Web - Local Music Guide

## How to Play Your Local Music in Chrome

Since web browsers can't directly access your file system for security reasons, SyncWave uses a file picker to let you manually select music files.

---

## 📁 Loading Music Files

### Method 1: Upload Button (Top Right)
1. Click the **Upload Music** button (📤) in the top-right corner
2. Browser will open a file picker dialog
3. Navigate to your music folder
4. Select one or more audio files (.mp3, .m4a, .wav, .ogg, .flac)
5. Click "Open" or "Choose"
6. Songs will be added to your queue automatically

### Method 2: Empty State Button
1. If no music is playing, you'll see an empty state
2. Click the **"Upload Music"** button in the center
3. Follow the same steps as Method 1

---

## 🎧 Supported Audio Formats

- **MP3** (.mp3) - Most common
- **M4A** (.m4a) - Apple/iTunes format
- **WAV** (.wav) - Uncompressed audio
- **OGG** (.ogg) - Open source format
- **FLAC** (.flac) - Lossless compression

---

## 📱 How It Works

1. **File Selection**: You select files using your browser's file picker
2. **In-Memory Storage**: Files are loaded into browser memory (RAM)
3. **Playback**: Audio plays directly from memory using Web Audio API
4. **Session Only**: Files are only available during current session
5. **Privacy**: Files never leave your computer - everything is local

---

## 💡 Tips

### Multiple File Selection
- Hold `Cmd` (Mac) or `Ctrl` (Windows/Linux) to select multiple files
- Hold `Shift` to select a range of files
- You can upload multiple times to build your queue

### Best Practices
- Upload batches of 10-20 songs at a time for best performance
- Total file size should stay under 500MB for smooth playback
- Browser tab must stay open for playback to continue

### Managing Your Queue
- Click songs in the horizontal queue preview to play them
- Use ▶️ Next/Previous buttons to navigate
- Click 🔀 Shuffle to randomize playback order
- Click 🔁 Repeat to loop current song

---

## 🔄 Persistence

**Important**: Uploaded files are cleared when you:
- Close the browser tab
- Refresh the page
- Clear browser cache

To keep music between sessions, you'll need to re-upload files each time you visit the app.

---

## 🚫 Limitations (Web vs Native Apps)

| Feature | Web Browser | Mobile/Desktop App |
|---------|------------|-------------------|
| Manual file selection | ✅ Yes | ✅ Yes |
| Auto-scan music folder | ❌ No | ✅ Yes |
| Background playback | ⚠️ Tab must stay open | ✅ Works when closed |
| Persistent library | ❌ Session only | ✅ Saved locally |
| File size limit | ⚠️ ~500MB recommended | ✅ No practical limit |

---

## 🎯 Quick Start Example

1. Open SyncWave in Chrome
2. Click **Upload Music** button (📤)
3. Navigate to your Music folder (e.g., `~/Music` or `C:\Users\YourName\Music`)
4. Select your favorite songs
5. Click "Open"
6. Music will appear in the queue
7. Click play! 🎵

---

## 🔧 Troubleshooting

### Files Won't Upload
- Check file format is supported (.mp3, .m4a, etc.)
- Ensure total size isn't too large (>1GB)
- Try uploading fewer files at once
- Check browser console for errors (F12)

### No Sound Playing
- Check browser volume isn't muted
- Check system volume
- Ensure file isn't corrupted (try different file)
- Check browser permissions for audio

### Playback Stops
- Browser tab may have lost focus (click tab)
- Check if tab went to sleep (browser power saving)
- Ensure browser didn't run out of memory

---

## 🌐 Browser Recommendations

**Best Experience:**
- Google Chrome (latest)
- Microsoft Edge (latest)
- Brave Browser (latest)

**Also Works:**
- Firefox (may have audio format limitations)
- Safari (Mac only, some format limitations)

---

## 🔮 Future Features

We're working on:
- IndexedDB storage for persistence
- Drag & drop file upload
- Folder upload support
- Better metadata extraction (album art, artist info)
- Cloud sync integration

---

**Enjoy your music! 🎶**

For more features, consider building the native mobile or desktop app from the Flutter project.
