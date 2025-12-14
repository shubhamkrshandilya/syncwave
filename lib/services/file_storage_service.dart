import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service to persist audio file bytes in IndexedDB for web platform
/// This allows uploaded music files to survive browser restarts
class FileStorageService {
  static const String _boxName = 'audio_files';
  Box<Uint8List>? _box;
  
  // Production: Limit cache to 500MB (configurable)
  static const int maxCacheSizeBytes = 500 * 1024 * 1024; // 500MB
  static const int maxFileSizeBytes = 50 * 1024 * 1024;   // 50MB per file

  /// Initialize the storage service
  Future<void> init() async {
    try {
      _box = await Hive.openBox<Uint8List>(_boxName);
      debugPrint('FileStorageService initialized with ${_box?.length ?? 0} cached files');
    } catch (e) {
      debugPrint('Error initializing FileStorageService: $e');
    }
  }

  /// Save file bytes to storage
  Future<void> saveFile(String songId, Uint8List bytes) async {
    try {
      // Validate file size
      if (bytes.length > maxFileSizeBytes) {
        debugPrint('Warning: File too large (${(bytes.length / 1024 / 1024).toStringAsFixed(1)}MB), skipping cache');
        return;
      }
      
      // Check total cache size and clean if needed
      final currentSize = getTotalSize();
      if (currentSize + bytes.length > maxCacheSizeBytes) {
        debugPrint('Cache full, cleaning oldest entries...');
        await _cleanOldestEntries(bytes.length);
      }
      
      await _box?.put(songId, bytes);
      debugPrint('Saved file for song: $songId (${bytes.length} bytes)');
    } catch (e) {
      debugPrint('Error saving file for $songId: $e');
    }
  }
  
  /// Remove oldest entries to make space
  Future<void> _cleanOldestEntries(int neededSpace) async {
    if (_box == null) return;
    
    final keys = _box!.keys.toList();
    int freedSpace = 0;
    
    // Remove oldest 25% of files
    final toRemove = (keys.length * 0.25).ceil();
    for (int i = 0; i < toRemove && freedSpace < neededSpace; i++) {
      final bytes = _box!.get(keys[i]);
      if (bytes != null) {
        freedSpace += bytes.length;
        await _box!.delete(keys[i]);
      }
    }
    
    debugPrint('Freed ${(freedSpace / 1024 / 1024).toStringAsFixed(1)}MB');
  }
  
  /// Get total size of all cached files
  int getTotalSize() {
    if (_box == null) return 0;
    int total = 0;
    for (var bytes in _box!.values) {
      total += bytes.length;
    }
    return total;
  }

  /// Get file bytes from storage
  Uint8List? getFile(String songId) {
    try {
      return _box?.get(songId);
    } catch (e) {
      debugPrint('Error getting file for $songId: $e');
      return null;
    }
  }

  /// Check if file exists in storage
  bool hasFile(String songId) {
    return _box?.containsKey(songId) ?? false;
  }

  /// Delete a file from storage
  Future<void> deleteFile(String songId) async {
    try {
      await _box?.delete(songId);
      debugPrint('Deleted file for song: $songId');
    } catch (e) {
      debugPrint('Error deleting file for $songId: $e');
    }
  }

  /// Clear all stored files
  Future<void> clearAll() async {
    try {
      await _box?.clear();
      debugPrint('Cleared all stored files');
    } catch (e) {
      debugPrint('Error clearing files: $e');
    }
  }

  /// Get total number of stored files
  int get fileCount => _box?.length ?? 0;

  /// Get approximate total size of stored files in bytes
  int get totalSize {
    int total = 0;
    try {
      _box?.values.forEach((bytes) {
        total += bytes.length;
      });
    } catch (e) {
      debugPrint('Error calculating total size: $e');
    }
    return total;
  }

  /// Get storage info as human-readable string
  String getStorageInfo() {
    final count = fileCount;
    final size = totalSize;
    final sizeMB = (size / (1024 * 1024)).toStringAsFixed(2);
    return '$count files ($sizeMB MB)';
  }

  /// Dispose the service
  Future<void> dispose() async {
    await _box?.close();
  }
}
