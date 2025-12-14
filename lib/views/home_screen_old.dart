import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../config/app_theme.dart';
import '../config/app_constants.dart';
import '../controllers/player_controller.dart';
import '../services/audio_service.dart';
import '../services/music_library_service.dart';
import '../services/local_server_service.dart';
import '../models/song.dart';
import '../widgets/music_player_card.dart';
import '../widgets/player_controls.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocalServerService _localServer = LocalServerService();
  bool _isServerConnected = false;
  bool _isCheckingServer = false;

  @override
  void initState() {
    super.initState();
    // Load demo songs after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDemoSongs();
      _checkLocalServer();
    });
  }

  Future<void> _checkLocalServer() async {
    setState(() => _isCheckingServer = true);
    final connected = await _localServer.checkConnection();
    if (mounted) {
      setState(() {
        _isServerConnected = connected;
        _isCheckingServer = false;
      });
    }
  }

  void _loadDemoSongs() {
    // Load some demo songs for testing
    final playerController = context.read<PlayerController>();
    
    final demoSongs = [
      Song(
        id: '1',
        title: 'Sample Song 1',
        artist: 'Artist 1',
        album: 'Album 1',
        duration: const Duration(minutes: 3, seconds: 45),
        filePath: '',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        addedDate: DateTime.now(),
      ),
      Song(
        id: '2',
        title: 'Sample Song 2',
        artist: 'Artist 2',
        album: 'Album 2',
        duration: const Duration(minutes: 4, seconds: 12),
        filePath: '',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        addedDate: DateTime.now(),
      ),
      Song(
        id: '3',
        title: 'Sample Song 3',
        artist: 'Artist 3',
        album: 'Album 3',
        duration: const Duration(minutes: 3, seconds: 30),
        filePath: '',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        addedDate: DateTime.now(),
      ),
    ];

    playerController.setQueue(demoSongs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
              child: const Icon(
                Icons.graphic_eq,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Text(AppConstants.appName),
          ],
        ),
        actions: [
          // Local server status
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isServerConnected ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isServerConnected ? Colors.green : Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isServerConnected ? Icons.check_circle : Icons.cloud_off,
                        size: 16,
                        color: _isServerConnected ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isServerConnected ? 'Server' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isServerConnected ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Storage info badge
          Consumer<PlayerController>(
            builder: (context, controller, child) {
              final storageInfo = controller.getStorageInfo();
              if (storageInfo.startsWith('0 files')) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  avatar: const Icon(Icons.storage, size: 16, color: AppTheme.accentColor),
                  label: Text(
                    storageInfo,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: AppTheme.cardColor,
                  visualDensity: VisualDensity.compact,
                ),
              );
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.upload_file, size: 20),
            ),
            onPressed: _handleFileUpload,
            tooltip: 'Upload Music from Your Computer\n(Supports MP3, M4A, WAV, OGG, FLAC)',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: Consumer2<PlayerController, AudioService>(
        builder: (context, playerController, audioService, child) {
          final currentSong = playerController.currentSong;

          return Column(
            children: [
              // Main Player Card
              Expanded(
                child: currentSong != null
                    ? MusicPlayerCard(song: currentSong)
                    : _buildEmptyState(),
              ),

              // Queue Preview
              if (playerController.queue.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Up Next',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          _showQueueBottomSheet(context);
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: playerController.queue.length,
                    itemBuilder: (context, index) {
                      final song = playerController.queue[index];
                      final isCurrentSong = song.id == currentSong?.id;
                      
                      return _buildQueueItem(song, isCurrentSong, () {
                        playerController.playSong(song);
                        final fileBytes = playerController.getFileBytes(song.id);
                        audioService.playSong(song, fileBytes: fileBytes);
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Player Controls
              PlayerControls(
                onPlayPause: () {
                  playerController.togglePlayPause();
                  audioService.togglePlayPause();
                },
                onNext: () {
                  playerController.playNext();
                  if (playerController.currentSong != null) {
                    final fileBytes = playerController.getFileBytes(playerController.currentSong!.id);
                    audioService.playSong(playerController.currentSong!, fileBytes: fileBytes);
                  }
                },
                onPrevious: () {
                  playerController.playPrevious();
                  if (playerController.currentSong != null) {
                    final fileBytes = playerController.getFileBytes(playerController.currentSong!.id);
                    audioService.playSong(playerController.currentSong!, fileBytes: fileBytes);
                  }
                },
                onShuffle: playerController.toggleShuffle,
                onRepeat: playerController.toggleRepeat,
                isPlaying: playerController.isPlaying,
                isShuffle: playerController.isShuffle,
                isRepeat: playerController.isRepeat,
                position: audioService.position,
                duration: audioService.duration,
                onSeek: (position) {
                  audioService.seek(position);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
            child: const Icon(
              Icons.music_note,
              size: 100,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No music playing',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Upload songs or select from your playlists',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          if (kIsWeb && _isServerConnected) ...[
            ElevatedButton.icon(
              onPressed: _isCheckingServer ? null : _loadFromLocalServer,
              icon: _isCheckingServer
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.folder_open),
              label: const Text('Load from Local Server'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'or',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
          ],
          ElevatedButton.icon(
            onPressed: _handleFileUpload,
            icon: const Icon(Icons.upload_file),
            label: Text(kIsWeb && _isServerConnected ? 'Upload Files' : 'Upload Music'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kIsWeb && _isServerConnected ? AppTheme.cardColor : null,
            ),
          ),
          if (kIsWeb && !_isServerConnected) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(height: 8),
                  Text(
                    'Start local server to access your music library without uploading',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _checkLocalServer,
                    child: const Text('Check Connection'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQueueItem(Song song, bool isCurrentSong, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isCurrentSong ? AppTheme.primaryColor : AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrentSong
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                isCurrentSong ? Icons.play_circle_filled : Icons.music_note,
                color: isCurrentSong ? Colors.white : AppTheme.textSecondary,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQueueBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<PlayerController>(
          builder: (context, controller, child) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Queue (${controller.queue.length})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: controller.queue.length,
                    itemBuilder: (context, index) {
                      final song = controller.queue[index];
                      final isCurrentSong = song.id == controller.currentSong?.id;
                      
                      return ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isCurrentSong
                                ? AppTheme.primaryColor
                                : AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isCurrentSong ? Icons.play_circle_filled : Icons.music_note,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          song.title,
                          style: TextStyle(
                            fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
                            color: isCurrentSong ? AppTheme.primaryColor : null,
                          ),
                        ),
                        subtitle: Text(song.artist),
                        trailing: Text(
                          _formatDuration(song.duration),
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        onTap: () {
                          controller.playSong(song);
                          context.read<AudioService>().playSong(song);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _loadFromLocalServer() async {
    setState(() => _isCheckingServer = true);
    
    try {
      final songs = await _localServer.getLibrary();
      
      if (!mounted) return;
      
      if (songs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No songs found in local library. Make sure the server is scanning your Music folder.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      final playerController = context.read<PlayerController>();
      
      // Add songs to queue
      for (var song in songs) {
        playerController.addToQueue(song);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Loaded ${songs.length} song${songs.length != 1 ? 's' : ''} from local library'),
          backgroundColor: AppTheme.accentColor,
          action: SnackBarAction(
            label: 'PLAY',
            textColor: Colors.white,
            onPressed: () {
              if (playerController.queue.isNotEmpty) {
                playerController.playAtIndex(0);
                final audioService = context.read<AudioService>();
                audioService.playSong(playerController.queue[0]);
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading from server: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCheckingServer = false);
      }
    }
  }

  Future<void> _handleFileUpload() async {
    try {
      final musicLibrary = context.read<MusicLibraryService>();
      final playerController = context.read<PlayerController>();
      
      int currentFile = 0;
      int totalFiles = 0;
      
      // Import music files with platform-adaptive behavior
      final result = await musicLibrary.importMusicFiles(
        onProgress: (current, total, filename) {
          currentFile = current;
          totalFiles = total;
          
          if (mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$current/$total: ${filename.length > 30 ? '${filename.substring(0, 30)}...' : filename}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(hours: 1),
                ),
              );
          }
        },
      );

      if (result.songs.isEmpty) return;

      // Add songs to queue
      for (var song in result.songs) {
        playerController.addToQueue(song);
      }

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // Show different message based on platform
      final message = kIsWeb
          ? '✓ Saved ${result.songs.length} song${result.songs.length != 1 ? 's' : ''} to library\n${MusicLibraryService.formatBytes(result.totalSize)}'
          : '✓ Added ${result.songs.length} song${result.songs.length != 1 ? 's' : ''} from local files';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.accentColor,
          action: SnackBarAction(
            label: 'PLAY',
            textColor: Colors.white,
            onPressed: () {
              if (playerController.queue.isNotEmpty) {
                playerController.playAtIndex(playerController.queue.length - result.songs.length);
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading files: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _extractTitle(String filename) {
    // Remove file extension
    final nameWithoutExt = filename.replaceAll(RegExp(r'\.(mp3|m4a|wav|ogg|flac)$', caseSensitive: false), '');
    // Replace underscores and dashes with spaces
    return nameWithoutExt.replaceAll(RegExp(r'[_-]'), ' ').trim();
  }
}
