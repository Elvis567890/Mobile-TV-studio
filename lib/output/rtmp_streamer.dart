import 'dart:async';
import 'platform_targets.dart';

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
  double get megabytesSent => _bytesSent / (1024 * 1024);

  DateTime? _startedAt;
  Duration get uptime => _startedAt == null
      ? Duration.zero
      : DateTime.now().difference(_startedAt!);

  Future<void> start() async {
    _state = StreamState.connecting;
    _stateController.add(_state);
    await Future.delayed(const Duration(milliseconds: 200));
    _startedAt = DateTime.now();
    _state = StreamState.live;
    _stateController.add(_state);
  }

  void reportBytes(int n) => _bytesSent += n;

  Future<void> stop() async {
    _startedAt = null;
    _state = StreamState.idle;
    _stateController.add(_state);
  }

  Future<void> dispose() async {
    await stop();
    await _stateController.close();
  }
}
