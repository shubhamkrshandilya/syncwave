import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../config/app_theme.dart';
import '../controllers/player_controller.dart';
import '../services/audio_service.dart';
import '../services/music_library_service.dart';
import '../services/local_music_scanner.dart';
import '../models/song.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _scanner = LocalMusicScanner();
  List<Song> _allSongs = [];
  List<Song> _filteredSongs = [];
  Set<String> _selectedSongIds = {};
  bool _isLoading = false;
  bool _selectMode = false;
  String _searchQuery = '';
  String _sortBy = 'title'; // title, artist, album, dateAdded

  @override
  void initState() {
    super.initState();
    _autoScanLocalMusic();
  }

  Future<void> _autoScanLocalMusic() async {
    if (kIsWeb) return;
    
    setState(() => _isLoading = true);

    try {
      await _scanner.initialize();
      final defaultPaths = _scanner.getDefaultMusicPaths();
      
      // Check which paths are accessible
      final accessiblePaths = <String>[];
      for (final path in defaultPaths) {
        if (await _scanner.isPathAccessible(path)) {
          accessiblePaths.add(path);
        }
      }

      if (accessiblePaths.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      int totalScanned = 0;
      final songs = await _scanner.scanMultipleDirectories(
        accessiblePaths,
        onProgress: (scanned, file) {
          totalScanned = scanned;
          if (mounted && scanned % 10 == 0) {
            setState(() {}); // Update UI periodically
          }
        },
      );

      if (mounted) {
        final playerController = context.read<PlayerController>();
        
        setState(() {
          _allSongs = songs;
          _filteredSongs = List.from(_allSongs);
          _sortSongs();
          _isLoading = false;
        });

        // Add to player controller queue
        for (final song in songs) {
          playerController.addToQueue(song);
        }

        if (songs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Found ${songs.length} songs in your music library'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('Error scanning music: $e');
      }
    }
  }

  void _loadExistingSongs() {
    final playerController = context.read<PlayerController>();
    setState(() {
      _allSongs = List.from(playerController.queue);
      _filteredSongs = List.from(_allSongs);
      _sortSongs();
    });
  }

  Future<void> _scanMusicFolder() async {
    if (kIsWeb) {
      _importFiles();
      return;
    }

    try {
      setState(() => _isLoading = true);

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      
      if (selectedDirectory == null) {
        setState(() => _isLoading = false);
        return;
      }

      if (!mounted) return;

      final playerController = context.read<PlayerController>();
      
      int scannedCount = 0;
      final songs = await _scanner.scanDirectory(
        selectedDirectory,
        onProgress: (scanned, file) {
          scannedCount = scanned;
          if (mounted && scanned % 5 == 0) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('Scanning... found $scanned files'),
                  duration: const Duration(milliseconds: 500),
                  backgroundColor: AppTheme.cardColor,
                ),
              );
          }
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      for (var song in songs) {
        if (!_allSongs.any((s) => s.filePath == song.filePath)) {
          _allSongs.add(song);
          playerController.addToQueue(song);
        }
      }

      setState(() {
        _filteredSongs = List.from(_allSongs);
        _sortSongs();
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Found ${songs.length} songs in $selectedDirectory'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scanning folder: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _importFiles() async {
    try {
      setState(() => _isLoading = true);

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

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      for (var song in result.songs) {
        if (!_allSongs.any((s) => s.id == song.id)) {
          _allSongs.add(song);
          playerController.addToQueue(song);
        }
      }

      setState(() {
        _filteredSongs = List.from(_allSongs);
        _sortSongs();
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Loaded ${result.songs.length} songs'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading files: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _searchSongs(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredSongs = List.from(_allSongs);
      } else {
        _filteredSongs = _allSongs.where((song) {
          return song.title.toLowerCase().contains(_searchQuery) ||
                 song.artist.toLowerCase().contains(_searchQuery) ||
                 (song.album?.toLowerCase().contains(_searchQuery) ?? false);
        }).toList();
      }
      _sortSongs();
    });
  }

  void _sortSongs() {
    setState(() {
      switch (_sortBy) {
        case 'title':
          _filteredSongs.sort((a, b) => a.title.compareTo(b.title));
          break;
        case 'artist':
          _filteredSongs.sort((a, b) => a.artist.compareTo(b.artist));
          break;
        case 'album':
          _filteredSongs.sort((a, b) => (a.album ?? '').compareTo(b.album ?? ''));
          break;
        case 'dateAdded':
          _filteredSongs.sort((a, b) => b.addedDate.compareTo(a.addedDate));
          break;
      }
    });
  }

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      if (!_selectMode) {
        _selectedSongIds.clear();
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedSongIds.length == _filteredSongs.length) {
        _selectedSongIds.clear();
      } else {
        _selectedSongIds = _filteredSongs.map((s) => s.id).toSet();
      }
    });
  }

  void _playSelected() {
    if (_selectedSongIds.isEmpty) return;

    final selectedSongs = _filteredSongs
        .where((song) => _selectedSongIds.contains(song.id))
        .toList();

    final playerController = context.read<PlayerController>();
    final audioService = context.read<AudioService>();

    playerController.setQueue(selectedSongs);
    playerController.playAtIndex(0);
    
    final fileBytes = playerController.getFileBytes(selectedSongs[0].id);
    audioService.playSong(selectedSongs[0], fileBytes: fileBytes);

    setState(() {
      _selectMode = false;
      _selectedSongIds.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing ${selectedSongs.length} song${selectedSongs.length != 1 ? 's' : ''}'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _addSelectedToQueue() {
    if (_selectedSongIds.isEmpty) return;

    final selectedSongs = _filteredSongs
        .where((song) => _selectedSongIds.contains(song.id))
        .toList();

    final playerController = context.read<PlayerController>();

    for (var song in selectedSongs) {
      playerController.addToQueue(song);
    }

    setState(() {
      _selectMode = false;
      _selectedSongIds.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${selectedSongs.length} song${selectedSongs.length != 1 ? 's' : ''} to queue'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        title: _selectMode
            ? Text('${_selectedSongIds.length} selected')
            : const Text('Music Library'),
        leading: _selectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectMode,
              )
            : null,
        actions: [
          if (_selectMode) ...[
            IconButton(
              icon: Icon(
                _selectedSongIds.length == _filteredSongs.length
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
              ),
              onPressed: _selectAll,
              tooltip: 'Select All',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _toggleSelectMode,
              tooltip: 'Select Mode',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              onSelected: (value) {
                setState(() {
                  _sortBy = value;
                  _sortSongs();
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'title', child: Text('Sort by Title')),
                const PopupMenuItem(value: 'artist', child: Text('Sort by Artist')),
                const PopupMenuItem(value: 'album', child: Text('Sort by Album')),
                const PopupMenuItem(value: 'dateAdded', child: Text('Sort by Date Added')),
              ],
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: _searchSongs,
              decoration: InputDecoration(
                hintText: 'Search songs, artists, albums...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Song List
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.primaryColor),
                        const SizedBox(height: 16),
                        Text(
                          'Loading songs...',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : _filteredSongs.isEmpty
                    ? _buildEmptyState()
                    : _buildSongList(isCompact),
          ),
        ],
      ),
      floatingActionButton: _selectMode && _selectedSongIds.isNotEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  onPressed: _playSelected,
                  backgroundColor: AppTheme.primaryColor,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play'),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.extended(
                  onPressed: _addSelectedToQueue,
                  backgroundColor: AppTheme.accentColor,
                  icon: const Icon(Icons.add),
                  label: const Text('Add to Queue'),
                ),
              ],
            )
          : FloatingActionButton.extended(
              onPressed: kIsWeb ? _importFiles : _scanMusicFolder,
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.folder_open),
              label: Text(kIsWeb ? 'Import Files' : 'Scan Folder'),
            ),
    );
  }

  Widget _buildSongList(bool isCompact) {
    return ListView.builder(
      itemCount: _filteredSongs.length,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemBuilder: (context, index) {
        final song = _filteredSongs[index];
        final isSelected = _selectedSongIds.contains(song.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.primaryGradient : null,
            color: isSelected ? null : AppTheme.cardColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : AppTheme.cardColor.withOpacity(0.3),
            ),
          ),
          child: ListTile(
            leading: _selectMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedSongIds.add(song.id);
                        } else {
                          _selectedSongIds.remove(song.id);
                        }
                      });
                    },
                    fillColor: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.selected)) {
                        return Colors.white;
                      }
                      return AppTheme.cardColor;
                    }),
                    checkColor: AppTheme.primaryColor,
                  )
                : Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient.scale(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.music_note,
                      color: isSelected ? Colors.white : AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
            title: Text(
              song.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.artist,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected
                        ? Colors.white.withOpacity(0.9)
                        : AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (song.album != null && !isCompact) ...[
                  const SizedBox(height: 2),
                  Text(
                    song.album!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white.withOpacity(0.7)
                          : AppTheme.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            trailing: _selectMode
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isCompact)
                        Text(
                          _formatDuration(song.duration),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () => _showSongOptions(song),
                      ),
                    ],
                  ),
            onTap: () {
              if (_selectMode) {
                setState(() {
                  if (isSelected) {
                    _selectedSongIds.remove(song.id);
                  } else {
                    _selectedSongIds.add(song.id);
                  }
                });
              } else {
                _playSong(song);
              }
            },
            onLongPress: () {
              if (!_selectMode) {
                setState(() {
                  _selectMode = true;
                  _selectedSongIds.add(song.id);
                });
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient.scale(0.3),
              ),
              child: Icon(
                Icons.library_music,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No songs in library',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add music files to start building your library',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _playSong(Song song) {
    final playerController = context.read<PlayerController>();
    final audioService = context.read<AudioService>();

    playerController.playSong(song);
    final fileBytes = playerController.getFileBytes(song.id);
    audioService.playSong(song, fileBytes: fileBytes);

    Navigator.pop(context);
  }

  void _showSongOptions(Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow, color: AppTheme.primaryColor),
              title: const Text('Play Now'),
              onTap: () {
                Navigator.pop(context);
                _playSong(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music, color: AppTheme.accentColor),
              title: const Text('Add to Queue'),
              onTap: () {
                Navigator.pop(context);
                context.read<PlayerController>().addToQueue(song);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Added to queue'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.errorColor),
              title: const Text('Remove from Library'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _allSongs.removeWhere((s) => s.id == song.id);
                  _filteredSongs.removeWhere((s) => s.id == song.id);
                });
                context.read<PlayerController>().removeFromQueue(song.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Removed from library'),
                    backgroundColor: AppTheme.warningColor,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes;
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
