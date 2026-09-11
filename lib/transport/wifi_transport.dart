import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'video_transport.dart';

/// WebRTC over the local Wi-Fi network.
/// Two phones on the same hotspot use this. Highest quality, lowest
/// data cost — video never leaves the room.
class WifiTransport implements VideoTransport {
  WifiTransport({
    required this.localId,
    required this.remoteId,
  });

  final String localId;
  final String remoteId;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  bool _running = false;
  final _pendingCandidates = <RTCIceCandidate>[];

  @override
  String get name => 'Wi-Fi';

  @override
  int get maxBitrateKbps => 4500;

  @override
  TransportQuality get bestQuality => TransportQuality.ultra1080p;

  @override
  bool get isRunning => _running;

  @override
  void Function()? onLost;

  @override
  void Function()? onReady;

  static const _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  @override
  Future<void> start() async {
    if (_running) return;

    _pc = await createPeerConnection(_iceConfig);

    _pc!.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        _running = true;
        onReady?.call();
      } else if (state ==
              RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
        _running = false;
        onLost?.call();
      }
    };

    _pc!.onIceCandidate = (candidate) {
      // Send candidate over the signaling channel (added in a later file).
    };

    // Capture camera + mic and attach.
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': 'environment',
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
        'frameRate': {'ideal': 30},
      },
    });

    for (final track in _localStream!.getTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }

    // Tune sender bitrate for the quality target.
    final senders = await _pc!.getSenders();
    for (final s in senders) {
      final params = s.parameters;
      if (params.encodings != null && params.encodings!.isNotEmpty) {
        params.encodings!.first.maxBitrate = bestQuality.kbps * 1000;
        await s.setParameters(params);
      }
    }

    // Drain any candidates that arrived before the PC was ready.
    for (final c in _pendingCandidates) {
      await _pc!.addCandidate(c);
    }
    _pendingCandidates.clear();
  }

  /// Called from the signaling layer when a remote candidate arrives.
  Future<void> addRemoteCandidate(RTCIceCandidate c) async {
    if (_pc == null) {
      _pendingCandidates.add(c);
      return;
    }
    await _pc!.addCandidate(c);
  }

  /// Called from the signaling layer when a remote offer arrives.
  Future<RTCSessionDescription> acceptOffer(
    RTCSessionDescription offer,
  ) async {
    await _pc!.setRemoteDescription(offer);
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    return answer;
  }

  Future<RTCSessionDescription> createOffer() async {
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    return offer;
  }

  Future<void> acceptAnswer(RTCSessionDescription answer) async {
    await _pc!.setRemoteDescription(answer);
  }

  @override
  Future<void> stop() async {
    _running = false;
    for (final t in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      await t.stop();
    }
    await _localStream?.dispose();
    _localStream = null;
    await _pc?.close();
    await _pc?.dispose();
    _pc = null;
  }
}
