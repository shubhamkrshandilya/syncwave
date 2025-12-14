import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../config/app_constants.dart';

class PlaylistController extends ChangeNotifier {
  List<Playlist> _playlists = [];
  
  List<Playlist> get playlists => _playlists;

  PlaylistController() {
    loadPlaylists();
  }

  // Load playlists from storage
  Future<void> loadPlaylists() async {
    final box = Hive.box(AppConstants.playlistsBox);
    final playlistsData = box.get('playlists', defaultValue: []);
    
    if (playlistsData is List) {
      _playlists = playlistsData
          .map((data) => Playlist.fromJson(Map<String, dynamic>.from(data)))
          .toList();
      notifyListeners();
    }
  }

  // Save playlists to storage
  Future<void> _savePlaylists() async {
    final box = Hive.box(AppConstants.playlistsBox);
    final playlistsData = _playlists.map((p) => p.toJson()).toList();
    await box.put('playlists', playlistsData);
  }

  // Create a new playlist
  Future<void> createPlaylist(String name, {String? description}) async {
    final playlist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description ?? '',
      songs: [],
      createdDate: DateTime.now(),
      modifiedDate: DateTime.now(),
    );
    
    _playlists.add(playlist);
    await _savePlaylists();
    notifyListeners();
  }

  // Delete a playlist
  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
    await _savePlaylists();
    notifyListeners();
  }

  // Add song to playlist
  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      _playlists[index].songs.add(song);
      await _savePlaylists();
      notifyListeners();
    }
  }

  // Remove song from playlist
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      _playlists[index].songs.removeWhere((s) => s.id == songId);
      await _savePlaylists();
      notifyListeners();
    }
  }

  // Update playlist
  Future<void> updatePlaylist(Playlist playlist) async {
    final index = _playlists.indexWhere((p) => p.id == playlist.id);
    if (index != -1) {
      _playlists[index] = playlist;
      await _savePlaylists();
      notifyListeners();
    }
  }

  // Get playlist by ID
  Playlist? getPlaylistById(String id) {
    try {
      return _playlists.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}
