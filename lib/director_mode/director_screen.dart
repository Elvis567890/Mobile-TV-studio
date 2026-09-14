cd /workspaces/Mobile-TV-studio && \
mkdir -p lib/director_mode && \
cat > lib/director_mode/director_screen.dart << 'DART_EOF'
import 'dart:async';

import 'package:flutter/material.dart';

const _bg = Color(0xFF0A0A0A);
const _panel = Color(0xFF141414);
const _border = Color(0x14FFFFFF);
const _red = Color(0xFFEF4444);
const _green = Color(0xFF22C55E);
const _yellow = Color(0xFFF5C542);
const _blue = Color(0xFF3B82F6);
const _textGrey = Color(0x66FFFFFF);
const _textMid = Color(0x99FFFFFF);

class DirectorScreen extends StatefulWidget {
  const DirectorScreen({super.key});

  @override
  State<DirectorScreen> createState() => _DirectorScreenState();
}

class _CamItem {
  final String name;
  bool isLive;
  bool isPreview;
  _CamItem(this.name, {this.isLive = false, this.isPreview = false});
}

class _AudioChannel {
  final String name;
  final String input;
  double volume;
  bool muted;
  bool solo;
  _AudioChannel(this.name, this.input, {this.volume = 0.7, this.muted = false, this.solo = false});
}

class _DirectorScreenState extends State<DirectorScreen> {
  bool _onAir = true;
  bool _menuOpen = false;
  int _activeTab = 0;
  int _seconds = 208;
  int _mbUsed = 24;
  Timer? _ticker;

  final List<_CamItem> _cams = [
    _CamItem('CAM 1', isLive: true),
    _CamItem('CAM 2', isPreview: true),
    _CamItem('CAM 3'),
    _CamItem('CAM 4'),
    _CamItem('CAM 5'),
    _CamItem('CAM 6'),
  ];

