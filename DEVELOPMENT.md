# 🛠️ SyncWave Development Guide

This guide will help you understand the codebase and start contributing to SyncWave.

---

## 📋 Table of Contents

1. [Project Setup](#project-setup)
2. [Architecture Overview](#architecture-overview)
3. [Code Structure](#code-structure)
4. [Adding Features](#adding-features)
5. [Best Practices](#best-practices)
6. [Debugging](#debugging)

---

## 🚀 Project Setup

### Quick Start

```bash
# Make the start script executable (first time only)
chmod +x start.sh

# Run the quick start script
./start.sh
```

### Manual Setup

```bash
# Install dependencies
flutter pub get

# Run on specific platform
flutter run -d chrome          # Web
flutter run -d macos           # macOS
flutter run -d ios             # iOS Simulator
flutter run -d android         # Android Emulator

# Run in release mode (better performance)
flutter run --release
```

---

## 🏗️ Architecture Overview

### State Management Pattern

SyncWave uses **Provider** for state management with the following pattern:

```dart
// 1. Controller (Business Logic)
class PlayerController extends ChangeNotifier {
  // State
  Song? _currentSong;
  
  // Getter
  Song? get currentSong => _currentSong;
  
  // Action
  void playSong(Song song) {
    _currentSong = song;
    notifyListeners(); // Update UI
  }
}

// 2. Provider Setup (main.dart)
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => PlayerController()),
  ],
  child: App(),
)

// 3. UI Consumption
Consumer<PlayerController>(
  builder: (context, controller, child) {
    return Text(controller.currentSong?.title ?? 'No song');
  },
)
```

### Data Flow

```
User Action → Controller → Service → External API/Storage
                ↓
           notifyListeners()
                ↓
           UI Updates (Consumer)
```

---

## 📁 Code Structure

### Models (`lib/models/`)

Data classes representing core entities:

- `song.dart` - Song metadata (title, artist, duration, etc.)
- `playlist.dart` - Playlist with songs collection
- `device.dart` - Connected device information

**Example: Adding a new model**

```dart
class Album {
  final String id;
  final String title;
  final String artist;
  final List<Song> songs;
  
  Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.songs,
  });
  
  // JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'songs': songs.map((s) => s.toJson()).toList(),
  };
  
  factory Album.fromJson(Map<String, dynamic> json) => Album(
    id: json['id'],
    title: json['title'],
    artist: json['artist'],
    songs: (json['songs'] as List)
        .map((s) => Song.fromJson(s))
        .toList(),
  );
}
```

### Controllers (`lib/controllers/`)

Business logic and state management:

- `player_controller.dart` - Music playback state
- `playlist_controller.dart` - Playlist CRUD operations

**Example: Adding a new action**

```dart
// In PlayerController
void addToFavorites(Song song) {
  _favorites.add(song);
  _saveFavorites(); // Persist to storage
  notifyListeners(); // Update UI
}
```

### Services (`lib/services/`)

External integrations and platform APIs:

- `audio_service.dart` - Audio playback using just_audio

**Example: Creating a new service**

```dart
class SyncService extends ChangeNotifier {
  final WebSocket _socket;
  bool _isConnected = false;
  
  bool get isConnected => _isConnected;
  
  Future<void> connect(String url) async {
    try {
      _socket = await WebSocket.connect(url);
      _isConnected = true;
      notifyListeners();
      
      _socket.listen((data) {
        // Handle incoming messages
      });
    } catch (e) {
      print('Connection failed: $e');
    }
  }
  
  void sendMessage(String message) {
    if (_isConnected) {
      _socket.add(message);
    }
  }
}
```

### Views (`lib/views/`)

Full-screen pages:

- `home_screen.dart` - Main player interface
- `playlists_screen.dart` - Playlist management
- `share_screen.dart` - QR code sharing
- `sync_screen.dart` - Device synchronization

### Widgets (`lib/widgets/`)

Reusable UI components:

- `music_player_card.dart` - Album art display
- `player_controls.dart` - Playback controls

**Example: Creating a reusable widget**

```dart
class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  
  const SongTile({
    required this.song,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: song.albumArt != null
            ? NetworkImage(song.albumArt!)
            : null,
        child: song.albumArt == null
            ? Icon(Icons.music_note)
            : null,
      ),
      title: Text(song.title),
      subtitle: Text(song.artist),
      onTap: onTap,
    );
  }
}
```

---

## ➕ Adding Features

### 1. File Upload Feature

**Steps:**

1. Add file picker logic in `services/file_service.dart`
2. Update `PlayerController` to handle new songs
3. Add UI button in `home_screen.dart`

```dart
// services/file_service.dart
class FileService {
  Future<Song?> pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    
    if (result != null) {
      final file = result.files.first;
      return Song(
        id: DateTime.now().toString(),
        title: file.name,
        artist: 'Unknown',
        filePath: file.path!,
        duration: Duration.zero, // Get from metadata
      );
    }
    return null;
  }
}

// home_screen.dart
Future<void> _handleFileUpload() async {
  final fileService = FileService();
  final song = await fileService.pickAudioFile();
  
  if (song != null) {
    context.read<PlayerController>().addToQueue(song);
  }
}
```

### 2. WebSocket Sync Feature

**Steps:**

1. Create `services/websocket_service.dart`
2. Add sync controller in `controllers/sync_controller.dart`
3. Integrate in `sync_screen.dart`

```dart
// services/websocket_service.dart
class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  
  void connect(String url) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    
    _channel!.stream.listen((message) {
      // Handle sync messages
      _handleMessage(message);
    });
  }
  
  void sendPlaybackState(Song song, Duration position) {
    final data = json.encode({
      'type': 'playback',
      'song': song.toJson(),
      'position': position.inMilliseconds,
    });
    _channel?.sink.add(data);
  }
}
```

---

## ✅ Best Practices

### 1. Code Organization

```dart
// ✅ Good: Organized imports
import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/song.dart';
import '../controllers/player_controller.dart';

// ❌ Bad: Mixed imports
import '../models/song.dart';
import 'package:flutter/material.dart';
import '../controllers/player_controller.dart';
```

### 2. Widget Extraction

```dart
// ✅ Good: Small, focused widgets
class PlayerControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PreviousButton(),
        _PlayPauseButton(),
        _NextButton(),
      ],
    );
  }
}

// ❌ Bad: Giant build methods
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 300+ lines of widgets
        ],
      ),
    );
  }
}
```

### 3. State Management

```dart
// ✅ Good: Use Consumer for specific rebuilds
Consumer<PlayerController>(
  builder: (context, controller, child) {
    return Text(controller.currentSong?.title ?? '');
  },
)

// ❌ Bad: Unnecessary rebuilds
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerController>();
    // Entire screen rebuilds on any change
  }
}
```

### 4. Error Handling

```dart
// ✅ Good: Proper error handling
Future<void> playSong(Song song) async {
  try {
    await _audioPlayer.setFilePath(song.filePath);
    await _audioPlayer.play();
  } catch (e) {
    debugPrint('Error playing song: $e');
    _showErrorSnackbar('Unable to play song');
  }
}

// ❌ Bad: Silent failures
Future<void> playSong(Song song) async {
  await _audioPlayer.setFilePath(song.filePath);
  await _audioPlayer.play();
}
```

---

## 🐛 Debugging

### Flutter DevTools

```bash
# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

### Common Issues

**1. Hot Reload Not Working**
```bash
# Full restart
flutter run --hot

# Or press 'R' in terminal
```

**2. Build Errors**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

**3. iOS Build Issues**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter run
```

### Logging

```dart
import 'package:flutter/foundation.dart';

// Use debugPrint for development logs
debugPrint('Current song: ${song.title}');

// Use kDebugMode for conditional debug code
if (kDebugMode) {
  print('Debug info: $details');
}
```

---

## 🧪 Testing

### Unit Tests

```dart
// test/controllers/player_controller_test.dart
void main() {
  group('PlayerController', () {
    test('playSong updates current song', () {
      final controller = PlayerController();
      final song = Song(id: '1', title: 'Test');
      
      controller.playSong(song);
      
      expect(controller.currentSong, song);
      expect(controller.isPlaying, true);
    });
  });
}
```

Run tests:
```bash
flutter test
```

---

## 📚 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Provider Package](https://pub.dev/packages/provider)
- [just_audio Package](https://pub.dev/packages/just_audio)
- [Hive Database](https://docs.hivedb.dev/)

---

**Happy Coding! 🚀**