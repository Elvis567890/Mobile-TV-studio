import 'package:flutter/material.dart';

/// Which radio the video is currently flowing over.
enum LinkState {
  offline,
  connecting,
  wifi,
  bluetooth,
  internet,
}

/// Small pill in the app bar showing link state and current quality.
class StatusBadge extends StatelessWidget {
  final LinkState state;
  final String label;

  const StatusBadge({
    super.key,
    required this.state,
    required this.label,
  });

  Color get _color {
    switch (state) {
      case LinkState.offline:
        return Colors.grey;
      case LinkState.connecting:
        return Colors.orangeAccent;
      case LinkState.wifi:
        return Colors.greenAccent;
      case LinkState.bluetooth:
        return Colors.blueAccent;
      case LinkState.internet:
        return Colors.purpleAccent;
    }
  }

  IconData get _icon {
    switch (state) {
      case LinkState.offline:
        return Icons.cloud_off;
      case LinkState.connecting:
        return Icons.sync;
      case LinkState.wifi:
        return Icons.wifi;
      case LinkState.bluetooth:
        return Icons.bluetooth;
      case LinkState.internet:
        return Icons.public;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: c),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
