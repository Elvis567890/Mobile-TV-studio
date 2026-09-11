import 'package:flutter/material.dart';

/// A large, thumb-friendly button. Designed to be hit while live
/// without looking at the screen.
class BigButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool active;
  final double size;

  const BigButton({
    super.key,
    this.icon,
    required this.label,
    this.color = Colors.blueAccent,
    this.onTap,
    this.active = false,
    this.size = 110,
  });

  @override
  Widget build(BuildContext context) {
    final effective = active ? color : color.withOpacity(0.35);

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: active ? effective.withOpacity(0.15) : Colors.white10,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: effective,
              width: active ? 2.5 : 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Icon(icon, size: size * 0.32, color: effective),
              if (icon != null) const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: effective,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
