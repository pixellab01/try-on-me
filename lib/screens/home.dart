import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api.dart';
import '../config.dart';
import '../demo_data.dart';
import 'widgets.dart';
import 'results.dart';
import 'camera_screen.dart';
import 'settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();
  final _linkCtrl = TextEditingController();
  bool _searching = false;
  List<Map<String, String>>? _trending;
  String? _trendError;

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  Future<void> _loadTrending() async {
    if (!AppConfig.serverMode) {
      setState(() => _trending = demoProducts);
      return;
    }
    try {
      final list = await ApiClient().catalog();
      setState(() => _trending = list);
    } catch (e) {
      setState(() {
        _trendError = 'Server se connect nahi hua: $e';
        _trending = demoProducts;
      });
    }
  }

  Future<void> _pickScreenshot() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    if (!AppConfig.serverMode) {
      // Offline demo: seedha demo results dikhao
      _openResults(demoProducts, offline: true);
      return;
    }
    setState(() => _searching = true);
    try {
      final products = await ApiClient().search(File(x.path));
      if (!mounted) return;
      _openResults(products, offline: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search fail: $e — demo results dikha rahe hain')),
      );
      _openResults(demoProducts, offline: true);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _openResults(List<Map<String, String>> products, {required bool offline}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResultsScreen(products: products, offline: offline),
    ));
  }

  void _tryProduct(Map<String, String> p) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CameraScreen(garment: p),
    ));
  }

  void _submitLink() {
    final url = _linkCtrl.text.trim();
    if (url.isEmpty) return;
    _tryProduct({
      'id': 'link-${DateTime.now().millisecondsSinceEpoch}',
      'title': 'Pasted product link',
      'price': '',
      'store': Uri.tryParse(url)?.host ?? 'link',
      'url': url,
      'emoji': '🔗',
      'cat': 'tops',
    });
    _linkCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Try On Me',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(child: ModeChip(serverMode: AppConfig.serverMode)),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SettingsScreen()));
              setState(() {});
              _loadTrending();
            },
          ),
        ],
      ),
      body: _searching
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Screenshot me product dhoondh rahe hain…'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadTrending,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Hero CTA
                  GestureDetector(
                    onTap: _pickScreenshot,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('📸', style: TextStyle(fontSize: 44)),
                            SizedBox(height: 8),
                            Text('Screenshot Upload Karo',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold)),
                            Text('Outfit ka screenshot → 8-10 matching products',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Link paste
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _linkCtrl,
                          decoration: InputDecoration(
                            hintText: '🔗 Product link paste karo…',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                          keyboardType: TextInputType.url,
                          onSubmitted: (_) => _submitLink(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _submitLink,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                        ),
                        child: const Text('Try'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('🔥 Trending',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (_trendError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_trendError!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.orange.shade800)),
                    ),
                  const SizedBox(height: 8),
                  if (_trending == null)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator()))
                  else
                    SizedBox(
                      height: 250,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _trending!.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 10),
                        itemBuilder: (_, i) => SizedBox(
                          width: 160,
                          child: ProductCard(
                            product: _trending![i],
                            onTryOn: () => _tryProduct(_trending![i]),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Text('🕘 Mere Try-Ons',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _HistoryRail(),
                ],
              ),
            ),
    );
  }
}

class _HistoryRail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final h = AppConfig.history;
    if (h.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text('Abhi tak koi try-on nahi.\nPehla try-on karo! ✨',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return Column(
      children: h
          .map((e) => ListTile(
                leading: const Text('🎥', style: TextStyle(fontSize: 28)),
                title: Text(e['title'] ?? '',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${e['price'] ?? ''} • ${e['mode'] == 'server' ? 'Server' : 'Demo'}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Trial build me history replay jald aa raha hai')) ,
                  );
                },
              ))
          .toList(),
    );
  }
}
