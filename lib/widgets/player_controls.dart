import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class PlayerControls extends StatefulWidget {
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onShuffle;
  final VoidCallback onRepeat;
  final bool isPlaying;
  final bool isShuffle;
  final bool isRepeat;
  final Duration position;
  final Duration duration;
  final Function(Duration) onSeek;

  const PlayerControls({
    super.key,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onShuffle,
    required this.onRepeat,
    required this.isPlaying,
    required this.isShuffle,
    required this.isRepeat,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  bool _isDragging = false;
  double _dragValue = 0.0;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes;
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 600;
    
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress Bar with Modern Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 6,
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: _isDragging ? 10 : 8,
                      elevation: 4,
                      pressedElevation: 8,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 20,
                    ),
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveTrackColor: AppTheme.cardColor,
                    thumbColor: Colors.white,
                    overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                    trackShape: const RoundedRectSliderTrackShape(),
                  ),
                  child: Slider(
                    value: _isDragging
                        ? _dragValue
                        : (widget.duration.inMilliseconds > 0
                            ? widget.position.inMilliseconds / widget.duration.inMilliseconds
                            : 0.0),
                    onChanged: (value) {
                      setState(() {
                        _isDragging = true;
                        _dragValue = value;
                      });
                    },
                    onChangeEnd: (value) {
                      final newPosition = Duration(
                        milliseconds: (value * widget.duration.inMilliseconds).round(),
                      );
                      widget.onSeek(newPosition);
                      setState(() => _isDragging = false);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_isDragging 
                            ? Duration(milliseconds: (_dragValue * widget.duration.inMilliseconds).round())
                            : widget.position),
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: isCompact ? 11 : 13,
                          fontWeight: FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        _formatDuration(widget.duration),
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: isCompact ? 11 : 13,
                          fontWeight: FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isCompact ? 16 : 24),

          // Main Controls with Responsive Layout
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isCompact) ...[
                // Shuffle Button
                _buildControlButton(
                  icon: Icons.shuffle,
                  onPressed: widget.onShuffle,
                  isActive: widget.isShuffle,
                  size: 24,
                ),
                const SizedBox(width: 8),
              ],

              // Previous Button
              _buildControlButton(
                icon: Icons.skip_previous_rounded,
                onPressed: widget.onPrevious,
                size: isCompact ? 32 : 40,
              ),

              SizedBox(width: isCompact ? 16 : 24),

              // Play/Pause Button with Animated Gradient
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isCompact ? 64 : 72,
                height: isCompact ? 64 : 72,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.5),
                      blurRadius: 24,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onPlayPause,
                    customBorder: const CircleBorder(),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: child,
                        );
                      },
                      child: Icon(
                        widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        key: ValueKey(widget.isPlaying),
                        size: isCompact ? 32 : 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(width: isCompact ? 16 : 24),

              // Next Button
              _buildControlButton(
                icon: Icons.skip_next_rounded,
                onPressed: widget.onNext,
                size: isCompact ? 32 : 40,
              ),

              if (!isCompact) ...[
                const SizedBox(width: 8),
                // Repeat Button
                _buildControlButton(
                  icon: widget.isRepeat ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                  onPressed: widget.onRepeat,
                  isActive: widget.isRepeat,
                  size: 24,
                ),
              ],
            ],
          ),

          if (isCompact) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  icon: Icons.shuffle,
                  onPressed: widget.onShuffle,
                  isActive: widget.isShuffle,
                  size: 20,
                ),
                const SizedBox(width: 32),
                _buildControlButton(
                  icon: widget.isRepeat ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                  onPressed: widget.onRepeat,
                  isActive: widget.isRepeat,
                  size: 20,
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
    double size = 28,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppTheme.primaryColor.withOpacity(0.2) : Colors.transparent,
        border: isActive ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 1.5) : null,
      ),
      child: IconButton(
        icon: Icon(icon),
        iconSize: size,
        color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
        onPressed: onPressed,
        tooltip: '',
        padding: EdgeInsets.all(size * 0.3),
      ),
    );
  }
}
