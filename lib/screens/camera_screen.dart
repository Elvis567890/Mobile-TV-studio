import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/streaming_service.dart';
import '../services/account_store.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _live = false;
  bool _recording = false;
  bool _micMuted = false;
  bool _front = false;
  String _quality = '720p';
  int _fps = 30;
  String _status = 'READY';
  List<String> _usbMics = [];
  CameraController? _cam;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _cam = await StreamingService.initialize(front: _front);
    final mics = await StreamingService.detectUsbMics();
    if (mounted) setState(() { _usbMics = mics; });
  }

  void _cycleQ() {
    setState(() {
      if (_quality == '720p') _quality = '480p';
      else if (_quality == '480p') _quality = '360p';
      else _quality = '720p';
    });
  }

  void _cycleF() {
    setState(() {
      final o = [24, 25, 30, 35, 60];
      _fps = o[(o.indexOf(_fps) + 1) % o.length];
    });
  }

  Future<void> _toggleLive() async {
    if (_live) {
      await StreamingService.stopStream();
      setState(() { _live = false; _status = 'STOPPED'; });
    } else {
      final store = AccountStore();
      final accounts = await store.loadAll();
      if (accounts.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(
              'Link an account first (Director > Menu > Link Accounts)')),
          );
        }
        return;
      }
      final acct = accounts.first;
      setState(() => _status = 'CONNECTING...');
      try {
        await StreamingService.startStream(
          rtmpUrl: acct.rtmpUrl,
          streamKey: acct.streamKey,
        );
        setState(() { _live = true; _status = 'LIVE'; });
      } catch (e) {
        setState(() => _status = 'ERROR: $e');
      }
    }
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      await StreamingService.stopRecording();
      setState(() { _recording = false; _status = 'RECORDING SAVED'; });
    } else {
      final path = '/storage/emulated/0/Movies/abrimax_'
          '${DateTime.now().millisecondsSinceEpoch}.mp4';
      await StreamingService.startRecording(path);
      setState(() { _recording = true; _status = 'RECORDING'; });
    }
  }

  @override
  void dispose() {
    StreamingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: const Text('CAMERA NODE', style: TextStyle(
          fontSize: 14, letterSpacing: 3, fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFF141418),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: Text(
              _status,
              style: TextStyle(
                color: _live ? Colors.green
                    : (_recording ? Colors.orange : Colors.grey),
                fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1,
              ),
            )),
          ),
        ],
      ),
      body: Row(children: [
        Expanded(child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _live ? Colors.red : Colors.white24,
              width: _live ? 3 : 1)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: _cam != null && _cam!.value.isInitialized
                ? CameraPreview(_cam!)
                : const Center(child: CircularProgressIndicator(
                    color: Colors.redAccent)),
          ),
        )),
        Container(width: 160, color: const Color(0xFF141418),
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(child: Column(children: [
            if (_usbMics.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.tealAccent.withOpacity(0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.usb, color: Colors.tealAccent, size: 14),
                  const SizedBox(width: 4),
                  Expanded(child: Text(
                    _usbMics.first,
                    style: const TextStyle(
                      color: Colors.tealAccent, fontSize: 8),
                    overflow: TextOverflow.ellipsis,
                  )),
                ]),
              ),
            _btn(_live ? Icons.stop : Icons.play_arrow,
              _live ? 'STOP' : 'GO LIVE',
              _live ? Colors.red : Colors.green, 78, _toggleLive),
            const SizedBox(height: 8),
            _btn(_recording ? Icons.stop : Icons.fiber_manual_record,
              _recording ? 'STOP REC' : 'RECORD',
              _recording ? Colors.red : Colors.orangeAccent, 64,
              _toggleRecord),
            const SizedBox(height: 8),
            _btn(Icons.high_quality, _quality, Colors.blue, 64, _cycleQ),
            const SizedBox(height: 8),
            _btn(Icons.speed, '$_fps FPS', Colors.tealAccent, 64, _cycleF),
            const SizedBox(height: 8),
            _btn(_micMuted ? Icons.mic_off : Icons.mic,
              _micMuted ? 'MUTED' : 'MIC ON',
              _micMuted ? Colors.redAccent : Colors.greenAccent, 64,
              () async {
                await StreamingService.muteMic(!_micMuted);
                setState(() => _micMuted = !_micMuted);
              }),
            const SizedBox(height: 8),
            _btn(Icons.flip_camera_android, 'SWITCH',
              Colors.purpleAccent, 64, () async {
                await StreamingService.switchCamera();
                setState(() => _front = !_front);
              }),
          ]))),
      ]),
    );
  }

  Widget _btn(IconData icon, String label, Color color,
      double size, VoidCallback onTap) {
    return InkWell(onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(width: size, height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(8)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: size * 0.32),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 9,
                fontWeight: FontWeight.w900, letterSpacing: 1)),
          ])));
  }
}
