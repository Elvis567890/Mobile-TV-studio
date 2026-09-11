import 'package:flutter/material.dart';

/// The red / green light on a camera.
/// RED   = this camera is ON AIR (the director chose it)
/// GREEN = preview (director is looking at it, not on air)
/// OFF   = idle
enum TallyState { off, preview, live }

class TallyIndicator extends StatefulWidget {
  final TallyState state;
  final double size;

  const TallyIndicator({
    super.key,
    required this.state,
    this.size = 20,
  });

  @override
  State<TallyIndicator> createState() => _TallyIndicatorState();
}

class _TallyIndicatorState extends State<TallyIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.state == TallyState.live) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant TallyIndicator old) {
    super.didUpdateWidget(old);
    if (widget.state == TallyState.live && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (widget.state != TallyState.live && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.state) {
      case TallyState.live:
        return Colors.redAccent;
      case TallyState.preview:
        return Colors.greenAccent;
      case TallyState.off:
        return Colors.white24;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final glow = widget.state == TallyState.live ? _pulse.value : 0.0;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _color,
            boxShadow: [
              BoxShadow(
                color: _color.withOpacity(0.3 + 0.6 * glow),
                blurRadius: 8 + 12 * glow,
                spreadRadius: 1 + 3 * glow,
              ),
            ],
          ),
        );
      },
    );
  }
}
