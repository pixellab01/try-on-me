import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'home.dart';

/// Result screen: dressed video, before/after toggle, View Product, Share.
class ResultScreen extends StatefulWidget {
  final Map<String, String> garment;
  final File originalClip;
  final String? resultVideoUrl; // server mode
  final String? resultVideoPath; // offline demo
  final String mode; // 'demo' | 'server'

  const ResultScreen({
    super.key,
    required this.garment,
    required this.originalClip,
    this.resultVideoUrl,
    this.resultVideoPath,
    required this.mode,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  VideoPlayerController? _resultCtrl;
  VideoPlayerController? _origCtrl;
  bool _showOriginal = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      if (widget.resultVideoUrl != null) {
        _resultCtrl =
            VideoPlayerController.networkUrl(Uri.parse(widget.resultVideoUrl!));
      } else if (widget.resultVideoPath != null) {
        _resultCtrl =
            VideoPlayerController.file(File(widget.resultVideoPath!));
      } else {
        throw Exception('Result video nahi mila');
      }
      _origCtrl = VideoPlayerController.file(widget.originalClip);
      await Future.wait([_resultCtrl!.initialize(), _origCtrl!.initialize()]);
      _resultCtrl!
        ..setLooping(true)
        ..play();
      _origCtrl!.setLooping(true);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _err = '$e');
    }
  }

  VideoPlayerController? get _active =>
      _showOriginal ? _origCtrl : _resultCtrl;

  void _toggle() {
    setState(() => _showOriginal = !_showOriginal);
    _resultCtrl?.pause();
    _origCtrl?.pause();
    _active?.play();
  }

  Future<void> _openProduct() async {
    final url = widget.garment['url'] ?? '';
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _share() async {
    final g = widget.garment;
    await Share.share(
      'Maine "${g['title']}" Try On Me app me try kiya! ✨ ${g['url'] ?? ''}',
      subject: 'Mera Try-On',
    );
  }

  @override
  void dispose() {
    _resultCtrl?.dispose();
    _origCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.garment;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tumhara Try-On ✨'),
        automaticallyImplyLeading: false,
        actions: [
          if (widget.mode == 'demo')
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: Chip(
                  label: Text('DEMO VIDEO',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.amber,
                ),
              ),
            ),
        ],
      ),
      body: _err != null
          ? Center(child: Text('Video load fail: $_err'))
          : _resultCtrl == null || !_resultCtrl!.value.isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    if (widget.mode == 'demo')
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        color: Colors.amber.shade100,
                        child: Text(
                          'Demo video hai — real AI try-on server connect karne pe chalega (Settings).',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: Colors.amber.shade900),
                        ),
                      ),
                    // Video
                    Expanded(
                      child: Container(
                        color: Colors.black,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: _active!.value.aspectRatio,
                            child: VideoPlayer(_active!),
                          ),
                        ),
                      ),
                    ),
                    // Before/after toggle
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                              value: false,
                              label: Text('✨ Try-On'),
                              icon: Icon(Icons.auto_awesome, size: 16)),
                          ButtonSegment(
                              value: true,
                              label: Text('🎥 Original'),
                              icon: Icon(Icons.videocam, size: 16)),
                        ],
                        selected: {_showOriginal},
                        onSelectionChanged: (s) => _toggle(),
                      ),
                    ),
                    // Product row
                    ListTile(
                      leading: Text(g['emoji'] ?? '👕',
                          style: const TextStyle(fontSize: 34)),
                      title: Text(g['title'] ?? '',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          '${g['price'] ?? ''} • ${g['store'] ?? ''}'),
                      trailing: ElevatedButton(
                        onPressed: _openProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEC4899),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('View Product'),
                      ),
                    ),
                    // Actions
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _share,
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const HomeScreen()),
                                  (_) => false,
                                );
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Naya Try-On'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF7C3AED),
                                foregroundColor: Colors.white,
                              ),
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
