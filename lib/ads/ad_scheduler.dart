import 'dart:async';

import 'ad_playlist.dart';

/// Watches the clock and fires a callback when it is time for a break.
///
/// Simple, predictable, and correct: every N minutes, on the second,
/// the director shows the next ad in the playlist.
class AdScheduler {
  AdScheduler({
    required this.playlist,
    required this.onBreakDue,
  });

  final AdPlaylist playlist;

  /// Called when the scheduler decides it is time for an ad.
  /// The director is expected to switch its program feed to the ad.
  final void Function(AdClip clip) onBreakDue;

  Timer? _timer;
  bool _enabled = false;
  Duration _interval = const Duration(minutes: 10);
  int _clipIndex = 0;
  DateTime? _lastBreakAt;

  bool get enabled => _enabled;
  Duration get interval => _interval;
  DateTime? get lastBreakAt => _lastBreakAt;

  Duration get timeUntilNext {
    if (_lastBreakAt == null) return _interval;
    final elapsed = DateTime.now().difference(_lastBreakAt!);
    final remaining = _interval - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void start({
    Duration interval = const Duration(minutes: 10),
  }) {
    if (playlist.clips.isEmpty) return;
    _interval = interval;
    _enabled = true;
    _lastBreakAt = DateTime.now();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void stop() {
    _enabled = false;
    _timer?.cancel();
    _timer = null;
  }

  void setInterval(Duration d) {
    _interval = d;
    _lastBreakAt = DateTime.now();
  }

  void _tick(Timer _) {
    if (!_enabled) return;
    if (playlist.clips.isEmpty) return;

    final elapsed = DateTime.now().difference(_lastBreakAt!);
    if (elapsed < _interval) return;

    _lastBreakAt = DateTime.now();

    final clip = playlist.clips[_clipIndex % playlist.clips.length];
    _clipIndex++;

    if (clip.exists) {
      onBreakDue(clip);
    }
  }

  /// Skip the wait and fire the next ad immediately.
  void triggerNow() {
    if (playlist.clips.isEmpty) return;
    final clip = playlist.clips[_clipIndex % playlist.clips.length];
    _clipIndex++;
    _lastBreakAt = DateTime.now();
    if (clip.exists) onBreakDue(clip);
  }

  void dispose() {
    _timer?.cancel();
  }
}
