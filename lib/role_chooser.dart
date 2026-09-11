import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_settings.dart';
import 'camera_mode/camera_screen.dart';
import 'director_mode/director_screen.dart';

class RoleChooser extends StatelessWidget {
  const RoleChooser({super.key});

  Future<void> _pick(BuildContext context, PhoneRole role) async {
    final settings = context.read<AppSettings>();
    await settings.setRole(role);

    if (!context.mounted) return;

    switch (role) {
      case PhoneRole.camera:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CameraScreen()),
        );
        break;
      case PhoneRole.director:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DirectorScreen()),
        );
        break;
      case PhoneRole.both:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DirectorScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'MOBILE TV STUDIO',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'What is this phone?',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 48),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoleCard(
                    icon: Icons.videocam,
                    title: 'CAMERA',
                    subtitle: 'Send live video',
                    color: Colors.redAccent,
                    onTap: () => _pick(context, PhoneRole.camera),
                  ),
                  const SizedBox(width: 24),
                  _RoleCard(
                    icon: Icons.dashboard,
                    title: 'DIRECTOR',
                    subtitle: 'Control the broadcast',
                    color: Colors.blueAccent,
                    onTap: () => _pick(context, PhoneRole.director),
                  ),
                  const SizedBox(width: 24),
                  _RoleCard(
                    icon: Icons.all_inclusive,
                    title: 'BOTH',
                    subtitle: 'Send and control',
                    color: Colors.purpleAccent,
                    onTap: () => _pick(context, PhoneRole.both),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              if (settings.role != null)
                Text(
                  'Last used: ${settings.role!.name.toUpperCase()}',
                  style: const TextStyle(color: Colors.white38),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 200,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
