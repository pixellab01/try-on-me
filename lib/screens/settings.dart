import 'package:flutter/material.dart';
import '../api.dart';
import '../config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlCtrl;
  late bool _serverMode;
  String? _testResult;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: AppConfig.backendUrl);
    _serverMode = AppConfig.serverMode;
  }

  Future<void> _save() async {
    await AppConfig.setBackendUrl(_urlCtrl.text.trim());
    await AppConfig.setServerMode(_serverMode);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings save ho gayi')),
    );
    setState(() {});
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    await AppConfig.setBackendUrl(_urlCtrl.text.trim());
    try {
      final h = await ApiClient().health();
      setState(() => _testResult =
          '✅ Connected!\nSearch: ${h['search_provider']}  •  Try-on: ${h['tryon_provider']}');
    } catch (e) {
      setState(() => _testResult = '❌ Connect nahi hua:\n$e');
    } finally {
      setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          SwitchListTile(
            title: const Text('Server mode',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text(
                'ON = trial backend se real search + try-on\nOFF = offline demo (bina server ke)'),
            value: _serverMode,
            onChanged: (v) => setState(() => _serverMode = v),
          ),
          const Divider(),
          const Text('Backend URL',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _urlCtrl,
            decoration: InputDecoration(
              hintText: 'https://tumhara-backend...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testing ? null : _test,
                  icon: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.wifi),
                  label: const Text('Test Connection'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
          if (_testResult != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_testResult!),
            ),
          ],
          const Divider(height: 32),
          const Text('Trial build v0.1.0',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            '• Offline demo me sab kuch phone pe hi chalta hai — koi server nahi chahiye.\n'
            '• Server mode me backend URL dalne pe real product search (SerpApi) aur real AI try-on (RunPod GPU) chalega.\n'
            '• Demo video sirf UX test ke liye hai, asli AI output nahi.',
            style: TextStyle(color: Colors.grey.shade700, height: 1.6),
          ),
        ],
      ),
    );
  }
}
