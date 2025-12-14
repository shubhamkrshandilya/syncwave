import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audio_service/audio_service.dart';
import 'config/app_theme.dart';
import 'config/app_constants.dart';
import 'services/audio_service.dart' as app_audio;
import 'services/audio_handler.dart';
import 'services/file_storage_service.dart';
import 'services/music_library_service.dart';
import 'controllers/player_controller.dart';
import 'controllers/playlist_controller.dart';
import 'views/home_screen.dart';
import 'views/playlists_screen.dart';
import 'views/share_screen.dart';
import 'views/sync_screen.dart';

late SyncWaveAudioHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize audio handler for background playback
  audioHandler = await AudioService.init(
    builder: () => SyncWaveAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.syncwave.audio',
      androidNotificationChannelName: 'SyncWave Music',
      androidNotificationOngoing: false,
      androidShowNotificationBadge: true,
      androidStopForegroundOnPause: false,
    ),
  );
  
  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.songsBox);
  await Hive.openBox(AppConstants.playlistsBox);
  await Hive.openBox(AppConstants.settingsBox);
  
  // Initialize file storage service for web
  final fileStorageService = FileStorageService();
  await fileStorageService.init();
  
  // Initialize music library service
  final musicLibraryService = MusicLibraryService(fileStorageService);
  
  runApp(SyncWaveApp(
    fileStorageService: fileStorageService,
    musicLibraryService: musicLibraryService,
  ));
}

class SyncWaveApp extends StatelessWidget {
  final FileStorageService fileStorageService;
  final MusicLibraryService musicLibraryService;
  
  const SyncWaveApp({
    super.key,
    required this.fileStorageService,
    required this.musicLibraryService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_audio.AudioService(audioHandler)),
        ChangeNotifierProvider(create: (_) => PlayerController(fileStorageService)),
        ChangeNotifierProvider(create: (_) => PlaylistController()),
        Provider.value(value: fileStorageService),
        Provider.value(value: musicLibraryService),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const PlaylistsScreen(),
    const ShareScreen(),
    const SyncScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.transparent,
          indicatorColor: AppTheme.primaryColor.withOpacity(0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.queue_music_outlined),
              selectedIcon: Icon(Icons.queue_music),
              label: 'Playlists',
            ),
            NavigationDestination(
              icon: Icon(Icons.share_outlined),
              selectedIcon: Icon(Icons.share),
              label: 'Share',
            ),
            NavigationDestination(
              icon: Icon(Icons.devices_outlined),
              selectedIcon: Icon(Icons.devices),
              label: 'Sync',
            ),
          ],
        ),
      ),
    );
  }
}
