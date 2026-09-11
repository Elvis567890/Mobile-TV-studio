import 'package:flutter/material.dart';

import '../ui/widgets/big_button.dart';
import '../ui/widgets/status_badge.dart';

/// The camera node UI. This phone sends video.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _live = false;
  LinkState _link = LinkState.offline;
  String _quality = '720p';
  bool _frontCamera = false;

  void _toggleLive() {
    setState(() {
      _live = !_live;
      _link = _live ? LinkState.connecting : LinkState.offline;
    });

    if (_live) {
      // Placeholder — will be replaced by real transport connection.
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _link = LinkState.wifi);
      });
    }
  }

  void _cycleQuality() {
    setState(() {
      switch (_quality) {
        case '720p':
          _quality = '480p';
          break;
        case '480p':
          _quality = '360p';
          break;
        default:
          _quality = '720p';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final linkLabel = _link == LinkState.offline
        ? 'OFFLINE'
        : '$_quality • ${_link.name.toUpperCase()}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('CAMERA NODE'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: StatusBadge(state: _link, label: linkLabel),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // ---- Preview area ----
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _live ? Colors.redAccent : Colors.white12,
                  width: _live ? 3 : 1,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _live ? Icons.videocam : Icons.videocam_off,
                      size: 72,
                      color: _live ? Colors.redAccent : Colors.white24,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _live ? 'PREVIEW LIVE' : 'CAMERA IDLE',
                      style: TextStyle(
                        color: _live ? Colors.redAccent : Colors.white38,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Live camera feed appears here.',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ---- Control column ----
          Container(
            width: 200,
            color: const Color(0xFF14141A),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                BigButton(
                  icon: _live ? Icons.stop : Icons.play_arrow,
                  label: _live ? 'STOP' : 'GO LIVE',
                  color: _live ? Colors.redAccent : Colors.greenAccent,
                  active: _live,
                  onTap: _toggleLive,
                ),
                BigButton(
                  icon: Icons.high_quality,
                  label: _quality,
                  color: Colors.blueAccent,
                  active: true,
                  size: 90,
                  onTap: _cycleQuality,
                ),
                BigButton(
                  icon: Icons.flip_camera_android,
                  label: _frontCamera ? 'FRONT' : 'REAR',
                  color: Colors.purpleAccent,
                  active: true,
                  size: 90,
                  onTap: () => setState(() => _frontCamera = !_frontCamera),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
