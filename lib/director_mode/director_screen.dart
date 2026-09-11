import 'package:flutter/material.dart';

import '../ui/widgets/big_button.dart';
import '../ui/widgets/status_badge.dart';

/// The control center. This phone directs the broadcast.
class DirectorScreen extends StatefulWidget {
  const DirectorScreen({super.key});

  @override
  State<DirectorScreen> createState() => _DirectorScreenState();
}

class _DirectorScreenState extends State<DirectorScreen> {
  static const _scenes = ['CAM 1', 'CAM 2', 'CAM 3', 'CAM 4'];

  int _activeScene = 0;
  bool _onAir = false;
  bool _adPlaying = false;

  void _cutTo(int index) {
    setState(() {
      _activeScene = index;
      _adPlaying = false;
    });
  }

  void _playAd() => setState(() => _adPlaying = true);
  void _returnLive() => setState(() => _adPlaying = false);
  void _toggleAir() => setState(() => _onAir = !_onAir);

  @override
  Widget build(BuildContext context) {
    final statusLabel = _adPlaying
        ? 'ON AD'
        : _onAir
            ? 'ON AIR • 720p'
            : 'OFFLINE';

    final statusState = _adPlaying
        ? LinkState.connecting
        : _onAir
            ? LinkState.internet
            : LinkState.offline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DIRECTOR'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: StatusBadge(state: statusState, label: statusLabel),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // ---- Multiview grid ----
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: List.generate(_scenes.length, (i) {
                  final isActive = i == _activeScene && !_adPlaying;
                  return GestureDetector(
                    onTap: () => _cutTo(i),
                    child: _SceneTile(
                      name: _scenes[i],
                      active: isActive,
                    ),
                  );
                }),
              ),
            ),
          ),

          // ---- Right-side control column ----
          Container(
            width: 220,
            color: const Color(0xFF14141A),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                BigButton(
                  icon: _onAir ? Icons.stop_circle : Icons.podcasts,
                  label: _onAir ? 'END STREAM' : 'GO LIVE',
                  color: _onAir ? Colors.redAccent : Colors.greenAccent,
                  active: _onAir,
                  onTap: _toggleAir,
                ),
                BigButton(
                  icon: Icons.campaign,
                  label: _adPlaying ? 'RETURN LIVE' : 'AD BREAK',
                  color: Colors.orangeAccent,
                  active: _adPlaying,
                  size: 90,
                  onTap: _adPlaying ? _returnLive : _playAd,
                ),
                BigButton(
                  icon: Icons.cut,
                  label: 'NEXT CAM',
                  color: Colors.blueAccent,
                  active: true,
                  size: 90,
                  onTap: () => _cutTo((_activeScene + 1) % _scenes.length),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneTile extends StatelessWidget {
  final String name;
  final bool active;

  const _SceneTile({required this.name, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.redAccent : Colors.white24;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? Colors.redAccent : Colors.white12,
          width: active ? 3 : 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam, color: color, size: 44),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: active ? Colors.redAccent : Colors.white38,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
            if (active) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
