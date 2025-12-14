import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../config/app_theme.dart';
import '../config/app_constants.dart';

class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  String _roomCode = '';
  bool _isHosting = false;

  @override
  void initState() {
    super.initState();
    _generateRoomCode();
  }

  void _generateRoomCode() {
    // Generate a random 6-digit room code
    setState(() {
      _roomCode = DateTime.now().millisecondsSinceEpoch.toString().substring(7, 13);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share & Connect'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Share Your Music',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Connect with friends to sync playback',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // QR Code Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: '${AppConstants.shareUrlPrefix}$_roomCode',
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Room Code',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _roomCode,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: _copyRoomCode,
                          tooltip: 'Copy code',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Scan this QR code or enter the room code to join',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Host/Stop Button
            ElevatedButton.icon(
              onPressed: _toggleHosting,
              icon: Icon(_isHosting ? Icons.stop : Icons.broadcast_on_personal),
              label: Text(_isHosting ? 'Stop Hosting' : 'Start Hosting'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isHosting ? AppTheme.errorColor : AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Join Room Button
            OutlinedButton.icon(
              onPressed: _showJoinRoomDialog,
              icon: const Icon(Icons.login),
              label: const Text('Join a Room'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),

            const SizedBox(height: 16),

            // Scan QR Code Button
            OutlinedButton.icon(
              onPressed: _scanQRCode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.secondaryColor, width: 2),
              ),
            ),

            const SizedBox(height: 32),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'How it works',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem('1. Host a room or join an existing one'),
                  _buildInfoItem('2. Share the QR code or room code'),
                  _buildInfoItem('3. Friends can scan or enter the code'),
                  _buildInfoItem('4. Enjoy synchronized playback together'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 32),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleHosting() {
    setState(() {
      _isHosting = !_isHosting;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isHosting ? 'Hosting room $_roomCode' : 'Stopped hosting'),
        backgroundColor: _isHosting ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
  }

  void _copyRoomCode() {
    // TODO: Implement clipboard copy
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Room code copied!'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _showJoinRoomDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Join Room'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: 'Enter Room Code',
            border: OutlineInputBorder(),
            hintText: '123456',
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.length == 6) {
                Navigator.pop(context);
                _joinRoom(codeController.text);
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _joinRoom(String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joining room $code...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _scanQRCode() {
    // TODO: Implement QR code scanning
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR scanner coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}
