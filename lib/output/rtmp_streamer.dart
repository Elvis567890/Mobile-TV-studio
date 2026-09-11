import 'dart:async';

import 'package:flutter/foundation.dart';

import 'platform_targets.dart';

/// State of a single RTMP output.
enum StreamState { idle, connecting, live, error }

class RtmpStreamer {
  RtmpStreamer({required this.target});

  final StreamTarget target;

  StreamState _state = StreamState.idle;
  StreamState get state => _state;

  final _stateController = StreamController<StreamState>.broadcast();
  Stream<StreamState> get stateStream => _stateController.stream;

  int _bytesSent = 0;
  int get bytesSent => _bytesSent;

  /// Approximate MB sent since going live.
  double get megabytesSent => _bytesSent / (1024 * 1024);

  DateTime? _startedAt;
  Duration get uptime =>
      _startedAt == null ? Duration.zero : DateTime.now().difference(_startedAt!);

  /// Begin publishing. In a full build this calls into a native
  /// RTMP library that muxes the mixed video+audio into FLV and
  /// pushes it to `target.fullUrl`.
  ///
  /// The native side is wired in a later batch. This class owns the
  /// state machine and stats so the UI is already complete.
  Future<void> start() async {
    _setState(StreamState.connecting);
    try {
      // Placeholder for the native RTMP publish call.
      // On Android: a MediaCodec -> FLV muxer -> RTMP socket.
      // On iOS:     VideoToolbox -> FLV muxer -> RTMP socket.
      await Future.delayed(const Duration(milliseconds: 600));

      _startedAt = DateTime.now();
      _bytesSent = 0;
      _setState(StreamState.live);
    } catch (e) {
      _setState(StreamState.error);
      debugPrint('RTMP start failed: $e');
    }
  }

  /// Call from the encoder for every muxed chunk.
  void reportBytes(int n) {
    _bytesSent += n;
  }

  Future<void> stop() async {
    _startedAt = null;
    _setState(StreamState.idle);
  }

  void _setState(StreamState s) {
    _state = s;
    if (!_stateController.isClosed) _stateController.add(s);
  }

  Future<void> dispose() async {
    await stop();
    await _stateController.close();
  }
}
