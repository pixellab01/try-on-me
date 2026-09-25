import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'processing.dart';

/// Camera screen: front camera default, 4-sec auto-record, preview + retake.
class CameraScreen extends StatefulWidget {
  final Map<String, String> garment;
  const CameraScreen({super.key, required this.garment});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _ctrl;
  List<CameraDescription> _cams = [];
  int _camIdx = 0;
  bool _ready = false;
  String? _error;

  bool _recording = false;
  int _countdown = 4;
  Timer? _timer;
  XFile? _clip;

  static const recordSecs = 4;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _cams = await availableCameras();
      if (_cams.isEmpty) throw Exception('Koi camera nahi mila');
      // front camera default (research: front camera day-one)
      _camIdx = _cams.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.front);
      if (_camIdx < 0) _camIdx = 0;
      await _open(_camIdx);
    } catch (e) {
      setState(() => _error = 'Camera error: $e');
    }
  }

  Future<void> _open(int idx) async {
    await _ctrl?.dispose();
    setState(() {
      _ready = false;
      _camIdx = idx;
    });
    _ctrl = CameraController(
      _cams[idx],
      ResolutionPreset.high,
      enableAudio: true,
    );
    try {
      await _ctrl!.initialize();
      setState(() => _ready = true);
    } catch (e) {
      setState(() => _error = 'Camera init fail: $e');
    }
  }

  void _flip() {
    if (_cams.length < 2 || _recording) return;
    _open((_camIdx + 1) % _cams.length);
  }

  Future<void> _startRecord() async {
    if (!_ready || _recording) return;
    try {
      await _ctrl!.startVideoRecording();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Record start fail: $e')));
      return;
    }
    setState(() {
      _recording = true;
      _countdown = recordSecs;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) return;
      if (_countdown <= 1) {
        t.cancel();
        await _stopRecord();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _stopRecord() async {
    if (!_recording) return;
    _timer?.cancel();
    try {
      final f = await _ctrl!.stopVideoRecording();
      setState(() {
        _recording = false;
        _clip = f;
      });
    } catch (e) {
      setState(() => _recording = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Record stop fail: $e')));
    }
  }

  void _retake() => setState(() => _clip = null);

  void _proceed() {
    if (_clip == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProcessingScreen(
        garment: widget.garment,
        clip: File(_clip!.path),
      ),
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.garment;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Try: ${(g['title'] ?? '').length > 28 ? '${g['title']!.substring(0, 28)}…' : g['title'] ?? ''}',
            style: const TextStyle(fontSize: 15)),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white)),
              ),
            )
          : !_ready
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
                  children: [
                    // Garment chip
                    Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${g['emoji'] ?? '👕'} ${g['title'] ?? ''} • ${g['price'] ?? ''}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Preview / recorded clip placeholder
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_clip == null)
                            CameraPreview(_ctrl!)
                          else
                            Container(
                              color: Colors.grey.shade900,
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('🎬',
                                        style: TextStyle(fontSize: 64)),
                                    SizedBox(height: 12),
                                    Text('Clip record ho gaya!',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold)),
                                    Text('Aage badho ya dobara record karo',
                                        style: TextStyle(
                                            color: Colors.white70)),
                                  ],
                                ),
                              ),
                            ),
                          // Tips overlay (recording nahi ho rahi tab)
                          if (_clip == null && !_recording)
                            Positioned(
                              bottom: 12,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    '💡 Chehra + kandhe frame me • Roshni saamne se',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ),
                            ),
                          // Countdown
                          if (_recording)
                            Center(
                              child: Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.red, width: 5),
                                  color: Colors.black45,
                                ),
                                child: Center(
                                  child: Text('$_countdown',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 44,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Controls
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 24),
                      color: Colors.black,
                      child: _clip == null
                          ? Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  onPressed: _flip,
                                  icon: const Icon(
                                      Icons.flip_camera_android,
                                      color: Colors.white,
                                      size: 30),
                                ),
                                GestureDetector(
                                  onTap: _startRecord,
                                  child: Container(
                                    width: 74,
                                    height: 74,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 4),
                                      color: _recording
                                          ? Colors.red
                                          : Colors.red.shade400,
                                    ),
                                    child: _recording
                                        ? const Icon(Icons.stop,
                                            color: Colors.white, size: 34)
                                        : const Icon(
                                            Icons.videocam,
                                            color: Colors.white,
                                            size: 34),
                                  ),
                                ),
                                const SizedBox(width: 48), // balance
                              ],
                            )
                          : Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _retake,
                                  icon: const Icon(Icons.refresh,
                                      color: Colors.white),
                                  label: const Text('Dobara',
                                      style: TextStyle(color: Colors.white)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Colors.white54),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 22, vertical: 12),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _proceed,
                                  icon: const Icon(Icons.auto_awesome),
                                  label: const Text('Try-On Karo ✨'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF7C3AED),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 26, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
    );
  }
}
