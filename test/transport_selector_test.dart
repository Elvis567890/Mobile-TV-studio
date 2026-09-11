import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tv_studio/transport/video_transport.dart';
import 'package:mobile_tv_studio/transport/transport_selector.dart';
import 'package:mobile_tv_studio/transport/markers.dart';

/// A fake transport used only in tests. Records what happened.
class FakeTransport implements VideoTransport {
  final String _name;
  final bool failOnStart;

  bool started = false;
  bool stopped = false;
  bool _running = false;

  FakeTransport({
    required String name,
    this.failOnStart = false,
  }) : _name = name;

  @override
  String get name => _name;

  @override
  int get maxBitrateKbps => 1000;

  @override
  TransportQuality get bestQuality => TransportQuality.medium480p;

  @override
  bool get isRunning => _running;

  @override
  void Function()? onLost;

  @override
  void Function()? onReady;

  @override
  Future<void> start() async {
    started = true;
    if (failOnStart) {
      throw StateError('forced failure');
    }
    _running = true;
    onReady?.call();
  }

  @override
  Future<void> stop() async {
    stopped = true;
    _running = false;
  }

  void simulateLoss() {
    _running = false;
    onLost?.call();
  }
}

class FakeWifi extends FakeTransport implements WifiMarker {
  FakeWifi({bool failOnStart = false})
      : super(name: 'Wi-Fi', failOnStart: failOnStart);
}

class FakeInternet extends FakeTransport implements InternetMarker {
  FakeInternet({bool failOnStart = false})
      : super(name: 'Internet', failOnStart: failOnStart);
}

class FakeBluetooth extends FakeTransport implements BluetoothMarker {
  FakeBluetooth({bool failOnStart = false})
      : super(name: 'Bluetooth', failOnStart: failOnStart);
}

void main() {
  group('TransportSelector', () {
    test('boots onto Wi-Fi when available', () async {
      final wifi = FakeWifi();
      final selector = TransportSelector(
        wifiFactory: () => wifi,
        internetFactory: () => FakeInternet(),
        bluetoothFactory: () => FakeBluetooth(),
      );

      await selector.boot(wifiAvailable: true, internetAvailable: true);

      expect(selector.state, SelectorState.wifi);
      expect(wifi.started, true);

      await selector.shutdown();
    });

    test('falls back to internet when Wi-Fi is not available', () async {
      final internet = FakeInternet();
      final selector = TransportSelector(
        wifiFactory: () => FakeWifi(),
        internetFactory: () => internet,
        bluetoothFactory: () => FakeBluetooth(),
      );

      await selector.boot(wifiAvailable: false, internetAvailable: true);

      expect(selector.state, SelectorState.internet);
      expect(internet.started, true);

      await selector.shutdown();
    });

    test('falls back to Bluetooth when neither Wi-Fi nor internet is available',
        () async {
      final bt = FakeBluetooth();
      final selector = TransportSelector(
        wifiFactory: () => FakeWifi(),
        internetFactory: () => FakeInternet(),
        bluetoothFactory: () => bt,
      );

      await selector.boot(wifiAvailable: false, internetAvailable: false);

      expect(selector.state, SelectorState.bluetooth);
      expect(bt.started, true);

      await selector.shutdown();
    });

    test('moves to internet when Wi-Fi drops', () async {
      final wifi = FakeWifi();
      final internet = FakeInternet();
      final selector = TransportSelector(
        wifiFactory: () => wifi,
        internetFactory: () => internet,
        bluetoothFactory: () => FakeBluetooth(),
      );

      await selector.boot(wifiAvailable: true, internetAvailable: true);
      expect(selector.state, SelectorState.wifi);

      wifi.simulateLoss();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(selector.state, SelectorState.internet);
      expect(internet.started, true);

      await selector.shutdown();
    });

    test('moves to Bluetooth when internet drops after Wi-Fi is gone', () async {
      final wifi = FakeWifi();
      final internet = FakeInternet();
      final bt = FakeBluetooth();

      final selector = TransportSelector(
        wifiFactory: () => wifi,
        internetFactory: () => internet,
        bluetoothFactory: () => bt,
      );

      await selector.boot(wifiAvailable: true, internetAvailable: true);
      wifi.simulateLoss();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(selector.state, SelectorState.internet);

      internet.simulateLoss();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(selector.state, SelectorState.bluetooth);
      expect(bt.started, true);

      await selector.shutdown();
    });

    test('goes offline when everything is gone', () async {
      final wifi = FakeWifi();
      final internet = FakeInternet();
      final bt = FakeBluetooth();

      final selector = TransportSelector(
        wifiFactory: () => wifi,
        internetFactory: () => internet,
        bluetoothFactory: () => bt,
      );

      await selector.boot(wifiAvailable: true, internetAvailable: true);
      wifi.simulateLoss();
      await Future.delayed(const Duration(milliseconds: 50));
      internet.simulateLoss();
      await Future.delayed(const Duration(milliseconds: 50));
      bt.simulateLoss();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(selector.state, SelectorState.offline);

      await selector.shutdown();
    });

    test('emits state changes on the stream', () async {
      final wifi = FakeWifi();
      final selector = TransportSelector(
        wifiFactory: () => wifi,
        internetFactory: () => FakeInternet(),
        bluetoothFactory: () => FakeBluetooth(),
      );

      final seen = <SelectorState>[];
      final sub = selector.stateStream.listen(seen.add);

      await selector.boot(wifiAvailable: true, internetAvailable: true);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(seen.contains(SelectorState.wifi), true);

      await sub.cancel();
      await selector.shutdown();
    });
  });

  group('TransportQuality', () {
    test('labels are correct', () {
      expect(TransportQuality.low360p.label, '360p');
      expect(TransportQuality.medium480p.label, '480p');
      expect(TransportQuality.high720p.label, '720p');
      expect(TransportQuality.ultra1080p.label, '1080p');
    });

    test('bitrates increase with quality', () {
      expect(
        TransportQuality.low360p.kbps < TransportQuality.medium480p.kbps,
        true,
      );
      expect(
        TransportQuality.medium480p.kbps < TransportQuality.high720p.kbps,
        true,
      );
      expect(
        TransportQuality.high720p.kbps < TransportQuality.ultra1080p.kbps,
        true,
      );
    });
  });
}
