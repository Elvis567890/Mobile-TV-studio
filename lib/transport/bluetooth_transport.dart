import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'video_transport.dart';

/// Video over Bluetooth Classic RFCOMM.
///
/// ANDROID ONLY. iOS blocks RFCOMM for third-party apps. On iOS this
/// transport immediately reports failure so the selector falls through
/// to the internet transport.
///
/// Ceiling: roughly 360p @ 15-24fps. This is a fallback, not a primary.
class BluetoothTransport implements VideoTransport {
  BluetoothTransport({required this.remoteMac});

  final String remoteMac;

  BluetoothConnection? _connection;
  bool _running = false;
  final _writeQueue = <Uint8List>[];
  bool _writing = false;

  @override
  String get name => 'Bluetooth';

  @override
  int get maxBitrateKbps => 600;

  @override
  TransportQuality get bestQuality => TransportQuality.low360p;

  @override
  bool get isRunning => _running;

  @override
  void Function()? onLost;

  @override
  void Function()? onReady;

  /// Send a video chunk. Chunks must be <= 990 bytes so they fit in a
  /// single RFCOMM packet. Caller is responsible for splitting.
  void sendChunk(Uint8List chunk) {
    if (!_running || _connection == null) return;
    if (chunk.length > 990) {
      throw ArgumentError('Bluetooth chunk too large: ${chunk.length} bytes');
    }
    _writeQueue.add(chunk);
    _drainQueue();
  }

  Future<void> _drainQueue() async {
    if (_writing) return;
    _writing = true;
    while (_writeQueue.isNotEmpty) {
      final chunk = _writeQueue.removeAt(0);
      try {
        _connection!.output.add(chunk);
        await _connection!.output.allSent;
      } catch (_) {
        _running = false;
        onLost?.call();
        break;
      }
    }
    _writing = false;
  }

  @override
  Future<void> start() async {
    if (kIsWeb || Platform.isIOS) {
      // Apple does not permit this. Fail fast so the selector moves on.
      throw UnsupportedError(
        'Bluetooth video is not available on iOS. Apple blocks RFCOMM.',
      );
    }
    if (_running) return;

    try {
      await FlutterBluetoothSerial.instance.requestEnable();
      _connection = await BluetoothConnection.toAddress(remoteMac);

      _connection!.input!.listen(
        _onData,
        onDone: () {
          _running = false;
          onLost?.call();
        },
        onError: (_) {
          _running = false;
          onLost?.call();
        },
      );

      _running = true;
      onReady?.call();
    } catch (_) {
      _running = false;
      rethrow;
    }
  }

  final _incoming = <int>[];
  void Function(Uint8List chunk)? onChunkReceived;

  void _onData(Uint8List data) {
    _incoming.addAll(data);
    // Reassembly of H.264 NAL units happens in the decoder layer.
    onChunkReceived?.call(Uint8List.fromList(data));
  }

  @override
  Future<void> stop() async {
    _running = false;
    _writeQueue.clear();
    await _connection?.close();
    _connection = null;
  }

  /// List paired devices so the UI can let the user choose.
  static Future<List<BluetoothDevice>> pairedDevices() async {
    return FlutterBluetoothSerial.instance.getBondedDevices();
  }
}
