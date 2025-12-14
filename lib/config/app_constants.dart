class AppConstants {
  // App Info
  static const String appName = 'SyncWave';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Stream & Sync Your Music';

  // Storage Keys
  static const String themeKey = 'theme_mode';
  static const String userIdKey = 'user_id';
  static const String playlistsKey = 'playlists';
  static const String settingsKey = 'settings';

  // Hive Box Names
  static const String songsBox = 'songs';
  static const String playlistsBox = 'playlists';
  static const String settingsBox = 'settings';

  // WebSocket
  static const String defaultServerUrl = 'ws://localhost:8080';
  static const int reconnectDelay = 3000; // milliseconds

  // Audio
  static const List<String> supportedFormats = [
    'mp3',
    'wav',
    'ogg',
    'm4a',
    'aac',
    'flac',
  ];

  static const double defaultVolume = 0.7;
  static const int maxQueueSize = 100;

  // UI
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Sharing
  static const int qrCodeSize = 200;
  static const String shareUrlPrefix = 'syncwave://share/';

  // Error Messages
  static const String networkError = 'Network connection failed';
  static const String fileNotSupported = 'File format not supported';
  static const String permissionDenied = 'Permission denied';
  static const String deviceNotFound = 'Device not found';
}
