import 'dart:typed_data';
import 'video_transport.dart';

class BluetoothTransport implements VideoTransport {
  BluetoothTransport({required this.remoteMac});
  final String remoteMac;

  @override
  String get name => 'Bluetooth';

  @override
  int get maxBitrateKbps => 600;

  @override
  TransportQuality get bestQuality => TransportQuality.low360p;

  @override
  bool get isRunning => false;

  @override
  void Function()? onLost;

  @override
  void Function()? onReady;

  void sendChunk(Uint8List chunk) {}

  @override
  Future<void> start() async {
    throw UnsupportedError('Bluetooth video coming in a later build.');
  }

  @override
  Future<void> stop() async {}
}