  final List<_AudioChannel> _channels = [
    _AudioChannel('CH 1', 'MIC', volume: 0.7),
    _AudioChannel('CH 2', 'USB', volume: 0.8),
    _AudioChannel('CH 3', 'BT', volume: 0.6),
    _AudioChannel('CH 4', 'WIRED', volume: 0.9),
    _AudioChannel('CH 5', 'MIC', volume: 0.5),
    _AudioChannel('CH 6', 'USB', volume: 0.7),
  ];

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _timerText {
    final h = (_seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((_seconds ~/ 60) % 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get _liveCam => _cams.firstWhere((c) => c.isLive, orElse: () => _cams.first).name;
  String get _previewCam => _cams.firstWhere((c) => c.isPreview, orElse: () => _cams[1]).name;

  void _take() {
    setState(() {
      final oldLive = _cams.indexWhere((c) => c.isLive);
      final oldPrev = _cams.indexWhere((c) => c.isPreview);
      if (oldLive >= 0 && oldPrev >= 0) {
        _cams[oldLive].isLive = false;
        _cams[oldLive].isPreview = true;
        _cams[oldPrev].isPreview = false;
        _cams[oldPrev].isLive = true;
      }
    });
  }

  void _selectPreview(int i) {
    setState(() {
      for (final c in _cams) { c.isPreview = false; }
      _cams[i].isPreview = true;
    });
  }

  void _goLiveToggle() {
    setState(() => _onAir = !_onAir);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _statusBar(),
                _cameraStrip(),
                _tabs(),
                Expanded(child: _centerArea()),
                _audioStrip(),
                _actionBar(),
              ],
            ),
            if (_menuOpen) _menuPanel(),
          ],
        ),
      ),
    );
  }

  // ── BAND 1 — STATUS BAR ────────────────────────────
  Widget _statusBar() {
    return Container(
      height: 52,
      color: _bg,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: _onAir ? _red : _textGrey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _onAir ? 'ON AIR' : 'OFFLINE',
            style: TextStyle(
              color: _onAir ? _red : _textGrey,
              fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 14),
          Container(width: 1, height: 22, color: _border),
          const SizedBox(width: 14),
          const Icon(Icons.videocam, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(_liveCam, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(width: 2),
          const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
          const SizedBox(width: 16),
          const Text('720p  30 FPS',
              style: TextStyle(color: _textMid, fontSize: 11, letterSpacing: 1)),
          const Spacer(),
          const Icon(Icons.access_time, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(_timerText,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(width: 18),
          const Icon(Icons.sd_storage, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text('$_mbUsed MB',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(width: 18),
          const Icon(Icons.wifi, color: _green, size: 16),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: () => setState(() => _menuOpen = !_menuOpen),
            child: const Icon(Icons.menu, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  // ── BAND 2 — CAMERA STRIP ──────────────────────────
  Widget _cameraStrip() {
    final items = <Widget>[];
    for (var i = 0; i < _cams.length; i++) {
      items.add(Expanded(child: _camTile(_cams[i], i)));
    }
    items.add(Expanded(child: _addCameraTile()));

    return Container(
      height: 96,
      color: _bg,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: items),
    );
  }

  Widget _camTile(_CamItem cam, int index) {
    final borderColor = cam.isLive
        ? _red
        : cam.isPreview
            ? _yellow
            : _border;
    final borderWidth = (cam.isLive || cam.isPreview) ? 2.0 : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => _selectPreview(index),
        onDoubleTap: () {
          setState(() {
            for (final c in _cams) { c.isLive = false; c.isPreview = false; }
            _cams[index].isLive = true;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: borderColor, width: borderWidth),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              // Faint video placeholder
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.04),
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              ),
              // Tally dot
              Positioned(
                top: 6, left: 6,
                child: Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: cam.isLive
                        ? _red
                        : cam.isPreview
                            ? _yellow
                            : _textGrey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // LIVE badge
              if (cam.isLive)
                Positioned(
                  top: 6, right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _red,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text('LIVE',
                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                ),
              // Name
              Positioned(
                left: 6, bottom: 6,
                child: Text(cam.name,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
              // Signal bars
              Positioned(
                right: 6, bottom: 6,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(4, (i) {
                    return Container(
                      width: 2,
                      height: 3.0 + i * 2,
                      margin: const EdgeInsets.only(left: 1.5),
                      color: _green,
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addCameraTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _textGrey, width: 1, style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.white70, size: 20),
            SizedBox(height: 4),
            Text('Add Camera',
                style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── BAND 3 — TABS ──────────────────────────────────
  Widget _tabs() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: _bg,
      child: Row(
        children: [
          _tab('PROGRAM', 0),
          const SizedBox(width: 28),
          _tab('MULTIVIEW', 1),
        ],
      ),
    );
  }

  Widget _tab(String label, int index) {
    final active = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : _textGrey,
          fontSize: 11,
          fontWeight: active ? FontWeight.w900 : FontWeight.w600,
          letterSpacing: 2,
        ),
      ),
    );
  }

  // ── BAND 4 — CENTER AREA ───────────────────────────
  Widget _centerArea() {
    if (_activeTab == 1) return _multiviewGrid();
    return _programArea();
  }

  Widget _programArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableW = constraints.maxWidth;
          final availableH = constraints.maxHeight;
          final programW = availableW;
          final programH = programW * 9 / 16;
          final h = programH > availableH ? availableH : programH;
          final w = programH > availableH ? availableH * 16 / 9 : programW;

          return Center(
            child: SizedBox(
              width: w,
              height: h,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: _yellow, width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  children: [
                    // Program content (placeholder)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.03),
                              Colors.black,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _liveCam,
                            style: const TextStyle(color: Colors.white24, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 4),
                          ),
                        ),
                      ),
                    ),
                    // PROGRAM badge
                    Positioned(
                      top: 10, left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _red,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text('PROGRAM',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      ),
                    ),
                    // Floating PREVIEW box
                    Positioned(
                      right: 12, bottom: 12,
                      width: w * 0.30,
                      height: w * 0.30 * 9 / 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(color: _yellow, width: 1.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(_previewCam,
                                  style: const TextStyle(color: Colors.white24, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
                            ),
                            Positioned(
                              top: 6, left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _yellow,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: const Text('PREVIEW',
                                    style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                              ),
                            ),
                            Positioned(
                              left: 6, bottom: 6,
                              child: Text(_previewCam,
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _multiviewGrid() {
    final n = _cams.length;
    final cols = n <= 4 ? 2 : 3;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: n,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 16 / 9,
        ),
        itemBuilder: (_, i) {
          final c = _cams[i];
          final border = c.isLive ? _red : (c.isPreview ? _yellow : _border);
          return GestureDetector(
            onTap: () => _selectPreview(i),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: border, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(c.name,
                    style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2)),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── BAND 5 — AUDIO STRIP ───────────────────────────
  Widget _audioStrip() {
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: _bg,
      child: Row(
        children: List.generate(_channels.length, (i) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _channelStrip(_channels[i], i),
            ),
          );
        }),
      ),
    );
  }

  Widget _channelStrip(_AudioChannel ch, int index) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _border, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row: CH name + input badge
          Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(ch.name,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: _blue.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(ch.input,
                    style: const TextStyle(color: _blue, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Meter + slider row
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Level meter (vertical bars)
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: ch.muted ? 0.0 : ch.volume,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [_green, _yellow],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Slider
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      activeTrackColor: _textMid,
                      inactiveTrackColor: _border,
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                      overlayColor: _blue.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: ch.muted ? 0.0 : ch.volume,
                      onChanged: (v) => setState(() => ch.volume = v),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // M + S buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => ch.muted = !ch.muted),
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: ch.muted ? _red : Colors.black,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: _border),
                    ),
                    child: Center(
                      child: Text('M',
                          style: TextStyle(
                            color: ch.muted ? Colors.white : _textGrey,
                            fontSize: 10, fontWeight: FontWeight.w900,
                          )),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => ch.solo = !ch.solo),
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: ch.solo ? _blue : Colors.black,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: _border),
                    ),
                    child: Center(
                      child: Text('S',
                          style: TextStyle(
                            color: ch.solo ? Colors.white : _textGrey,
                            fontSize: 10, fontWeight: FontWeight.w900,
                          )),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── BAND 6 — ACTION BAR ────────────────────────────
  Widget _actionBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: _bg,
      child: Row(
        children: [
          // GO LIVE / END STREAM
          GestureDetector(
            onTap: _goLiveToggle,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: _onAir ? _red : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(_onAir ? Icons.stop_circle : Icons.podcasts,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(_onAir ? 'END STREAM' : 'GO LIVE',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ],
              ),
            ),
          ),
          const Spacer(),
          // DATA BUDGET card
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                const Icon(Icons.storage, color: Colors.white70, size: 16),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DATA BUDGET',
                        style: TextStyle(color: _textGrey, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                    Text('$_mbUsed MB',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (_mbUsed / 100).clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: Colors.black,
                      valueColor: const AlwaysStoppedAnimation(_green),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // PiP button
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _border),
            ),
            child: const Row(
              children: [
                Icon(Icons.picture_in_picture_alt, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('PiP',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // TAKE button
          GestureDetector(
            onTap: _take,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              decoration: BoxDecoration(
                color: _red,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.fiber_manual_record, color: Colors.white, size: 14),
                  SizedBox(width: 10),
                  Text('TAKE',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 3)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── MENU PANEL ─────────────────────────────────────
  Widget _menuPanel() {
    final items = <_MenuItem>[
      _MenuItem(Icons.title, 'Titles'),
      _MenuItem(Icons.layers, 'Graphics'),
      _MenuItem(Icons.campaign, 'Ads'),
      _MenuItem(Icons.bookmark_border, 'Templates'),
      _MenuItem(Icons.monitor_heart, 'Diagnostics'),
      _MenuItem(Icons.account_circle, 'Accounts'),
      _MenuItem(Icons.key, 'Stream Targets'),
      _MenuItem(Icons.schedule, 'Schedule'),
      _MenuItem(Icons.video_library, 'Recordings'),
      _MenuItem(Icons.settings, 'Settings'),
    ];

    return Positioned(
      top: 0, right: 0, bottom: 0,
      child: Container(
        width: 260,
        color: _bg,
        child: Column(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _border, width: 1)),
              ),
              child: Row(
                children: [
                  const Text('Menu',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _menuOpen = false),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final it = items[i];
                  return InkWell(
                    onTap: () {
                      setState(() => _menuOpen = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${it.label} — opens soon'), duration: const Duration(seconds: 1)),
                      );
                    },
                    child: SizedBox(
                      height: 46,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(it.icon, color: Colors.white70, size: 18),
                            const SizedBox(width: 14),
                            Text(it.label,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  _MenuItem(this.icon, this.label);
}
DART_EOF
echo "=== File written ===" && \
wc -l lib/director_mode/director_screen.dart && \
echo "" && \
echo "=== Analyze ===" && \
flutter analyze 2>&1 | tail -8 && \
echo "" && \
echo "=== RELEASE BUILD ===" && \
flutter clean > /dev/null 2>&1 && \
flutter pub get > /dev/null 2>&1 && \
flutter build apk --release 2>&1 | tail -8 && \
echo "" && \
mkdir -p ~/apk-share && \
cp build/app/outputs/flutter-apk/app-release.apk ~/apk-share/MobileTVStudio.apk && \
ls -la ~/apk-share/MobileTVStudio.apk && \
pkill -f "http.server 8000" 2>/dev/null; \
cd ~/apk-share && nohup python3 -m http.server 8000 > /tmp/apk-server.log 2>&1 & \
sleep 2 && \
curl -s http://localhost:8000/MobileTVStudio.apk -o /dev/null -w "HTTP %{http_code}\n"
