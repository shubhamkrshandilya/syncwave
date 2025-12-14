import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:hive/hive.dart';
import '../models/song.dart';
import 'package:uuid/uuid.dart';

class LocalMusicScanner {
  final _uuid = const Uuid();
  late Box<Map<dynamic, dynamic>> _scanHistoryBox;
  bool _isInitialized = false;

  static const List<String> _audioExtensions = [
    '.mp3', '.m4a', '.wav', '.flac', '.aac', '.ogg', '.wma', '.opus'
  ];

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      if (!Hive.isBoxOpen('scan_history')) {
        _scanHistoryBox = await Hive.openBox<Map<dynamic, dynamic>>('scan_history');
      } else {
        _scanHistoryBox = Hive.box<Map<dynamic, dynamic>>('scan_history');
      }
      _isInitialized = true;
      debugPrint('LocalMusicScanner initialized successfully');
    } catch (e) {
      debugPrint('Error initializing LocalMusicScanner: $e');
      // Initialize anyway but without persistence
      _isInitialized = true;
    }
  }

  /// Get default music directories for macOS and Android
  List<String> getDefaultMusicPaths() {
    if (kIsWeb) return [];
    
    // iOS doesn't allow automatic directory scanning due to sandboxing
    // Users must use file picker instead
    if (Platform.isIOS) return [];
    
    final home = Platform.environment['HOME'] ?? '';
    if (home.isEmpty) return [];

    return [
      path.join(home, 'Music', 'Music'),
      path.join(home, 'Music'),
      path.join(home, 'Downloads'),
    ];
  }

  /// Scan a directory recursively for audio files
  Future<List<Song>> scanDirectory(
    String directoryPath, {
    Function(int scanned, String currentFile)? onProgress,
    int maxDepth = 5,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Directory scanning not supported on web');
    }

    // iOS doesn't support directory scanning due to sandboxing
    // Return empty list if attempting to scan iOS sandboxed paths
    if (Platform.isIOS && directoryPath.contains('File Provider Storage')) {
      debugPrint('iOS sandboxed path detected, skipping scan: $directoryPath');
      return [];
    }

    debugPrint('Starting scan of directory: $directoryPath');
    
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      debugPrint('Directory does not exist: $directoryPath');
      throw Exception('Directory does not exist: $directoryPath');
    }

    final songs = <Song>[];
    int scannedCount = 0;

    try {
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = path.extension(entity.path).toLowerCase();
          
          if (_audioExtensions.contains(ext)) {
            scannedCount++;
            debugPrint('Found audio file $scannedCount: ${entity.path}');
            onProgress?.call(scannedCount, entity.path);

            final song = await _createSongFromFile(entity);
            if (song != null) {
              songs.add(song);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error during directory scan: $e');
      // Return what we've found so far
    }

    debugPrint('Scan complete. Found ${songs.length} songs');

    // Save scan history
    try {
      await _saveScanHistory(directoryPath, songs.length);
    } catch (e) {
      debugPrint('Error saving scan history: $e');
    }

    return songs;
  }

  /// Create a Song object from a file
  Future<Song?> _createSongFromFile(File file) async {
    try {
      final fileName = path.basenameWithoutExtension(file.path);
      final stat = await file.stat();
      
      // Parse filename for title and artist (common format: "Artist - Title")
      String title = fileName;
      String artist = 'Unknown Artist';
      
      if (fileName.contains(' - ')) {
        final parts = fileName.split(' - ');
        if (parts.length >= 2) {
          artist = parts[0].trim();
          title = parts.sublist(1).join(' - ').trim();
        }
      }

      // Try to get album from parent directory name
      String? album;
      try {
        final parentDir = path.basename(path.dirname(file.path));
        if (parentDir.isNotEmpty && parentDir != 'Music') {
          album = parentDir;
        }
      } catch (_) {}

      return Song(
        id: _uuid.v4(),
        title: title,
        artist: artist,
        album: album,
        duration: const Duration(minutes: 3), // Default, would need metadata extraction
        filePath: file.path,
        url: '', // Local file, no URL needed
        addedDate: stat.modified,
      );
    } catch (e) {
      debugPrint('Error creating song from file ${file.path}: $e');
      return null;
    }
  }

  /// Scan multiple directories
  Future<List<Song>> scanMultipleDirectories(
    List<String> directories, {
    Function(int totalScanned, String currentFile)? onProgress,
  }) async {
    final allSongs = <Song>[];
    int totalScanned = 0;

    for (final dir in directories) {
      try {
        final songs = await scanDirectory(
          dir,
          onProgress: (scanned, file) {
            totalScanned++;
            onProgress?.call(totalScanned, file);
          },
        );
        allSongs.addAll(songs);
      } catch (e) {
        debugPrint('Error scanning directory $dir: $e');
        // Continue with next directory
      }
    }

    return allSongs;
  }

  /// Get songs from previously scanned directories
  Future<List<Song>> getScannedSongs() async {
    await initialize();
    
    final history = _scanHistoryBox.get('last_scan');
    if (history == null) return [];

    final paths = (history['directories'] as List?)?.cast<String>() ?? [];
    if (paths.isEmpty) return [];

    return await scanMultipleDirectories(paths);
  }

  /// Save scan history
  Future<void> _saveScanHistory(String directory, int songCount) async {
    await initialize();
    
    final existing = _scanHistoryBox.get('last_scan') ?? {};
    final directories = (existing['directories'] as List?)?.cast<String>() ?? [];
    
    if (!directories.contains(directory)) {
      directories.add(directory);
    }

    await _scanHistoryBox.put('last_scan', {
      'directories': directories,
      'last_scan_time': DateTime.now().toIso8601String(),
      'total_songs': songCount,
    });
  }

  /// Get scan history
  Future<Map<String, dynamic>> getScanHistory() async {
    await initialize();
    
    final history = _scanHistoryBox.get('last_scan');
    if (history == null) {
      return {
        'directories': <String>[],
        'last_scan_time': null,
        'total_songs': 0,
      };
    }

    return Map<String, dynamic>.from(history);
  }

  /// Clear scan history
  Future<void> clearScanHistory() async {
    await initialize();
    await _scanHistoryBox.clear();
  }

  /// Check if a path is accessible
  Future<bool> isPathAccessible(String directoryPath) async {
    if (kIsWeb) return false;
    
    try {
      final directory = Directory(directoryPath);
      return await directory.exists();
    } catch (_) {
      return false;
    }
  }
}
