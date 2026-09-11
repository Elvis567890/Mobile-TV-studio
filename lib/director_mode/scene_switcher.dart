import 'package:flutter/material.dart';

enum TransitionType { cut, fade, wipeLeft, wipeRight }

/// Bottom bar of the director. Pick a transition, then tap a source
/// to take it to air.
class SceneSwitcher extends StatelessWidget {
  final TransitionType transition;
  final void Function(TransitionType) onTransitionChanged;
  final VoidCallback onTake;
  final bool canTake;

  const SceneSwitcher({
    super.key,
    required this.transition,
    required this.onTransitionChanged,
    required this.onTake,
    this.canTake = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF14141A),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Text(
            'TRANSITION',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 12),
          _TransChip(
            label: 'CUT',
            icon: Icons.content_cut,
            active: transition == TransitionType.cut,
            onTap: () => onTransitionChanged(TransitionType.cut),
          ),
          const SizedBox(width: 6),
          _TransChip(
            label: 'FADE',
            icon: Icons.gradient,
            active: transition == TransitionType.fade,
            onTap: () => onTransitionChanged(TransitionType.fade),
          ),
          const SizedBox(width: 6),
          _TransChip(
            label: 'WIPE ←',
            icon: Icons.arrow_back,
            active: transition == TransitionType.wipeLeft,
            onTap: () => onTransitionChanged(TransitionType.wipeLeft),
          ),
          const SizedBox(width: 6),
          _TransChip(
            label: 'WIPE →',
            icon: Icons.arrow_forward,
            active: transition == TransitionType.wipeRight,
            onTap: () => onTransitionChanged(TransitionType.wipeRight),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: canTake ? onTake : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('TAKE'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              disabledBackgroundColor: Colors.white12,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TransChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.blueAccent : Colors.white38;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? color : Colors.white12,
            width: active ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
