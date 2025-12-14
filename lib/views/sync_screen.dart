import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/device.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _isSyncing = false;
  final List<ConnectedDevice> _connectedDevices = [];

  @override
  void initState() {
    super.initState();
    _loadDemoDevices();
  }

  void _loadDemoDevices() {
    // Demo devices for testing
    setState(() {
      _connectedDevices.addAll([
        ConnectedDevice(
          id: '1',
          name: 'iPhone 13',
          type: DeviceType.mobile,
          status: DeviceStatus.online,
          connectedAt: DateTime.now(),
        ),
        ConnectedDevice(
          id: '2',
          name: 'MacBook Pro',
          type: DeviceType.desktop,
          status: DeviceStatus.online,
          connectedAt: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
        ConnectedDevice(
          id: '3',
          name: 'iPad Air',
          type: DeviceType.tablet,
          status: DeviceStatus.offline,
          connectedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Sync'),
        actions: [
          IconButton(
            icon: Icon(_isSyncing ? Icons.sync_disabled : Icons.sync),
            onPressed: _toggleSync,
            tooltip: _isSyncing ? 'Disable Sync' : 'Enable Sync',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sync Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: _isSyncing
                            ? AppTheme.primaryGradient
                            : LinearGradient(
                                colors: [
                                  AppTheme.cardColor,
                                  AppTheme.cardColor.withOpacity(0.8),
                                ],
                              ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isSyncing ? Icons.sync : Icons.sync_disabled,
                        size: 40,
                        color: _isSyncing ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isSyncing ? 'Sync Active' : 'Sync Disabled',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSyncing
                          ? 'Your music is synced across devices'
                          : 'Enable sync to play across multiple devices',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _toggleSync,
                      icon: Icon(_isSyncing ? Icons.stop : Icons.play_arrow),
                      label: Text(_isSyncing ? 'Stop Sync' : 'Start Sync'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isSyncing ? AppTheme.errorColor : AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Connected Devices
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Connected Devices',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                TextButton.icon(
                  onPressed: _scanForDevices,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Scan'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Device List
            if (_connectedDevices.isEmpty)
              _buildEmptyState()
            else
              ..._connectedDevices.map((device) => _buildDeviceCard(device)),

            const SizedBox(height: 32),

            // Sync Settings Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync Settings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Auto-sync on WiFi'),
                      subtitle: const Text('Automatically sync when connected to WiFi'),
                      value: true,
                      onChanged: (value) {},
                      activeColor: AppTheme.primaryColor,
                    ),
                    SwitchListTile(
                      title: const Text('Sync Playlists'),
                      subtitle: const Text('Keep playlists in sync across devices'),
                      value: true,
                      onChanged: (value) {},
                      activeColor: AppTheme.primaryColor,
                    ),
                    SwitchListTile(
                      title: const Text('Sync Playback Position'),
                      subtitle: const Text('Resume from where you left off'),
                      value: false,
                      onChanged: (value) {},
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.devices_other,
              size: 60,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No devices found',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _scanForDevices,
              child: const Text('Scan for devices'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(ConnectedDevice device) {
    final isConnected = device.status == DeviceStatus.online;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: isConnected
                ? AppTheme.primaryGradient
                : LinearGradient(
                    colors: [
                      AppTheme.cardColor,
                      AppTheme.cardColor.withOpacity(0.8),
                    ],
                  ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getDeviceIcon(device.type),
            color: isConnected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
        title: Text(
          device.name,
          style: TextStyle(
            fontWeight: isConnected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          isConnected
              ? 'Connected'
              : 'Last seen ${_formatLastSeen(device.connectedAt)}',
          style: TextStyle(
            color: isConnected ? AppTheme.successColor : AppTheme.textSecondary,
          ),
        ),
        trailing: isConnected
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : TextButton(
                onPressed: () => _connectDevice(device),
                child: const Text('Connect'),
              ),
      ),
    );
  }

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.mobile:
        return Icons.phone_android;
      case DeviceType.tablet:
        return Icons.tablet;
      case DeviceType.desktop:
        return Icons.computer;
      case DeviceType.web:
        return Icons.language;
    }
  }

  String _formatLastSeen(DateTime lastSeen) {
    final difference = DateTime.now().difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _toggleSync() {
    setState(() {
      _isSyncing = !_isSyncing;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSyncing ? 'Sync enabled' : 'Sync disabled'),
        backgroundColor: _isSyncing ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
  }

  void _scanForDevices() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scanning for devices...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _connectDevice(ConnectedDevice device) {
    setState(() {
      final index = _connectedDevices.indexWhere((d) => d.id == device.id);
      if (index != -1) {
        _connectedDevices[index] = ConnectedDevice(
          id: device.id,
          name: device.name,
          type: device.type,
          status: DeviceStatus.online,
          connectedAt: DateTime.now(),
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connected to ${device.name}'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
}
