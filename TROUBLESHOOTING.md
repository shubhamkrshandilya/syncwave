# 🔧 SyncWave Troubleshooting Guide

Common issues and solutions for running SyncWave.

---

## 🚨 Common Issues

### 1. "flutter command not found"

**Problem**: Flutter is not installed or not in PATH

**Solutions**:
```bash
# Check if Flutter is installed
which flutter

# If not found, install Flutter:
# Visit: https://flutter.dev/docs/get-started/install

# Or if installed but not in PATH, add to ~/.zshrc:
export PATH="$PATH:/path/to/flutter/bin"
source ~/.zshrc
```

---

### 2. "No devices found"

**Problem**: No simulator/emulator is running

**Solutions**:

#### iOS Simulator
```bash
# List available simulators
xcrun simctl list devices

# Open iOS Simulator
open -a Simulator

# Or use Xcode > Xcode > Open Developer Tool > Simulator
```

#### Android Emulator
```bash
# List available emulators
emulator -list-avds

# Start an emulator
emulator -avd <emulator_name>

# Or use Android Studio > AVD Manager > Run
```

#### Chrome (Web)
```bash
# Just run
flutter run -d chrome
# Chrome will open automatically
```

---

### 3. "Packages get failed"

**Problem**: Dependencies couldn't be downloaded

**Solutions**:
```bash
# Clean and retry
flutter clean
flutter pub cache repair
flutter pub get

# If still failing, check internet connection
ping pub.dev

# Clear pub cache completely (nuclear option)
rm -rf ~/.pub-cache
flutter pub get
```

---

### 4. "iOS build failed - pod install error"

**Problem**: CocoaPods dependencies issue

**Solutions**:
```bash
cd ios

# Clean pods
rm -rf Pods Podfile.lock
pod deintegrate
pod cache clean --all

# Reinstall
pod install --repo-update

cd ..
flutter clean
flutter run
```

---

### 5. "Android build failed - Gradle error"

**Problem**: Gradle or Android SDK issues

**Solutions**:
```bash
# Clean Gradle cache
cd android
./gradlew clean
cd ..

# Or clean all
flutter clean
flutter pub get

# Update Gradle wrapper
cd android
./gradlew wrapper --gradle-version=8.0
cd ..

# Accept Android licenses
flutter doctor --android-licenses
```

---

### 6. "Just Audio not working"

**Problem**: Audio playback service issues

**Solutions**:

#### iOS
```bash
# Make sure you have permissions in Info.plist
# ios/Runner/Info.plist should have:
<key>NSMicrophoneUsageDescription</key>
<string>Required for audio playback</string>
```

#### Android
```bash
# Check android/app/src/main/AndroidManifest.xml has:
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

---

### 7. "Hive database error"

**Problem**: Database initialization failed

**Solutions**:
```dart
// Make sure main.dart has:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // ... rest of code
}
```

```bash
# If persists, clear app data:
flutter clean
# Uninstall app from device/simulator
flutter run
```

---

### 8. "Hot reload not working"

**Problem**: Changes not reflecting

**Solutions**:
```bash
# Full restart (press R in terminal)
R

# Or stop and restart
# Press 'q' to quit
flutter run

# If still not working, clean rebuild:
flutter clean
flutter run
```

---

### 9. "Provider state not updating"

**Problem**: UI not rebuilding when state changes

**Check**:
```dart
// Make sure you're calling notifyListeners()
class PlayerController extends ChangeNotifier {
  void playSong(Song song) {
    _currentSong = song;
    notifyListeners(); // ← Don't forget this!
  }
}

// Use Consumer or context.watch
Consumer<PlayerController>(
  builder: (context, controller, child) {
    return Text(controller.currentSong?.title ?? '');
  },
)
```

---

### 10. "File picker permission denied"

**Problem**: Can't access files on device

**Solutions**:

#### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>To import music files</string>
<key>NSDocumentDirectoryUsageDescription</key>
<string>To access music files</string>
```

#### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

Request at runtime:
```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermission() async {
  if (await Permission.storage.request().isGranted) {
    // Permission granted
  }
}
```

---

### 11. "QR Code not generating"

