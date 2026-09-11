import 'package:flutter/material.dart';

import '../data/app_settings.dart';

/// First-run guide. Three short pages, then done.
class SetupWizard extends StatefulWidget {
  final VoidCallback onComplete;

  const SetupWizard({super.key, required this.onComplete});

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: const [
                  _Page(
                    icon: Icons.wifi_tethering,
                    title: 'CONNECT',
                    body:
                        'Put all phones on the same Wi-Fi hotspot for best quality. '
                        'When Wi-Fi drops, the app switches to Bluetooth or the internet '
                        'automatically. You never lose the broadcast.',
                  ),
                  _Page(
                    icon: Icons.dashboard_customize,
                    title: 'DIRECT',
                    body:
                        'One phone is the control room. You see every camera at once, '
                        'cut between them live, mix audio, and play commercial breaks '
                        'with a single tap.',
                  ),
                  _Page(
                    icon: Icons.podcasts,
                    title: 'GO LIVE',
                    body:
                        'Send your broadcast to YouTube, Facebook, Twitch, or your own '
                        'server. Data saver mode keeps your mobile bill down. Local '
                        'recording is always on as a backup.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(3, (i) {
                      final active = i == _page;
                      return Container(
                        width: active ? 22 : 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: active ? Colors.blueAccent : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  FilledButton(
                    onPressed: _next,
                    child: Text(_page == 2 ? 'GET STARTED' : 'NEXT'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Page({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 96, color: Colors.blueAccent),
          const SizedBox(height: 32),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white70,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper the app calls on startup to decide wizard vs role chooser.
Future<bool> shouldShowWizard() async {
  final s = AppSettings();
  await s.load();
  return s.role == null;
}
