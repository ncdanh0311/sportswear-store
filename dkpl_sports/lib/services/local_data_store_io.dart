import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalDataStore {
  LocalDataStore._();
  static final LocalDataStore instance = LocalDataStore._();

  Future<Directory> _baseDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return docs;
  }

  Future<File> _file(String name, String defaultContent) async {
    final base = await _baseDir();
    final file = File('${base.path}/$name');
    if (!await file.exists()) {
      await file.writeAsString(defaultContent);
    }
    return file;
  }

  Future<List<dynamic>> readList(String name) async {
    final file = await _file(name, '[]');
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is List) return decoded;
    return [];
  }

  Future<Map<String, dynamic>> readMap(String name) async {
    final file = await _file(name, '{}');
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    return {};
  }

  Future<void> writeList(String name, List<dynamic> data) async {
    final file = await _file(name, '[]');
    await file.writeAsString(jsonEncode(data));
  }

  Future<void> writeMap(String name, Map<String, dynamic> data) async {
    final file = await _file(name, '{}');
    await file.writeAsString(jsonEncode(data));
  }
}