**Problem**: QR code widget showing blank

**Check**:
```dart
// Make sure QR data is not empty
QrImageView(
  data: '${AppConstants.shareUrlPrefix}$_roomCode',
  // data must not be empty string
)
```

---

### 12. "App crashes on startup"

**Problem**: Initialization error

**Debug steps**:
```bash
# Run with verbose logging
flutter run -v

# Check console output for error
# Common causes:
# - Missing await in main()
# - Hive not initialized
# - Provider not set up correctly
```

**Fix**:
```dart
// main.dart should look like:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.songsBox);
  await Hive.openBox(AppConstants.playlistsBox);
  await Hive.openBox(AppConstants.settingsBox);
  
  runApp(const SyncWaveApp());
}
```

---

### 13. "Web version not loading"

**Problem**: Blank page on web

**Solutions**:
```bash
# Clear browser cache
# Then rebuild
flutter clean
flutter run -d chrome

# Or try different port
flutter run -d chrome --web-port=8080
```

---

### 14. "macOS build failed - signing error"

**Problem**: Code signing issues

**Solutions**:
```bash
# Disable signing for development
# In Xcode:
# 1. Open macos/Runner.xcworkspace
# 2. Select Runner target
# 3. Signing & Capabilities
# 4. Uncheck "Automatically manage signing"
# 5. Set Team to None

# Or add entitlements
# Check macos/Runner/DebugProfile.entitlements
```

---

## 🔍 Debugging Tips

### Enable Debug Mode
```dart
// Add to any screen
if (kDebugMode) {
  print('Debug info: $variable');
}
```

### Use Flutter DevTools
```bash
# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Then in your running app terminal, you'll see a link
# Click it to open DevTools
```

### Check Provider State
```dart
// In any widget
@override
Widget build(BuildContext context) {
  print('PlayerController: ${context.read<PlayerController>()}');
  return Container();
}
```

### Performance Profiling
```bash
# Run in profile mode
flutter run --profile

# Use DevTools Performance tab
```

---

## 📱 Platform-Specific Tips

### iOS
- Use Xcode to see detailed build errors
- Check simulator logs: `xcrun simctl spawn booted log stream --predicate 'process == "Runner"'`
- Reset simulator: Device > Erase All Content and Settings

### Android
- Use Android Studio for detailed Gradle errors
- Check logcat: `adb logcat`
- Clear app data: Settings > Apps > SyncWave > Clear Data

### Web
- Open browser console (F12) for JavaScript errors
- Check Network tab for failed requests
- Try incognito mode to avoid cache issues

### macOS
- Check Console app for crash logs
- Grant necessary permissions in System Preferences

---

## 🆘 Still Having Issues?

### Check Flutter Installation
```bash
flutter doctor -v
```

Fix any issues shown with ❌

### Verify Dependencies
```bash
flutter pub outdated
flutter pub upgrade
```

### Clean Everything
```bash
# Nuclear option - clean everything
flutter clean
rm -rf ios/Pods ios/Podfile.lock
rm -rf android/.gradle
flutter pub get
cd ios && pod install && cd ..
flutter run
```

### Get Help
1. Check existing GitHub issues
2. Run `flutter doctor -v` and share output
3. Include error logs
4. Mention platform (iOS/Android/Web/etc)

---

## 📊 Performance Issues

### App Running Slowly
```bash
# Run in release mode
flutter run --release

# Profile mode for debugging
flutter run --profile
```

### Large App Size
```bash
# Build optimized APK
flutter build apk --split-per-abi

# Check size breakdown
flutter build apk --analyze-size
```

### Memory Issues
```dart
// Use const constructors
const Text('Hello');

// Dispose controllers
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

---

## 🔄 Update Issues

### After Updating Flutter
```bash
flutter clean
flutter pub get
flutter pub upgrade
flutter run
```

### After Git Pull
```bash
flutter pub get
cd ios && pod install && cd ..
flutter run
```

---

**Last Updated**: December 2025

**Need more help?** Open an issue on GitHub with:
- Your `flutter doctor -v` output
- Full error message
- Steps to reproduce
- Platform (iOS/Android/Web/macOS)
