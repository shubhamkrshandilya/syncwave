import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:typed_data';
import '../models/song.dart';
import 'audio_handler.dart';

class AudioService extends ChangeNotifier {
  final SyncWaveAudioHandler _audioHandler;
  AudioPlayer get _audioPlayer => _audioHandler.audioPlayer;
  
  Song? _currentSong;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Function()? onSongComplete;

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  SyncWaveAudioHandler get audioHandler => _audioHandler;
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;

  AudioService(this._audioHandler) {
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    // Configure audio player for production
    _audioPlayer.setVolume(1.0);
    
    // Set buffer duration for smooth playback
    // Larger buffer = less stuttering, more memory
    // Production: 10-20 seconds is optimal
    
    // Listen to player state
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      
      // Check if song completed
      if (state.processingState == ProcessingState.completed) {
        debugPrint('Song completed, triggering next song');
        onSongComplete?.call();
      }
      
      notifyListeners();
    });
    
    // Listen for errors and auto-retry
    _audioPlayer.playbackEventStream.listen(
      (event) {},
      onError: (Object e, StackTrace st) async {
        debugPrint('Playback error: $e');
        // Auto-retry on network errors
        if (e.toString().contains('network') || e.toString().contains('connection')) {
          debugPrint('Network error detected, retrying in 2s...');
          await Future.delayed(const Duration(seconds: 2));
          if (_currentSong != null) {
            try {
              await _audioPlayer.play();
            } catch (retryError) {
              debugPrint('Retry failed: $retryError');
            }
          }
        }
      },
    );

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        _duration = duration;
        notifyListeners();
      }
    });
  }

  // Play a song
  Future<void> playSong(Song song, {Uint8List? fileBytes}) async {
    try {
      // Stop current playback first
      await _audioPlayer.stop();
      
      _currentSong = song;
      
      // Create media item for notifications
      final mediaItem = MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        duration: song.duration,
      );
      
      // Priority: filePath (direct access) > fileBytes (web cached) > URL
      if (song.filePath.isNotEmpty && !song.filePath.startsWith('http')) {
        await _audioHandler.playFromFilePath(song.filePath, mediaItem);
      } else if (fileBytes != null) {
        // For web/bytes, set media item and play
        _audioHandler.mediaItem.add(mediaItem);
        await _audioPlayer.setAudioSource(_BytesAudioSource(fileBytes));
        await _audioPlayer.play();
      } else if (song.url != null && song.url!.isNotEmpty) {
        _audioHandler.mediaItem.add(mediaItem);
        await _audioPlayer.setUrl(song.url!);
        await _audioPlayer.play();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing song: $e');
    }
  }



  // Play/Pause
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _audioHandler.pause();
    } else {
      await _audioHandler.play();
    }
  }

  // Stop
  Future<void> stop() async {
    await _audioHandler.stop();
    _currentSong = null;
    notifyListeners();
  }

  // Seek
  Future<void> seek(Duration position) async {
    await _audioHandler.seek(position);
  }

  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

// Custom audio source for playing from bytes
class _BytesAudioSource extends StreamAudioSource {
  final Uint8List _bytes;

  _BytesAudioSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;

    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
