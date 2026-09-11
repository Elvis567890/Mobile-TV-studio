import 'dart:async';

import 'video_transport.dart';

/// What the selector tells the UI to display.
enum SelectorState {
  offline,
  wifi,
  bluetooth,
  internet,
}

/// Watches the available radios and always keeps the best one running.
/// Priority order:
///   1. Wi-Fi     (best quality, cheapest data)
///   2. Internet  (works at any distance, uses mobile data)
///   3. Bluetooth (fallback when nothing else works, low quality)
class TransportSelector {
  TransportSelector({
    required this.wifiFactory,
    required this.bluetoothFactory,
    required this.internetFactory,
  });

  final VideoTransport Function() wifiFactory;
  final VideoTransport Function() bluetoothFactory;
  final VideoTransport Function() internetFactory;

  VideoTransport? _active;
  SelectorState _state = SelectorState.offline;
  Timer? _watchdog;

  final _stateController = StreamController<SelectorState>.broadcast();
  Stream<SelectorState> get stateStream => _stateController.stream;
  SelectorState get state => _state;

  VideoTransport? get active => _active;

  /// Called once at the start of a session.
  Future<void> boot({bool wifiAvailable = true, bool internetAvailable = true}) async {
    await _switchTo(
      wifiAvailable
          ? wifiFactory()
          : internetAvailable
              ? internetFactory()
              : bluetoothFactory(),
    );
  }

  Future<void> _switchTo(VideoTransport next) async {
    final old = _active;
    _active = next;

    next.onLost = _handleLost;
    next.onReady = _handleReady;

    try {
      await next.start();
    } catch (_) {
      // If the preferred transport fails outright, fall through.
      await _fallbackFrom(next);
      return;
    }

    if (old != null && old != next) {
      await old.stop();
    }

    _state = _stateFor(next);
    _stateController.add(_state);
    _startWatchdog();
  }

  void _handleReady() {
    _state = _stateFor(_active!);
    _stateController.add(_state);
  }

  void _handleLost() {
    final lost = _active;
    if (lost == null) return;
    // Do not await — react immediately.
    _fallbackFrom(lost);
  }

  Future<void> _fallbackFrom(VideoTransport lost) async {
    // Try next radio in priority order.
    final next = lost is _WifiMarker
        ? internetFactory()
        : lost is _InternetMarker
            ? bluetoothFactory()
            : null;

    if (next == null) {
      _state = SelectorState.offline;
      _stateController.add(_state);
      return;
    }
    await _switchTo(next);
  }

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 5), (_) {
      final a = _active;
      if (a == null || !a.isRunning) return;
      // Real health check is added in the relay batch.
    });
  }

  SelectorState _stateFor(VideoTransport t) {
    if (t is _WifiMarker) return SelectorState.wifi;
    if (t is _InternetMarker) return SelectorState.internet;
    if (t is _BluetoothMarker) return SelectorState.bluetooth;
    return SelectorState.offline;
  }

  Future<void> shutdown() async {
    _watchdog?.cancel();
    await _active?.stop();
    _active = null;
    _state = SelectorState.offline;
    _stateController.add(_state);
    await _stateController.close();
  }
}

/// Marker interfaces so the selector can identify which radio is active
/// without importing every transport implementation.
abstract class _WifiMarker {}
abstract class _InternetMarker {}
abstract class _BluetoothMarker {}
