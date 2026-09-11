import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'video_transport.dart';
import '../relay/signaling_client.dart';
import '../relay/turn_config.dart';

/// WebRTC over the public internet, using a signaling server + STUN/TURN.
/// This is what makes 12 km (or 1,200 km) work. Both phones just need data.
class InternetTransport implements VideoTransport {
  InternetTransport({
    required this.roomId,
    required this.localId,
    required this.isCaller,
  });

  final String roomId;
  final String localId;
  final bool isCaller;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  SignalingClient? _signal;
  bool _running = false;
  final _pendingCandidates = <RTCIceCandidate>[];
  StreamSubscription<SignalingMessage>? _signalSub;

  @override
  String get name => 'Internet';

  @override
  int get maxBitrateKbps => 1500;

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
    if (_running) return;

    _pc = await createPeerConnection(TurnConfig.iceConfig);

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
      _signal?.send(SignalingMessage.candidate(
        room: roomId,
        from: localId,
        sdp: candidate.candidate ?? '',
        mid: candidate.sdpMid ?? '',
        mline: candidate.sdpMLineIndex ?? 0,
      ));
    };

    // Connect to the relay and join the room.
    _signal = SignalingClient(
      serverUrl: TurnConfig.signalingUrl,
      roomId: roomId,
      clientId: localId,
    );
    await _signal!.connect();

    _signalSub = _signal!.messages.listen(_onSignal);

    // Capture camera + mic.
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': 'environment',
        'width': {'ideal': 854},
        'height': {'ideal': 480},
        'frameRate': {'ideal': 24},
      },
    });

    for (final t in _localStream!.getTracks()) {
      await _pc!.addTrack(t, _localStream!);
    }

    // Tune bitrate to save data.
    final senders = await _pc!.getSenders();
    for (final s in senders) {
      final p = s.parameters;
      if (p.encodings != null && p.encodings!.isNotEmpty) {
        p.encodings!.first.maxBitrate = bestQuality.kbps * 1000;
        await s.setParameters(p);
      }
    }

    if (isCaller) {
      final offer = await _pc!.createOffer();
      await _pc!.setLocalDescription(offer);
      _signal!.send(SignalingMessage.offer(
        room: roomId,
        from: localId,
        sdp: offer.sdp ?? '',
      ));
    }

    for (final c in _pendingCandidates) {
      await _pc!.addCandidate(c);
    }
    _pendingCandidates.clear();
  }

  Future<void> _onSignal(SignalingMessage msg) async {
    if (msg.from == localId) return;
    switch (msg.type) {
      case SignalingType.offer:
        await _pc!.setRemoteDescription(
          RTCSessionDescription(msg.sdp, 'offer'),
        );
        final answer = await _pc!.createAnswer();
        await _pc!.setLocalDescription(answer);
        _signal!.send(SignalingMessage.answer(
          room: roomId,
          from: localId,
          sdp: answer.sdp ?? '',
        ));
        break;
      case SignalingType.answer:
        await _pc!.setRemoteDescription(
          RTCSessionDescription(msg.sdp, 'answer'),
        );
        break;
      case SignalingType.candidate:
        final c = RTCIceCandidate(msg.sdp, msg.mid, msg.mline);
        if (_pc == null) {
          _pendingCandidates.add(c);
        } else {
          await _pc!.addCandidate(c);
        }
        break;
      case SignalingType.peerLeft:
        _running = false;
        onLost?.call();
        break;
    }
  }

  @override
  Future<void> stop() async {
    _running = false;
    await _signalSub?.cancel();
    await _signal?.disconnect();
    for (final t in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      await t.stop();
    }
    await _localStream?.dispose();
    await _pc?.close();
    await _pc?.dispose();
    _pc = null;
    _localStream = null;
  }
}
