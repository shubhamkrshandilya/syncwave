import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import '../config/app_theme.dart';
import '../config/app_constants.dart';
import '../controllers/player_controller.dart';
import '../services/audio_service.dart';
import '../services/music_library_service.dart';
import '../services/local_server_service.dart';
import '../services/local_music_scanner.dart';
import '../models/song.dart';
import '../widgets/music_player_card.dart';
import '../widgets/player_controls.dart';
import 'library_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final LocalServerService _localServer = LocalServerService();
  final LocalMusicScanner _scanner = LocalMusicScanner();
  final GlobalKey<ScaffoldState> _mediumScaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _compactScaffoldKey = GlobalKey<ScaffoldState>();
  bool _isServerConnected = false;
  bool _isCheckingServer = false;
  bool _isScanning = false;
  int _songsFound = 0;
  bool _isQueueExpanded = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocalServer();
      _setupAudioCallbacks();
    });
  }
  
  void _setupAudioCallbacks() {
    final audioService = Provider.of<AudioService>(context, listen: false);
    final controller = Provider.of<PlayerController>(context, listen: false);
    
    // Setup auto-play next song when current song completes
    audioService.onSongComplete = () {
      debugPrint('Song completed, playing next...');
      controller.playNext();
      if (controller.currentSong != null) {
        final fileBytes = controller.getFileBytes(controller.currentSong!.id);
        audioService.playSong(controller.currentSong!, fileBytes: fileBytes);
      }
    };
    
    // Setup notification controls for next/previous
    try {
      final handler = audioService.audioHandler;
      if (handler != null) {
        handler.onPlayNext = () {
          controller.playNext();
          if (controller.currentSong != null) {
            final fileBytes = controller.getFileBytes(controller.currentSong!.id);
            audioService.playSong(controller.currentSong!, fileBytes: fileBytes);
          }
        };
        
        handler.onPlayPrevious = () {
          controller.playPrevious();
          if (controller.currentSong != null) {
            final fileBytes = controller.getFileBytes(controller.currentSong!.id);
            audioService.playSong(controller.currentSong!, fileBytes: fileBytes);
          }
        };
      }
    } catch (e) {
      debugPrint('Could not set up notification controls: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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





  Future<void> _addMusicFolder() async {
    try {
      // Request storage permissions on Android
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        // Check Android version
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        
        PermissionStatus status;
        
        if (androidInfo.version.sdkInt >= 33) {
          // Android 13+ (API 33+) - Request audio permission
          status = await Permission.audio.request();
        } else if (androidInfo.version.sdkInt >= 30) {
          // Android 11-12 (API 30-32) - Request manage external storage
          status = await Permission.manageExternalStorage.request();
        } else {
          // Android 10 and below - Request read external storage
          status = await Permission.storage.request();
        }
        
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Storage permission is required to access music files'),
                backgroundColor: AppTheme.errorColor,
                action: SnackBarAction(
                  label: 'SETTINGS',
                  textColor: Colors.white,
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          }
          return;
        }
        
        // Warn about Android limitations
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceColor,
            title: Text('Note', style: TextStyle(color: AppTheme.textPrimary)),
            content: Text(
              'Folder scanning may be slow on Android due to system restrictions.\n\nFor better performance, use "Add Music Files" to select files directly.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Use Files Instead'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
        
        if (proceed != true) {
          if (mounted) {
            await _addMusicFiles();
          }
          return;
        }
      }
      
      // Use directory picker for all platforms
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      
      if (selectedDirectory == null) return;
      
      if (!mounted) return;
      
      setState(() {
        _isScanning = true;
        _songsFound = 0;
      });

      final playerController = context.read<PlayerController>();
      
      final songs = await _scanner.scanDirectory(
        selectedDirectory,
        onProgress: (scanned, file) {
          if (mounted) {
            setState(() => _songsFound = scanned);
          }
        },
      );

      if (!mounted) return;

      setState(() => _isScanning = false);

      for (var song in songs) {
        playerController.addToQueue(song);
      }

      if (songs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Found ${songs.length} songs in selected folder'),
            backgroundColor: AppTheme.successColor,
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LibraryScreen()),
                );
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No music files found in selected folder'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _addMusicFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'flac', 'aac', 'ogg', 'wma', 'opus'],
        allowMultiple: true,
        dialogTitle: 'Select Music Files',
      );
      
      if (result == null || result.files.isEmpty) return;
      
      if (!mounted) return;
      
      setState(() {
        _isScanning = true;
        _songsFound = 0;
      });

      final playerController = context.read<PlayerController>();
      final songs = <Song>[];
      
      for (var file in result.files) {
        if (file.path != null) {
          final song = Song(
            id: const Uuid().v4(),
            title: file.name.replaceAll(RegExp(r'\.[^.]+$'), ''),
            artist: 'Unknown Artist',
            album: 'Unknown Album',
            duration: const Duration(minutes: 3),
            filePath: file.path!,
            addedDate: DateTime.now(),
          );
          songs.add(song);
          playerController.addToQueue(song);
          
          if (mounted) {
            setState(() => _songsFound = songs.length);
          }
        }
      }

      if (!mounted) return;

      setState(() => _isScanning = false);

      if (songs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Added ${songs.length} songs to queue'),
            backgroundColor: AppTheme.successColor,
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LibraryScreen()),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;
    final isMedium = size.width > 600 && size.width <= 900;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.backgroundColor.withBlue(20),
              AppTheme.backgroundColor.withRed(15),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer2<PlayerController, AudioService>(
            builder: (context, playerController, audioService, child) {
              final currentSong = playerController.currentSong;
              
              if (isWide) {
                return _buildWideLayout(playerController, audioService, currentSong);
              } else if (isMedium) {
                return _buildMediumLayout(playerController, audioService, currentSong);
              } else {
                return _buildCompactLayout(playerController, audioService, currentSong);
              }
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor.withOpacity(0.9),
              AppTheme.backgroundColor.withOpacity(0),
            ],
          ),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.glowShadow,
            ),
            child: const Icon(Icons.music_note, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 12),
          ShaderMask(
            shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
            child: Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.library_music),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LibraryScreen(),
              ),
            );
          },
          tooltip: 'Music Library',
        ),
        if (kIsWeb) _buildServerStatusBadge(),
        const SizedBox(width: 8),
        Consumer<PlayerController>(
          builder: (context, controller, _) {
            final storageInfo = controller.getStorageInfo();
            if (storageInfo.startsWith('0 files')) return const SizedBox.shrink();
            
            return Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.cardColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storage, size: 14, color: AppTheme.secondaryColor),
                  const SizedBox(width: 6),
                  Text(
                    storageInfo,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildServerStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: _isServerConnected
            ? LinearGradient(colors: [AppTheme.successColor, AppTheme.successColor.withOpacity(0.8)])
            : null,
        color: _isServerConnected ? null : AppTheme.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isServerConnected 
              ? AppTheme.successColor 
              : AppTheme.textTertiary,
          width: 1.5,
        ),
        boxShadow: _isServerConnected ? [
          BoxShadow(
            color: AppTheme.successColor.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isServerConnected ? Colors.white : AppTheme.textTertiary,
              boxShadow: _isServerConnected ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ] : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isServerConnected ? 'Server' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              color: _isServerConnected ? Colors.white : AppTheme.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(PlayerController controller, AudioService audioService, Song? currentSong) {
    return Row(
      children: [
        // Left sidebar - Queue (collapsible)
        if (_isQueueExpanded)
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withOpacity(0.5),
              border: Border(right: BorderSide(color: AppTheme.cardColor.withOpacity(0.3))),
            ),
            child: _buildQueueSection(controller, audioService),
          ),
        // Collapse/Expand button
        Container(
          width: 40,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withOpacity(0.5),
            border: Border(right: BorderSide(color: AppTheme.cardColor.withOpacity(0.3))),
          ),
          child: Center(
            child: IconButton(
              icon: Icon(
                _isQueueExpanded ? Icons.chevron_left : Icons.chevron_right,
                color: AppTheme.primaryColor,
              ),
              onPressed: () {
                setState(() {
                  _isQueueExpanded = !_isQueueExpanded;
                });
              },
              tooltip: _isQueueExpanded ? 'Hide Queue' : 'Show Queue',
            ),
          ),
        ),
        // Main content
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: currentSong != null
                    ? _buildPlayerSection(controller, audioService, currentSong)
                    : _buildEmptyState(),
              ),
              _buildPlayerControls(controller, audioService),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediumLayout(PlayerController controller, AudioService audioService, Song? currentSong) {
    return Scaffold(
      key: _mediumScaffoldKey,
      endDrawer: Drawer(
        backgroundColor: AppTheme.surfaceColor,
        child: _buildQueueSection(controller, audioService),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox.shrink(),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Badge(
                label: Text('${controller.queue.length}'),
                child: Icon(Icons.queue_music, color: AppTheme.primaryColor),
              ),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: currentSong != null
                ? _buildPlayerSection(controller, audioService, currentSong)
                : _buildEmptyState(),
          ),
          _buildPlayerControls(controller, audioService),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(PlayerController controller, AudioService audioService, Song? currentSong) {
    return Scaffold(
      key: _compactScaffoldKey,
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundColor,
      endDrawer: Drawer(
        backgroundColor: AppTheme.surfaceColor,
        width: MediaQuery.of(context).size.width * 0.85,
        child: _buildQueueSection(controller, audioService),
      ),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor.withOpacity(0.95),
        elevation: 0,
        leading: const SizedBox.shrink(),
        toolbarHeight: 64,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.backgroundColor.withOpacity(0.95),
                AppTheme.backgroundColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
        actions: [
          Builder(
            builder: (context) => Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Badge(
                    label: Text('${controller.queue.length}', style: const TextStyle(fontSize: 10)),
                    child: const Icon(Icons.queue_music, color: Colors.white, size: 20),
                  ),
                ),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.surfaceColor.withOpacity(0.5),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: currentSong != null
                    ? _buildPlayerSection(controller, audioService, currentSong)
                    : _buildEmptyState(),
              ),
              _buildPlayerControls(controller, audioService),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerSection(PlayerController controller, AudioService audioService, Song currentSong) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Album Art
                Hero(
                  tag: 'album_art_${currentSong.id}',
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = (MediaQuery.of(context).size.width * 0.75).clamp(280.0, 360.0);
                      return Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: AppTheme.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.5),
                              blurRadius: 50,
                              spreadRadius: -5,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: AppTheme.accentColor.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: -10,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.glassGradient,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.music_note,
                                  size: size * 0.4,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: size * 0.3,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.3),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                
                // Song Info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        currentSong.title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          letterSpacing: 0.5,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      ShaderMask(
                        shaderCallback: (bounds) => AppTheme.accentGradient.createShader(bounds),
                        child: Text(
                          currentSong.artist,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (currentSong.album != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          currentSong.album!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textTertiary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQueueSection(PlayerController controller, AudioService audioService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withOpacity(0.1),
                AppTheme.accentColor.withOpacity(0.05),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.cardColor.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.queue_music, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Queue',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  '${controller.queue.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: controller.queue.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.primaryGradient.scale(0.3),
                        ),
                        child: Icon(
                          Icons.queue_music,
                          size: 48,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Queue is empty',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: controller.queue.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemBuilder: (context, index) {
                    final song = controller.queue[index];
                    final isPlaying = song.id == controller.currentSong?.id;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: isPlaying ? AppTheme.primaryGradient : null,
                        color: isPlaying ? null : AppTheme.cardColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isPlaying 
                              ? Colors.transparent 
                              : AppTheme.cardColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: isPlaying ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ] : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            controller.playSong(song);
                            final fileBytes = controller.getFileBytes(song.id);
                            audioService.playSong(song, fileBytes: fileBytes);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isPlaying 
                                        ? Colors.white.withOpacity(0.2) 
                                        : AppTheme.surfaceColor,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: isPlaying ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        spreadRadius: 0,
                                      ),
                                    ] : null,
                                  ),
                                  child: Icon(
                                    isPlaying ? Icons.play_circle_filled : Icons.music_note,
                                    color: isPlaying ? Colors.white : AppTheme.primaryColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song.title,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w500,
                                          color: isPlaying ? Colors.white : AppTheme.textPrimary,
                                          letterSpacing: 0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        song.artist,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isPlaying 
                                              ? Colors.white.withOpacity(0.8) 
                                              : AppTheme.textSecondary,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      controller.removeFromQueue(song.id);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'Removed "${song.title}"',
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              ),
                                            ],
                                          ),
                                          duration: const Duration(seconds: 2),
                                          backgroundColor: AppTheme.surfaceColor,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.remove_circle_outline,
                                        color: isPlaying 
                                            ? Colors.white.withOpacity(0.8) 
                                            : AppTheme.textSecondary,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPlayerControls(PlayerController controller, AudioService audioService) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.surfaceColor.withOpacity(0),
            AppTheme.surfaceColor.withOpacity(0.95),
          ],
        ),
      ),
      child: PlayerControls(
        onPlayPause: () {
          controller.togglePlayPause();
          audioService.togglePlayPause();
        },
        onNext: () {
          controller.playNext();
          if (controller.currentSong != null) {
            final fileBytes = controller.getFileBytes(controller.currentSong!.id);
            audioService.playSong(controller.currentSong!, fileBytes: fileBytes);
          }
        },
        onPrevious: () {
          controller.playPrevious();
          if (controller.currentSong != null) {
            final fileBytes = controller.getFileBytes(controller.currentSong!.id);
            audioService.playSong(controller.currentSong!, fileBytes: fileBytes);
          }
        },
        onShuffle: controller.toggleShuffle,
        onRepeat: controller.toggleRepeat,
        isPlaying: controller.isPlaying,
        isShuffle: controller.isShuffle,
        isRepeat: controller.isRepeat,
        position: audioService.position,
        duration: audioService.duration,
        onSeek: (position) {
          audioService.seek(position);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                    boxShadow: AppTheme.glowShadow,
                  ),
                  child: Icon(
                    Icons.music_note,
                    size: 80,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 32),
                ShaderMask(
                  shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                  child: Text(
                    _isScanning ? 'Scanning your music...' : 'No music playing',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isScanning 
                      ? 'Found $_songsFound songs so far...'
                      : (kIsWeb 
                          ? 'Upload songs or load from your library'
                          : (defaultTargetPlatform == TargetPlatform.iOS 
                              ? 'Select music files from Files app to get started'
                              : 'Upload songs or load from your library')),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_isScanning) ...[
                  const SizedBox(height: 24),
                  CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                ],
                const SizedBox(height: 40),
                
                if (!kIsWeb) ...[
                  // On iOS, must use file picker (folder access not permitted by iOS)
                  if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                    _buildGlassButton(
                      onPressed: _addMusicFiles,
                      icon: Icons.audio_file,
                      label: 'Select All Music Files',
                      gradient: AppTheme.primaryGradient,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.touch_app,
                              color: AppTheme.accentColor,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'How to select all songs:',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '1. Tap button above\n2. Tap "Browse" → find music folder\n3. Tap "Select" (top-right corner)\n4. Tap first file, then drag down\n   OR use "Select All" if available\n5. Tap "Open" to import all',
                              style: TextStyle(
                                color: AppTheme.textTertiary,
                                fontSize: 12,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Android and macOS: show both folder and file pickers
                    _buildGlassButton(
                      onPressed: _addMusicFolder,
                      icon: Icons.folder_open,
                      label: 'Add Music Folder',
                      gradient: AppTheme.primaryGradient,
                    ),
                    const SizedBox(height: 16),
                    _buildGlassButton(
                      onPressed: _addMusicFiles,
                      icon: Icons.audio_file,
                      label: 'Add Music Files',
                      gradient: AppTheme.accentGradient,
                    ),
                  ],
                ],
                
                if (kIsWeb && _isServerConnected) ...[
                  const SizedBox(height: 40),
                  _buildGlassButton(
                    onPressed: _isCheckingServer ? null : _loadFromLocalServer,
                    icon: _isCheckingServer ? Icons.hourglass_empty : Icons.folder_open,
                    label: 'Load from Local Server',
                    gradient: AppTheme.accentGradient,
                    isLoading: _isCheckingServer,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'or',
                    style: TextStyle(color: AppTheme.textTertiary),
                  ),
                  const SizedBox(height: 16),
                  _buildGlassButton(
                    onPressed: _handleFileUpload,
                    icon: Icons.upload_file,
                    label: 'Upload Files',
                    gradient: null,
                  ),
                ],
                
                if (kIsWeb && !_isServerConnected) ...[
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.secondaryColor, size: 24),
                        const SizedBox(height: 12),
                        Text(
                          'Start local server to access your music library without uploading',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _checkLocalServer,
                          child: Text('Check Connection'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    Gradient? gradient,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: gradient != null ? [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ] : null,
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: gradient != null ? Colors.transparent : AppTheme.cardColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _loadFromLocalServer() async {
    setState(() => _isCheckingServer = true);
    
    try {
      final songs = await _localServer.getLibrary();
      
      if (!mounted) return;
      
      if (songs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No songs found in local library'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        return;
      }
      
      final playerController = context.read<PlayerController>();
      
      for (var song in songs) {
        playerController.addToQueue(song);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Loaded ${songs.length} song${songs.length != 1 ? 's' : ''}'),
          backgroundColor: AppTheme.successColor,
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
          backgroundColor: AppTheme.errorColor,
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
      
      final result = await musicLibrary.importMusicFiles(
        onProgress: (current, total, filename) {
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
                  backgroundColor: AppTheme.cardColor,
                ),
              );
          }
        },
      );

      if (result.songs.isEmpty) return;

      for (var song in result.songs) {
        playerController.addToQueue(song);
      }

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      final message = kIsWeb
          ? '✓ Saved ${result.songs.length} song${result.songs.length != 1 ? 's' : ''} to library\n${MusicLibraryService.formatBytes(result.totalSize)}'
          : '✓ Added ${result.songs.length} song${result.songs.length != 1 ? 's' : ''} from local files';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.successColor,
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
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
