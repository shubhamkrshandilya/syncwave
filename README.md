# 🎵 SyncWave

**Cross-platform local music player with background playback and system media controls**

SyncWave is a beautiful, feature-rich music player built with Flutter that plays your local music files with full background playback support and system notification controls on iOS, Android, and macOS.

---

## ✨ Features

### 🎶 Music Player
- **Modern Player UI** - Beautiful gradient-based design with album art display
- **Playback Controls** - Play, pause, skip, seek with intuitive controls
- **Queue Management** - View and manage your playback queue
- **Auto-play Next** - Automatically plays the next song in queue
- **Progress Tracking** - Real-time position tracking with seek support

### 🎵 Background Playback
- **System Notifications** - Control playback from notification panel (iOS, Android)
- **Lock Screen Controls** - Full media controls on iOS Control Center and Android lock screen
- **Background Audio** - Music continues playing when app is in background
- **Media Metadata** - Song title, artist, album, and artwork in system notifications

### 📚 Music Library
- **Local File Support** - Play music from your device storage
- **Multi-select Import** - Import multiple songs at once via file picker
- **Playlist Management** - Create and manage custom playlists
- **Persistent Storage** - Songs and playlists saved using Hive database

### 🎨 Beautiful Design
- **Gradient UI** - Modern gradient-based design with blur effects
- **Responsive Layout** - Adapts to different screen sizes and orientations
- **Album Artwork** - Displays embedded album art from music files
- **Dark Theme** - Easy on the eyes for night-time listening

---

## 🏗️ Architecture

### Project Structure

```
lib/
├── main.dart                 # App entry point with audio service initialization
├── config/
│   ├── app_theme.dart        # Theme colors, gradients & styles
│   └── app_constants.dart    # App-wide constants
├── models/
│   ├── song.dart             # Song data model
│   ├── playlist.dart         # Playlist data model
│   └── device.dart           # Device model
├── controllers/
│   ├── player_controller.dart    # Music player state & queue management
│   └── playlist_controller.dart  # Playlist CRUD operations
├── services/
│   ├── audio_service.dart    # Audio playback using just_audio
│   ├── audio_handler.dart    # Background audio & notification controls
│   └── music_scanner.dart    # Local music file scanning
├── views/
│   ├── home_screen.dart      # Main player screen with queue
│   ├── playlists_screen.dart # Playlist management
│   └── library_screen.dart   # Music library view
└── widgets/
    ├── music_player_card.dart # Album art display with controls
    └── player_controls.dart   # Play/pause/skip buttons
```

### Key Technologies

**Audio Stack:**
- **just_audio** (^0.9.36) - High-quality audio playback engine
- **audio_service** (^0.18.12) - Background playback and system media controls
- **audio_session** (^0.1.18) - Audio session management for iOS/Android

**State Management:**
- **Provider** - Used for state management across the app
- Controllers handle business logic and notify UI of changes
- Services manage audio playback and file operations

**Data Persistence:**
- **Hive** - Local NoSQL database for playlists and song metadata
- Stores library, playlists, and user preferences

**File Handling:**
- **file_picker** - Multi-select file import
- **path_provider** - Platform-specific storage paths
- **metadata_god** - Extract audio metadata (title, artist, album art)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.10.0 or higher)
- Dart SDK
- iOS device/simulator, Android device/emulator, or macOS

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/shubhamkrshandilya/syncwave.git
   cd syncwave
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run on your platform**
   
   **iOS:**
   ```bash
   cd ios && pod install && cd ..
   flutter run -d <your-ios-device-id>
   ```
   
   **Android:**
   ```bash
   flutter run -d <your-android-device-id>
   ```
   
   **macOS:**
   ```bash
   flutter run -d macos
   ```

### Platform-Specific Setup

**iOS Requirements:**
- Xcode 14.0 or higher
- iOS 12.0 or higher
- Code signing team configured in Xcode
- Background audio capability enabled in Info.plist

