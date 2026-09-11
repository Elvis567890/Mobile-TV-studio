import 'dart:async';

import 'package:flutter/foundation.dart';

import 'platform_targets.dart';
import 'rtmp_streamer.dart';

/// Runs several RTMP outputs at once. Each target has its own state,
/// its own uptime, and its own byte count. One failing output does not
/// stop the others — this is the whole point.
class MultiStreamer {
  MultiStreamer({required this.targets});

  final List<StreamTarget> targets;

  final _streamers = <String, RtmpStreamer>{};
  final _stateController = StreamController<void>.broadcast();

  /// Notifies when any output changes state.
  Stream<void> get changes => _stateController.stream;

  bool _running = false;
  bool get running => _running;

  List<RtmpStreamer> get outputs =>
      _streamers.values.toList(growable: false);

  /// Total MB sent across every output this session.
  double get totalMegabytes {
    var total = 0.0;
    for (final s in _streamers.values) {
      total += s.megabytesSent;
    }
    return total;
  }

  /// How many outputs are currently live.
  int get liveCount =>
      _streamers.values.where((s) => s.state == StreamState.live).length;

  Future<void> start() async {
    if (_running) return;
    _running = true;

    for (final t in targets) {
      final s = RtmpStreamer(target: t);
      _streamers[t.id] = s;
      s.stateStream.listen((_) => _stateController.add(null));

      // Fire all of them in parallel. Do not await each in sequence.
      unawaited(s.start());
    }

    _stateController.add(null);
  }

  /// Called from the encoder for every muxed chunk.
  /// Sends the same bytes to every output.
  void reportBytes(int n) {
    for (final s in _streamers.values) {
      s.reportBytes(n);
    }
  }

  Future<void> stopAll() async {
    _running = false;
    await Future.wait(_streamers.values.map((s) => s.stop()));
    _stateController.add(null);
  }

  /// Restart one output that failed.
  Future<void> restart(String targetId) async {
    final s = _streamers[targetId];
    if (s == null) return;
    await s.stop();
    await s.start();
    _stateController.add(null);
  }

  Future<void> dispose() async {
    await stopAll();
    for (final s in _streamers.values) {
      await s.dispose();
    }
    _streamers.clear();
    await _stateController.close();
  }
}

/// Convenience: build a MultiStreamer from a list of targets loaded
/// from disk.
Future<MultiStreamer> buildMultiStreamerFromStore({
  required List<String> enabledTargetIds,
}) async {
  final store = TargetStore();
  final all = await store.loadAll();
  final chosen = all.where((t) => enabledTargetIds.contains(t.id)).toList();
  return MultiStreamer(targets: chosen);
}

/// Prints the current state of every output. Useful for debugging
/// during development, harmless in production.
void debugPrintOutputs(MultiStreamer m) {
  for (final s in m.outputs) {
    debugPrint(
      '[stream] ${s.target.displayName} → ${s.state.name} '
      '${s.megabytesSent.toStringAsFixed(1)} MB '
      'uptime ${s.uptime.inSeconds}s',
    );
  }
}
