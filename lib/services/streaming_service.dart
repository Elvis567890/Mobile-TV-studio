import 'dart:async';
import 'package:camera/camera.dart';
import 'package:rtmp_broadcaster/rtmp_broadcaster.dart';
import 'package:mic_info/mic_info.dart';

class StreamingService {
  static CameraController? _controller;
  static bool _isStreaming = false;
  static bool _isRecording = false;

  static CameraController? get controller => _controller;
  static bool get isStreaming => _isStreaming;
  static bool get isRecording => _isRecording;

  static Future<CameraController?> initialize({bool front = false}) async {
    final cams = await availableCameras();
    if (cams.isEmpty) return null;
    final lens = front
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    final cam = cams.firstWhere(
      (c) => c.lensDirection == lens,
      orElse: () => cams.first,
    );
    _controller = CameraController(cam, ResolutionPreset.high,
        enableAudio: true);
    await _controller!.initialize();
    return _controller;
  }

  static Future<List<String>> detectUsbMics() async {
    try {
      final mics = await MicInfo.getWiredMicrophones();
      return mics.map((m) => m.productName).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> startStream({
    required String rtmpUrl,
    required String streamKey,
    int bitrate = 2500 * 1024,
  }) async {
    if (_controller == null) return;
    final url = '$rtmpUrl/$streamKey';
    await _controller!.startVideoStreaming(url, bitrate: bitrate);
    _isStreaming = true;
  }

  static Future<void> stopStream() async {
    if (_controller == null) return;
    await _controller!.stopEverything();
    _isStreaming = false;
  }

  static Future<void> startRecording(String path) async {
    if (_controller == null) return;
    await _controller!.startVideoRecording();
    _isRecording = true;
  }

  static Future<void> stopRecording() async {
    if (_controller == null) return;
    await _controller!.stopVideoRecording();
    _isRecording = false;
  }

  static Future<void> switchCamera() async {
    if (_controller == null) return;
    final cams = await availableCameras();
    final current = _controller!.description.lensDirection;
    final target = current == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    final cam = cams.firstWhere(
      (c) => c.lensDirection == target,
      orElse: () => cams.first,
    );
    await _controller!.dispose();
    _controller = CameraController(cam, ResolutionPreset.high,
        enableAudio: true);
    await _controller!.initialize();
  }

  static Future<void> muteMic(bool muted) async {
    if (_controller == null) return;
    await _controller!.setMicrophoneMute(muted);
  }

  static Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isStreaming = false;
    _isRecording = false;
  }
}
