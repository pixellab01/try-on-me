import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import '../api.dart';
import '../config.dart';
import 'result_screen.dart';

/// Processing: server mode me real polling, offline demo me fake delay.
class ProcessingScreen extends StatefulWidget {
  final Map<String, String> garment;
  final File clip;
  const ProcessingScreen(
      {super.key, required this.garment, required this.clip});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  String _step = 'Video upload ho raha hai…';
  bool _failed = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    if (!AppConfig.serverMode) {
      await _demoFlow();
      return;
    }
    try {
      setState(() => _step = 'Video upload ho raha hai…');
      final jobId = await ApiClient().submitTryOn(widget.clip, widget.garment);
      setState(() => _step = 'AI kapde try kar raha hai… (yeh 1-3 min le sakta hai)');
      // poll up to ~6 min
      for (var i = 0; i < 120; i++) {
        await Future.delayed(const Duration(seconds: 3));
        if (!mounted) return;
        final st = await ApiClient().tryOnStatus(jobId);
        final status = st['status'] as String;
        if (status == 'done') {
          final url = ApiClient().absoluteUrl(st['result_url'] as String);
          _finish(resultVideoUrl: url, mode: 'server');
          return;
        }
        if (status == 'failed') {
          throw Exception(st['error'] ?? 'Try-on fail ho gaya');
        }
        setState(() => _step =
            'AI kapde try kar raha hai… (${(i + 1) * 3}s)');
      }
      throw Exception('Timeout — 6 min me result nahi aaya');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _err = '$e';
      });
    }
  }

  Future<void> _demoFlow() async {
    const steps = [
      'Video upload ho raha hai…',
      'Garment detect ho raha hai…',
      'AI kapde try kar raha hai…',
    ];
    for (final s in steps) {
      if (!mounted) return;
      setState(() => _step = s);
      await Future.delayed(const Duration(seconds: 2));
    }
    // bundled sample video ko temp me copy karo taaki player chala sake
    final dir = await getTemporaryDirectory();
    final dst = File('${dir.path}/demo_result.mp4');
    if (!await dst.exists()) {
      final data = await rootBundle.load('assets/sample_result.mp4');
      await dst.writeAsBytes(data.buffer.asUint8List());
    }
    _finish(resultVideoPath: dst.path, mode: 'demo');
  }

  void _finish({String? resultVideoUrl, String? resultVideoPath, required String mode}) {
    if (!mounted) return;
    AppConfig.addHistory(
        title: widget.garment['title'] ?? '',
        price: widget.garment['price'] ?? '',
        mode: mode);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ResultScreen(
        garment: widget.garment,
        originalClip: widget.clip,
        resultVideoUrl: resultVideoUrl,
        resultVideoPath: resultVideoPath,
        mode: mode,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Try-On ho raha hai')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_failed) ...[
                const SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(strokeWidth: 6),
                ),
                const SizedBox(height: 24),
                const Text('✨', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text(_step,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text('App band mat karo',
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ] else ...[
                const Text('😞', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text('Kuch gadbad ho gayi',
                    style:
                        TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_err ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Wapas jao'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
