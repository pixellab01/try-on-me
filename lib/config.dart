import 'package:shared_preferences/shared_preferences.dart';

/// App-wide config: server mode vs offline demo, backend URL.
class AppConfig {
  static const _kServerMode = 'server_mode';
  static const _kBackendUrl = 'backend_url';
  static const _kOnboarded = 'onboarded_v1';

  static late SharedPreferences prefs;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  static bool get serverMode => prefs.getBool(_kServerMode) ?? false;
  static Future<void> setServerMode(bool v) => prefs.setBool(_kServerMode, v);

  static String get backendUrl =>
      prefs.getString(_kBackendUrl) ?? 'https://tryonme-trial.hf.space';
  static Future<void> setBackendUrl(String v) => prefs.setString(_kBackendUrl, v);

  static bool get onboarded => prefs.getBool(_kOnboarded) ?? false;
  static Future<void> setOnboarded() => prefs.setBool(_kOnboarded, true);

  /// History: list of {title, price, ts, mode}
  static List<Map<String, String>> get history {
    final raw = prefs.getStringList('history_v1') ?? [];
    return raw.map((e) {
      final parts = e.split('|||');
      return {
        'title': parts.isNotEmpty ? parts[0] : '',
        'price': parts.length > 1 ? parts[1] : '',
        'ts': parts.length > 2 ? parts[2] : '',
        'mode': parts.length > 3 ? parts[3] : 'demo',
      };
    }).toList();
  }

  static Future<void> addHistory(
      {required String title, required String price, required String mode}) async {
    final raw = prefs.getStringList('history_v1') ?? [];
    raw.insert(0,
        '$title|||$price|||${DateTime.now().millisecondsSinceEpoch}|||$mode');
    if (raw.length > 30) raw.removeRange(30, raw.length);
    await prefs.setStringList('history_v1', raw);
  }
}
