import 'dart:async';

import 'package:flutter/material.dart';

enum RecordingState { idle, preparing, recording, stopping, error }

/// Owns the state of a local recording of the full program feed.
/// The bytes themselves are written by the native encoder bridge,
/// which will be wired in the native batch. This file owns the state
/// machine and the UI so the operator experience is complete.
class RecordingController extends ChangeNotifier {
  RecordingState _state = RecordingState.idle;
  RecordingState get state => _state;

  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;

  Duration get elapsed => _elapsed;

  int _bytesWritten = 0;
  int get bytesWritten => _bytesWritten;

  double get megabytesWritten => _bytesWritten / (1024 * 1024);

  bool get isRecording => _state == RecordingState.recording;

  Future<void> start() async {
    if (_state == RecordingState.recording) return;
    _setState(RecordingState.preparing);

    try {
      // Native call to begin recording goes here.
      await Future.delayed(const Duration(milliseconds: 400));

      _startedAt = DateTime.now();
      _elapsed = Duration.zero;
      _bytesWritten = 0;
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsed = DateTime.now().difference(_startedAt!);
        notifyListeners();
      });

      _setState(RecordingState.recording);
    } catch (_) {
      _setState(RecordingState.error);
    }
  }

  Future<void> stop() async {
    if (_state != RecordingState.recording) return;
    _setState(RecordingState.stopping);
    _ticker?.cancel();

    try {
      // Native call to stop and close the file goes here.
      await Future.delayed(const Duration(milliseconds: 200));
      _setState(RecordingState.idle);
    } catch (_) {
      _setState(RecordingState.error);
    }
  }

  void reportBytes(int n) {
    _bytesWritten += n;
    notifyListeners();
  }

  void _setState(RecordingState s) {
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

/// Small panel that shows the current recording state and stats.
class RecordingPanel extends StatelessWidget {
  final RecordingController controller;

  const RecordingPanel({super.key, required this.controller});

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get _label {
    switch (controller.state) {
      case RecordingState.idle:
        return 'RECORD';
      case RecordingState.preparing:
        return 'PREPARING…';
      case RecordingState.recording:
        return 'STOP REC';
      case RecordingState.stopping:
        return 'STOPPING…';
      case RecordingState.error:
        return 'ERROR';
    }
  }

  Color get _color {
    switch (controller.state) {
      case RecordingState.idle:
        return Colors.white54;
      case RecordingState.preparing:
      case RecordingState.stopping:
        return Colors.orangeAccent;
      case RecordingState.recording:
        return Colors.redAccent;
      case RecordingState.error:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final rec = controller.isRecording;
        return Container(
          color: const Color(0xFF14141A),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'LOCAL RECORDING',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (rec)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    rec ? _formatDuration(controller.elapsed) : '—',
                    style: TextStyle(
                      color: _color,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  if (rec)
                    Text(
                      '${controller.megabytesWritten.toStringAsFixed(1)} MB',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    if (rec) {
                      controller.stop();
                    } else {
                      controller.start();
                    }
                  },
                  icon: Icon(rec ? Icons.stop : Icons.fiber_manual_record),
                  label: Text(_label),
                  style: FilledButton.styleFrom(
                    backgroundColor: _color,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
