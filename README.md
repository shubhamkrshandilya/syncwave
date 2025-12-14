# 🎵 SyncWave

**Cross-platform music streaming app with playlist sharing and multi-device synchronization**

SyncWave is a beautiful, feature-rich music player built with Flutter that allows you to stream music, create playlists, and sync playback across multiple devices in real-time.

---

## ✨ Features

### 🎶 Music Player
- **Modern Player UI** - Beautiful gradient-based design with album art display
- **Playback Controls** - Play, pause, skip, shuffle, and repeat
- **Queue Management** - View and manage your playback queue
- **Progress Tracking** - Real-time position tracking with seek support

### 📚 Playlist Management
- **Create Playlists** - Organize your music into custom playlists
- **Edit & Delete** - Full CRUD operations for playlists
- **Playlist Details** - View all songs in a playlist
- **Quick Play** - Play entire playlists with one tap

### 🔄 Device Synchronization
- **Multi-Device Sync** - Keep playback in sync across devices
- **Device Discovery** - Automatically find nearby devices
- **Connection Status** - See which devices are currently connected
- **Sync Settings** - Configure auto-sync, playlist sync, and more

### 🤝 Sharing & Collaboration
- **QR Code Sharing** - Share playlists via QR codes
- **Room Codes** - Join music sessions with 6-digit codes
- **Host Sessions** - Create rooms for friends to join
- **Real-time Sync** - Everyone hears the same music at the same time

---

## 🏗️ Architecture

### Project Structure

```
lib/
├── main.dart                 # App entry point & navigation
├── config/
│   ├── app_theme.dart        # Theme colors, gradients & styles
│   └── app_constants.dart    # App-wide constants
├── models/
│   ├── song.dart             # Song data model
│   ├── playlist.dart         # Playlist data model
│   └── device.dart           # Connected device model
├── controllers/
│   ├── player_controller.dart    # Music player state management
│   └── playlist_controller.dart  # Playlist CRUD operations
├── services/
│   └── audio_service.dart    # Audio playback using just_audio
├── views/
│   ├── home_screen.dart      # Main player screen
│   ├── playlists_screen.dart # Playlist management
│   ├── share_screen.dart     # QR sharing & room codes
│   └── sync_screen.dart      # Device sync management
└── widgets/
    ├── music_player_card.dart # Album art display
    └── player_controls.dart   # Playback control widgets
```

### State Management
- **Provider** - Used for state management across the app
- Controllers handle business logic and notify UI of changes
- Services manage external integrations (audio, storage, networking)

### Data Persistence
- **Hive** - Local storage for playlists and songs
- **SharedPreferences** - User settings and preferences

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.10.0 or higher)
- Dart SDK
- iOS Simulator / Android Emulator / Physical Device

### Installation

1. **Clone the repository**
   ```bash
   cd syncwave
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### iOS
```bash
cd ios
pod install
cd ..
flutter run
```

#### Android
```bash
flutter run
```

#### Web
```bash
flutter run -d chrome
```

#### macOS
```bash
flutter run -d macos
```

---

## 📦 Dependencies

### Core
- `provider` - State management
- `hive` & `hive_flutter` - Local database
- `go_router` - Navigation (ready for future routing)

### Audio
- `just_audio` - Audio playback
- `audio_service` - Background audio support
- `audio_session` - Audio session management

### UI Components
- `qr_flutter` - QR code generation
- `mobile_scanner` - QR code scanning
- `cached_network_image` - Image caching
- `shimmer` - Loading animations
- `flutter_slidable` - Swipe actions

### File Handling
- `file_picker` - Local file selection
- `path_provider` - Directory access
- `permission_handler` - Runtime permissions

### Networking
- `web_socket_channel` - Real-time sync
- `http` & `dio` - REST API calls

### Utilities
- `uuid` - Unique ID generation
- `intl` - Internationalization
- `equatable` - Value equality

---

## 🎨 Design System

### Colors
- **Primary**: Indigo (#6366F1)
- **Secondary**: Purple (#8B5CF6)
- **Accent**: Pink (#EC4899)
- **Background**: Dark Blue (#0F172A)
- **Surface**: Slate (#1E293B)

### Typography
- **Font Family**: Inter
- **Weights**: Regular (400), Medium (500), SemiBold (600), Bold (700)

### Components
- Cards with 16px border radius
- Gradient backgrounds for key elements
- Consistent 24px padding for screens
- Bottom navigation with gradient indicators

---

## 🔮 Future Enhancements

### Phase 1: File Management
- [ ] Local file import
- [ ] Music library scanning
- [ ] Metadata extraction
- [ ] Album art fetching

### Phase 2: Advanced Playback
- [ ] Equalizer
- [ ] Audio effects
- [ ] Crossfade
- [ ] Gapless playback

### Phase 3: Social Features
- [ ] User profiles
- [ ] Friend system
- [ ] Collaborative playlists
- [ ] Activity feed

### Phase 4: Cloud Integration
- [ ] Cloud storage
- [ ] Cross-device sync via cloud
- [ ] Playlist backup
- [ ] Music recommendations

### Phase 5: Platform Features
- [ ] Widget support
- [ ] Lock screen controls
- [ ] CarPlay / Android Auto
- [ ] Chromecast support

---

## 🧪 Testing

Run tests with:
```bash
flutter test
```

---

## 🌐 Deployment

### Quick Deploy

Use the automated deployment script:
```bash
./deploy.sh
```

This will:
1. Clean previous builds
2. Install dependencies
3. Build the web app
4. Let you choose deployment platform (Firebase, local test, or manual)

### Manual Deployment

**Build for Web:**
```bash
# Profile build (recommended)
flutter build web --profile

# Release build (fully optimized)
flutter build web --release
```

**Deploy to Firebase:**
```bash
# First time setup
npm install -g firebase-tools
firebase login
firebase init hosting

# Deploy
firebase deploy --only hosting
```

**Other Platforms:**
- Vercel: `vercel --prod`
- Netlify: `netlify deploy --prod`
- GitHub Pages: See `DEPLOYMENT.md`

For complete deployment instructions, see [DEPLOYMENT.md](DEPLOYMENT.md)

---

## 📱 Screenshots

*Coming soon - Run the app to see the beautiful UI!*

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📄 License

This project is open source and available under the MIT License.

---

## 👨‍💻 Author

Built with ❤️ using Flutter

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- just_audio for excellent audio playback
- All open-source contributors

---

**Ready to groove? Run the app and start syncing your music! 🎵**
