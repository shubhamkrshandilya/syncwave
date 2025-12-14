import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../models/song.dart';
import '../services/file_storage_service.dart';

class PlayerController extends ChangeNotifier {
  final FileStorageService _fileStorageService;
  
  Song? _currentSong;
  List<Song> _queue = [];
  bool _isPlaying = false;
  bool _isShuffle = false;
  bool _isRepeat = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  // Temporary cache for current session (fallback)
  final Map<String, Uint8List> _fileBytesCache = {};

  PlayerController(this._fileStorageService);

  // Getters
  Song? get currentSong => _currentSong;
  List<Song> get queue => _queue;
  bool get isPlaying => _isPlaying;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  
  double get progress {
    if (_totalDuration.inMilliseconds == 0) return 0.0;
    return _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
  }
  
  // Get file bytes for a song
  Uint8List? getFileBytes(String songId) {
    // Try memory cache first (fastest)
    if (_fileBytesCache.containsKey(songId)) {
      return _fileBytesCache[songId];
    }
    
    // Try IndexedDB storage (persistent)
    final bytes = _fileStorageService.getFile(songId);
    if (bytes != null) {
      // Cache in memory for faster subsequent access
      _fileBytesCache[songId] = bytes;
    }
    
    return bytes;
  }

  // Play a song
  void playSong(Song song) {
    _currentSong = song;
    _isPlaying = true;
    notifyListeners();
  }

  // Toggle play/pause
  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  // Play next song
  void playNext() {
    if (_queue.isEmpty) return;
    
    if (_currentSong != null) {
      final currentIndex = _queue.indexWhere((s) => s.id == _currentSong!.id);
      if (currentIndex != -1 && currentIndex < _queue.length - 1) {
        _currentSong = _queue[currentIndex + 1];
        _isPlaying = true;
        notifyListeners();
      }
    }
  }

  // Play previous song
  void playPrevious() {
    if (_queue.isEmpty) return;
    
    if (_currentSong != null) {
      final currentIndex = _queue.indexWhere((s) => s.id == _currentSong!.id);
      if (currentIndex > 0) {
        _currentSong = _queue[currentIndex - 1];
        _isPlaying = true;
        notifyListeners();
      }
    }
  }

  // Toggle shuffle
  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  // Toggle repeat
  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    notifyListeners();
  }

  // Seek to position
  void seekTo(Duration position) {
    _currentPosition = position;
    notifyListeners();
  }

  // Update position
  void updatePosition(Duration position) {
    _currentPosition = position;
    notifyListeners();
  }

  // Update duration
  void updateDuration(Duration duration) {
    _totalDuration = duration;
    notifyListeners();
  }

  // Set queue
  void setQueue(List<Song> songs, {int startIndex = 0}) {
    _queue = songs;
    if (songs.isNotEmpty && startIndex < songs.length) {
      playSong(songs[startIndex]);
    }
  }

  // Add to queue
  void addToQueue(Song song) {
    _queue.add(song);
    notifyListeners();
  }
  
  // Remove from queue
  void removeFromQueue(String songId) {
    _queue.removeWhere((song) => song.id == songId);
    
    // If current song was removed, stop playing
    if (_currentSong?.id == songId) {
      if (_queue.isNotEmpty) {
        _currentSong = _queue.first;
      } else {
        _currentSong = null;
        _isPlaying = false;
      }
    }
    
    // Clean up file bytes
    deleteSongFile(songId);
    notifyListeners();
  }
  
  // Add song with file bytes (for web)
  void addSongWithBytes(Song song, Uint8List bytes) async {
    // Store in both memory cache and persistent storage
    _fileBytesCache[song.id] = bytes;
    await _fileStorageService.saveFile(song.id, bytes);
    _queue.add(song);
    notifyListeners();
  }
  
  // Play at specific index
  void playAtIndex(int index) {
    if (index >= 0 && index < _queue.length) {
      playSong(_queue[index]);
    }
  }

  // Clear queue
  void clearQueue() async {
    _queue.clear();
    _currentSong = null;
    _isPlaying = false;
    _fileBytesCache.clear();
    // Optionally clear persistent storage (commented out to keep files)
    // await _fileStorageService.clearAll();
    notifyListeners();
  }
  
  // Get storage info
  String getStorageInfo() {
    return _fileStorageService.getStorageInfo();
  }
  
  // Delete a song's file bytes
  Future<void> deleteSongFile(String songId) async {
    _fileBytesCache.remove(songId);
    await _fileStorageService.deleteFile(songId);
    notifyListeners();
  }
}
