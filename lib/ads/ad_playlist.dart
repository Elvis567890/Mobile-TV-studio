import 'package:flutter/material.dart';
import 'ad_playlist.dart';

class AdPlayer extends StatelessWidget {
  final AdClip clip;
  final VoidCallback onFinished;
  final bool loop;

  const AdPlayer({
    super.key,
    required this.clip,
    required this.onFinished,
    this.loop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Center(
            child: Text(
              clip.name,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          Positioned(
            top: 12, left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orangeAccent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('AD BREAK',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 2)),
            ),
          ),
          Positioned(
            bottom: 12, right: 12,
            child: FilledButton.icon(
              onPressed: onFinished,
              icon: const Icon(Icons.live_tv),
              label: const Text('BACK TO LIVE'),
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
