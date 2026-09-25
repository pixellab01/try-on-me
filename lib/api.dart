import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'config.dart';

/// Trial backend client. Server mode me real API, warna offline demo.
class ApiClient {
  String get base => AppConfig.backendUrl.replaceAll(RegExp(r'/+$'), '');

  Future<Map<String, dynamic>> health() async {
    final r = await http.get(Uri.parse('$base/health')).timeout(
          const Duration(seconds: 12),
        );
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, String>>> catalog() async {
    final r = await http.get(Uri.parse('$base/api/v1/catalog')).timeout(
          const Duration(seconds: 15),
        );
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    return (data['products'] as List)
        .map((p) => (p as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')))
        .toList();
  }

  Future<List<Map<String, String>>> search(File image) async {
    final req = http.MultipartRequest('POST', Uri.parse('$base/api/v1/search'));
    req.files.add(await http.MultipartFile.fromPath('image', image.path));
    final streamed = await req.send().timeout(const Duration(seconds: 90));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) throw Exception('Search failed (${streamed.statusCode})');
    final data = jsonDecode(body) as Map<String, dynamic>;
    return (data['products'] as List)
        .map((p) => (p as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')))
        .toList();
  }

  /// Returns job_id
  Future<String> submitTryOn(File video, Map<String, String> garment) async {
    final req = http.MultipartRequest('POST', Uri.parse('$base/api/v1/tryon'));
    req.files.add(await http.MultipartFile.fromPath('video', video.path));
    req.fields['garment'] = jsonEncode(garment);
    final streamed = await req.send().timeout(const Duration(seconds: 120));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) throw Exception('Try-on failed (${streamed.statusCode})');
    return (jsonDecode(body) as Map)['job_id'] as String;
  }

  /// Returns {status, result_url?, error?}
  Future<Map<String, dynamic>> tryOnStatus(String jobId) async {
    final r = await http.get(Uri.parse('$base/api/v1/tryon/$jobId')).timeout(
          const Duration(seconds: 15),
        );
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  String absoluteUrl(String maybeRelative) {
    if (maybeRelative.startsWith('http')) return maybeRelative;
    return '$base$maybeRelative';
  }
}
