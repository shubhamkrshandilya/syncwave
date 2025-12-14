import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class SyncWaveAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  Function()? onPlayNext;
  Function()? onPlayPrevious;

  SyncWaveAudioHandler() {
    _init();
  }

  void _init() {
    // Initialize playback state with controls enabled
    playbackState.add(PlaybackState(
      playing: false,
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      processingState: AudioProcessingState.idle,
      updatePosition: Duration.zero,
    ));
    
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      final controls = state.playing
          ? [
              MediaControl.skipToPrevious,
              MediaControl.pause,
              MediaControl.skipToNext,
            ]
          : [
              MediaControl.skipToPrevious,
              MediaControl.play,
              MediaControl.skipToNext,
            ];
      
      playbackState.add(playbackState.value.copyWith(
        playing: state.playing,
        controls: controls,
        processingState: _mapProcessingState(state.processingState),
      ));
      
      // Trigger next song when current completes
      if (state.processingState == ProcessingState.completed) {
        onPlayNext?.call();
      }
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        mediaItem.add(mediaItem.value?.copyWith(duration: duration));
      }
    });
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  Future<void> playFromFilePath(String filePath, MediaItem media) async {
    try {
      mediaItem.add(media);
      
      final fileUrl = filePath.startsWith('file://') 
          ? filePath 
          : 'file://$filePath';
      
      await _audioPlayer.setUrl(fileUrl);
      await _audioPlayer.play();
      
      playbackState.add(playbackState.value.copyWith(
        playing: true,
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.pause,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
      ));
    } catch (e) {
      debugPrint('Error in playFromFilePath: $e');
    }
  }

  @override
  Future<void> play() async {
    await _audioPlayer.play();
    playbackState.add(playbackState.value.copyWith(
      playing: true,
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.skipToNext,
      ],
    ));
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
      ],
    ));
  }

  @override
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    onPlayNext?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    onPlayPrevious?.call();
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
    await _audioPlayer.dispose();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
    await super.stop();
  }

  AudioPlayer get audioPlayer => _audioPlayer;
}
