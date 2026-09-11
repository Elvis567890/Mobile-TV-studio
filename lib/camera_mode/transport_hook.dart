import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../transport/bluetooth_transport.dart';
import '../transport/internet_transport.dart';
import '../transport/transport_selector.dart';
import '../transport/video_transport.dart';
import '../transport/wifi_transport.dart';
import '../relay/turn_config.dart';

/// The single place that decides which radio is currently carrying
/// this phone's video, and pushes encoded chunks through it.
///
/// The camera screen owns one of these. It creates the transports,
/// boots the selector, and exposes a single `pushChunk` call for the
/// encoder to use.
class CameraTransportHook {
  CameraTransportHook({
    required this.roomId,
    required this.localId,
    this.remoteMacForBluetooth,
  });

  final String roomId;
  final String localId;
  final String? remoteMacForBluetooth;

  late final TransportSelector _selector;
  StreamSubscription<SelectorState>? _stateSub;

  final _stateController =
      StreamController<SelectorState>.broadcast();
  Stream<SelectorState> get stateStream => _stateController.stream;
  SelectorState get state => _selector.state;

  /// How many bytes have been pushed into the current radio.
  int _bytesPushed = 0;
  int get bytesPushed => _bytesPushed;

  /// Set to true if the platform is iOS. Bluetooth video is blocked there.
  bool get bluetoothAllowed => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> boot({
    bool wifiAvailable = true,
    bool internetAvailable = true,
  }) async {
    _selector = TransportSelector(
      wifiFactory: () => WifiTransport(
        localId: localId,
        remoteId: roomId,
      ),
      internetFactory: () => InternetTransport(
        roomId: roomId,
        localId: localId,
        isCaller: true,
      ),
      bluetoothFactory: () {
        if (!bluetoothAllowed) {
          // On iOS the selector will not be able to fall through to
          // Bluetooth. Return a stub that throws so the selector
          // treats it as unavailable.
          return _UnsupportedBluetooth();
        }
        return BluetoothTransport(
          remoteMac: remoteMacForBluetooth ?? '',
        );
      },
    );

    _stateSub = _selector.stateStream.listen((s) {
      if (!_stateController.isClosed) _stateController.add(s);
    });

    await _selector.boot(
      wifiAvailable: wifiAvailable,
      internetAvailable: internetAvailable,
    );
  }

  /// The encoder calls this for every H.264 chunk it produces.
  ///
  /// On Wi-Fi and Internet the chunk is handed to WebRTC, which does
  /// its own packetisation. On Bluetooth the chunk must be split into
  /// 990-byte slices before it can cross RFCOMM.
  void pushChunk(Uint8List chunk) {
    final active = _selector.active;
    if (active == null) return;

    if (active is BluetoothTransport) {
      for (var i = 0; i < chunk.length; i += 990) {
        final end = (i + 990 < chunk.length) ? i + 990 : chunk.length;
        final slice = Uint8List.sublistView(chunk, i, end);
        active.sendChunk(slice);
      }
    } else {
      // WebRTC transports already own their own send path via the
      // attached video track. Nothing to do here for them yet; the
      // encoder surface feeds them directly.
    }

    _bytesPushed += chunk.length;
  }

  Future<void> shutdown() async {
    await _stateSub?.cancel();
    await _selector.shutdown();
    await _stateController.close();
  }
}

/// Used on iOS so the selector sees Bluetooth as unavailable and
/// falls through to the internet transport.
class _UnsupportedBluetooth implements VideoTransport {
  @override
  String get name => 'Bluetooth (unsupported)';

  @override
  int get maxBitrateKbps => 0;

  @override
  TransportQuality get bestQuality => TransportQuality.low360p;

  @override
  bool get isRunning => false;

  @override
  void Function()? onLost;

  @override
  void Function()? onReady;

  @override
  Future<void> start() async {
    throw UnsupportedError('Bluetooth video is not available on iOS.');
  }

  @override
  Future<void> stop() async {}
}
