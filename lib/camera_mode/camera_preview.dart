import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Native bridge handle for the camera.
class NativeCamera {
  static const _channel = MethodChannel('mobile_tv_studio/native/camera');

  /// List cameras on this device.
  static Future<List<Map<String, String>>> listCameras() async {
    final raw = await _channel.invokeMethod<List<dynamic>>('listCameras');
    if (raw == null) return [];
    return raw
        .cast<Map<dynamic, dynamic>>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v.toString())))
        .toList();
  }

  /// Start the native preview on the chosen camera.
  static Future<bool> startPreview({
    required String cameraId,
    int width = 1280,
    int height = 720,
    int fps = 30,
  }) async {
    final ok = await _channel.invokeMethod<bool>('startPreview', {
      'cameraId': cameraId,
      'width': width,
      'height': height,
      'fps': fps,
    });
    return ok ?? false;
  }

  static Future<void> stopPreview() async {
    await _channel.invokeMethod<void>('stopPreview');
  }
}

/// A Flutter widget that reserves a rectangle for the native preview.
///
/// The native side draws onto a Surface placed behind the Flutter view.
/// Until that Surface is attached, this widget shows a clear "camera
/// warming up" state so the UI is honest about what is happening.
class CameraPreview extends StatefulWidget {
  final String cameraId;
  final int width;
  final int height;
  final int fps;
  final bool active;

  const CameraPreview({
    super.key,
    required this.cameraId,
    this.width = 1280,
    this.height = 720,
    this.fps = 30,
    this.active = true,
  });

  @override
  State<CameraPreview> createState() => _CameraPreviewState();
}

class _CameraPreviewState extends State<CameraPreview> {
  bool _starting = false;
  String? _error;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) _start();
  }

  @override
  void didUpdateWidget(covariant CameraPreview old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _start();
    } else if (!widget.active && old.active) {
      _stop();
    }
    if (widget.cameraId != old.cameraId && widget.active) {
      _stop().then((_) => _start());
    }
  }

  Future<void> _start() async {
    if (_starting || _running) return;
    setState(() {
      _starting = true;
      _error = null;
    });

    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _starting = false;
          _error = 'Camera preview is not available on web.';
        });
      }
      return;
    }

    try {
      final ok = await NativeCamera.startPreview(
        cameraId: widget.cameraId,
        width: widget.width,
        height: widget.height,
        fps: widget.fps,
      );
      if (!mounted) return;
      setState(() {
        _starting = false;
        _running = ok;
        if (!ok) _error = 'Camera failed to start.';
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _running = false;
        _error = e.message ?? 'Camera error';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _running = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _stop() async {
    if (!_running) return;
    try {
      await NativeCamera.stopPreview();
    } catch (_) {}
    if (mounted) {
      setState(() => _running = false);
    }
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.videocam_off,
                  color: Colors.redAccent,
                  size: 56,
                ),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _start,
                  child: const Text('RETRY'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_starting) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.redAccent),
              SizedBox(height: 14),
              Text(
                'STARTING CAMERA…',
                style: TextStyle(
                  color: Colors.white38,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // The native Surface is drawn underneath this Flutter widget.
    // Leave it transparent so the camera shows through.
    return const ColoredBox(
      color: Colors.transparent,
      child: SizedBox.expand(),
    );
  }
}
