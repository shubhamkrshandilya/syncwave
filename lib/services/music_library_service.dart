import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/song.dart';
import 'file_storage_service.dart';

/// Platform-adaptive music library service
/// - Web: Stores files in IndexedDB (required by browser security)
/// - Mobile/Desktop: References local files directly (no upload)
class MusicLibraryService {
  final FileStorageService _fileStorageService;
  final _uuid = const Uuid();

  MusicLibraryService(this._fileStorageService);

  /// Add music files to library
  /// Returns list of songs and whether they were uploaded to storage
  Future<MusicImportResult> importMusicFiles({
    required Function(int current, int total, String filename) onProgress,
  }) async {
    try {
      // Pick audio files
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
        withData: kIsWeb, // Only load bytes on web (required)
      );

      if (result == null || result.files.isEmpty) {
        return MusicImportResult(songs: [], uploaded: false);
      }

      final songs = <Song>[];
      
      for (int i = 0; i < result.files.length; i++) {
        final file = result.files[i];
        onProgress(i + 1, result.files.length, file.name);

        final song = await _processFile(file);
        if (song != null) {
          songs.add(song);
        }
      }

      return MusicImportResult(
        songs: songs,
        uploaded: kIsWeb,
        totalSize: result.files.fold(0, (sum, f) => sum + f.size),
      );
    } catch (e) {
      debugPrint('Error importing music: $e');
      rethrow;
    }
  }

  /// Process a single file and extract metadata
  Future<Song?> _processFile(PlatformFile file) async {
    try {
      String title = _extractTitleFromFilename(file.name);
      String artist = 'Unknown Artist';
      String? album;
      Duration duration = const Duration(minutes: 3);

      // Try to extract metadata
      try {
        // On mobile/desktop, file.path is available
        // On web, file.path is null
        final filePath = file.path;
        
        // TODO: Metadata extraction disabled for now due to build issues
        // Re-enable when metadata_god is stable across all platforms
        /*
        if (filePath != null && !kIsWeb) {
          MetadataGod.initialize();
          final metadata = await MetadataGod.readMetadata(file: filePath);
          
          if (metadata.title != null && metadata.title!.isNotEmpty) {
            title = metadata.title!;
          }
          if (metadata.artist != null && metadata.artist!.isNotEmpty) {
            artist = metadata.artist!;
          }
          if (metadata.album != null) {
            album = metadata.album;
          }
          if (metadata.durationMs != null && metadata.durationMs! > 0) {
            duration = Duration(milliseconds: metadata.durationMs!.toInt());
          }
        }
        */
      } catch (e) {
        debugPrint('Could not read metadata for ${file.name}: $e');
      }

      final song = Song(
        id: _uuid.v4(),
        title: title,
        artist: artist,
        album: album,
        duration: duration,
        filePath: kIsWeb ? file.name : (file.path ?? file.name),
        url: '',
        addedDate: DateTime.now(),
      );

      // On web: Store file bytes in IndexedDB for persistence
      // On mobile/desktop: Just return the song with file path reference
      if (kIsWeb && file.bytes != null) {
        await _fileStorageService.saveFile(song.id, file.bytes!);
      }

      return song;
    } catch (e) {
      debugPrint('Error processing file ${file.name}: $e');
      return null;
    }
  }

  /// Extract title from filename
  String _extractTitleFromFilename(String filename) {
    final nameWithoutExt = filename.replaceAll(
      RegExp(r'\.(mp3|m4a|wav|ogg|flac|aac)$', caseSensitive: false),
      '',
    );
    return nameWithoutExt.replaceAll(RegExp(r'[_-]'), ' ').trim();
  }

  /// Get file bytes for playback
  /// - Web: Load from IndexedDB
  /// - Mobile/Desktop: Return null (play from file path directly)
  Uint8List? getFileBytes(String songId) {
    if (kIsWeb) {
      return _fileStorageService.getFile(songId);
    }
    return null; // Not needed on native platforms
  }

  /// Format bytes for display
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Result of music import operation
class MusicImportResult {
  final List<Song> songs;
  final bool uploaded; // true on web, false on native
  final int totalSize;

  MusicImportResult({
    required this.songs,
    required this.uploaded,
    this.totalSize = 0,
  });
}