**Android Requirements:**
- Android SDK 21 (Lollipop) or higher
- MainActivity extends `AudioServiceActivity`
- Permissions: FOREGROUND_SERVICE, WAKE_LOCK
- Audio service declared in AndroidManifest.xml

**macOS Requirements:**
- macOS 10.14 or higher

---

## 📱 Usage

### Importing Music
1. Tap the **"Scan Music"** button on the home screen
2. Use the file picker to select music files (supports multi-select)
3. Songs are automatically added to your library
4. Album art and metadata are extracted automatically

### Playing Music
1. Browse your library or playlists
2. Tap any song to start playback
3. Use playback controls: Previous, Play/Pause, Next
4. Drag the progress bar to seek within the song
5. Queue shows upcoming songs

### Background Playback
- Music continues when you lock your device or switch apps
- **iOS:** Control from Control Center or Lock Screen
- **Android:** Control from notification shade
- All controls (play/pause/skip) work from notifications

### Playlists
1. Navigate to **Playlists** screen
2. Create new playlists with custom names
3. Add songs to playlists from the library
4. Play entire playlists with one tap

---

## 📦 Key Dependencies

### Audio Stack
- `just_audio: ^0.9.36` - Audio playback engine
- `audio_service: ^0.18.12` - Background playback & media controls
- `audio_session: ^0.1.18` - Audio session management

### State & Storage
- `provider: ^6.1.1` - State management
- `hive: ^2.2.3` - Local NoSQL database
- `hive_flutter: ^1.1.0` - Flutter integration for Hive

### File & Metadata
- `file_picker: ^8.0.0+1` - Multi-select file import
- `path_provider: ^2.1.2` - Platform storage paths
- `metadata_god: ^0.5.2` - Audio metadata extraction
- `permission_handler: ^11.3.0` - Runtime permissions

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

## 🎯 Roadmap

### Completed ✅
- [x] Local music file playback
- [x] Background audio playback
- [x] System notification controls (iOS/Android)
- [x] Lock screen controls
- [x] Playlist management
- [x] Queue management
- [x] Auto-play next song
- [x] Metadata extraction (title, artist, album, artwork)
- [x] Multi-select file import
- [x] Progress tracking and seeking
- [x] macOS support

### Planned Features 🚀

**Phase 1: Enhanced Playback**
- [ ] Shuffle and repeat modes
- [ ] Equalizer controls
- [ ] Sleep timer
- [ ] Playback speed control
- [ ] Gapless playback

**Phase 2: Library Management**
- [ ] Smart playlists
- [ ] Recently played
- [ ] Most played tracks
- [ ] Search functionality
- [ ] Sort and filter options
- [ ] Album and artist grouping

**Phase 3: Advanced Features**
- [ ] Lyrics display
- [ ] Audio effects
- [ ] Crossfade between tracks
- [ ] Car mode / Android Auto
- [ ] Home screen widgets

**Phase 4: Platform Expansion**
- [ ] Windows support
- [ ] Linux support
- [ ] Web support (limited playback)

---

## 🧪 Testing

Run tests with:
```bash
flutter test
```

---

## 🏗️ Building for Release

### iOS
```bash
flutter build ios --release
```

### Android
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

---

## 📱 Screenshots

*Coming soon - Run the app to see the beautiful gradient UI with album artwork!*

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Shubham Kumar Shandilya**
- GitHub: [@shubhamkrshandilya](https://github.com/shubhamkrshandilya)

---

## 🙏 Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Audio playback powered by [just_audio](https://pub.dev/packages/just_audio)
- Background audio using [audio_service](https://pub.dev/packages/audio_service)
- Local storage with [Hive](https://pub.dev/packages/hive)

---

**Made with ❤️ using Flutter**


## 👨‍💻 Author

Built with ❤️ using Flutter

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- just_audio for excellent audio playback
- All open-source contributors

---

**Ready to groove? Run the app and start syncing your music! 🎵**
