import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';

/// Service to communicate with local file server
/// Enables web app to access local music library without file uploads
class LocalServerService {
  final String baseUrl;
  bool _isConnected = false;
  
  // Production settings
  static const Duration _connectionTimeout = Duration(seconds: 5);
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  
  LocalServerService({this.baseUrl = 'http://localhost:3456'});
  
  bool get isConnected => _isConnected;
  
  /// Check if local server is running
  Future<bool> checkConnection() async {
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/api/health'),
        ).timeout(_connectionTimeout);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _isConnected = data['status'] == 'ok';
          return _isConnected;
        }
      } catch (e) {
        if (attempt < _maxRetries - 1) {
          // Wait before retry with exponential backoff
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          continue;
        }
        _isConnected = false;
      }
    }
    return false;
  }
  
  /// Get all songs from local library
  Future<List<Song>> getLibrary() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/songs'),
      ).timeout(_requestTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List songsJson = data['songs'];
        
        return songsJson.map((json) => Song(
          id: json['id'],
          title: json['title'],
          artist: json['artist'],
          album: json['album'],
          duration: Duration(seconds: (json['duration'] as num).toInt()),
          url: '$baseUrl/api/stream/${json['id']}',
          filePath: json['filePath'], // Keep original path for reference
          addedDate: DateTime.now(),
        )).toList().cast<Song>();
      }
    } catch (e) {
      print('Error fetching library: $e');
    }
    return [];
  }
  
  /// Search songs in local library
  Future<List<Song>> searchSongs(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/songs/search?q=${Uri.encodeComponent(query)}'),
      ).timeout(_requestTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List songsJson = data['songs'];
        
        return songsJson.map((json) => Song(
          id: json['id'],
          title: json['title'],
          artist: json['artist'],
          album: json['album'],
          duration: Duration(seconds: (json['duration'] as num).toInt()),
          url: '$baseUrl/api/stream/${json['id']}',
          filePath: json['filePath'],
          addedDate: DateTime.now(),
        )).toList().cast<Song>();
      }
    } catch (e) {
      print('Error searching songs: $e');
    }
    return [];
  }
  
  /// Trigger server to rescan music library
  Future<bool> rescanLibrary() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/scan'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error triggering rescan: $e');
      return false;
    }
  }
  
  /// Add custom directory to server
  Future<bool> addDirectory(String path) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/directories'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'path': path}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error adding directory: $e');
      return false;
    }
  }
  
  /// Get stream URL for a song
  String getStreamUrl(String songId) {
    return '$baseUrl/api/stream/$songId';
  }
  
  /// Get cover art URL for a song
  String getCoverUrl(String songId) {
    return '$baseUrl/api/cover/$songId';
  }
}
