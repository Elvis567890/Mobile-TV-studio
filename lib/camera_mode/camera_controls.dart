import 'package:flutter/material.dart';

import '../ui/widgets/big_button.dart';

/// The entire right-side control column of the camera screen.
/// Kept separate so it can be reused in "Both" mode.
class CameraControls extends StatelessWidget {
  final bool live;
  final bool frontCamera;
  final String quality;
  final VoidCallback onToggleLive;
  final VoidCallback onCycleQuality;
  final VoidCallback onFlipCamera;
  final VoidCallback? onOpenSettings;

  const CameraControls({
    super.key,
    required this.live,
    required this.frontCamera,
    required this.quality,
    required this.onToggleLive,
    required this.onCycleQuality,
    required this.onFlipCamera,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: const Color(0xFF14141A),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BigButton(
            icon: live ? Icons.stop : Icons.play_arrow,
            label: live ? 'STOP' : 'GO LIVE',
            color: live ? Colors.redAccent : Colors.greenAccent,
            active: live,
            onTap: onToggleLive,
          ),
          BigButton(
            icon: Icons.high_quality,
            label: quality,
            color: Colors.blueAccent,
            active: true,
            size: 90,
            onTap: onCycleQuality,
          ),
          BigButton(
            icon: Icons.flip_camera_android,
            label: frontCamera ? 'FRONT' : 'REAR',
            color: Colors.purpleAccent,
            active: true,
            size: 90,
            onTap: onFlipCamera,
          ),
          if (onOpenSettings != null)
            IconButton(
              icon: const Icon(Icons.tune, color: Colors.white54),
              onPressed: onOpenSettings,
              tooltip: 'Settings',
            ),
        ],
      ),
    );
  }
}
