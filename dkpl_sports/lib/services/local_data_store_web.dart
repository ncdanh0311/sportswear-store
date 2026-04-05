import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDataStore {
  LocalDataStore._();
  static final LocalDataStore instance = LocalDataStore._();

  Future<String> _read(String name, String fallback) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(name) ?? fallback;
  }

  Future<void> _write(String name, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(name, value);
  }

  Future<List<dynamic>> readList(String name) async {
    final raw = await _read(name, '[]');
    final decoded = jsonDecode(raw);
    if (decoded is List) return decoded;
    return [];
  }

  Future<Map<String, dynamic>> readMap(String name) async {
    final raw = await _read(name, '{}');
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    return {};
  }

  Future<void> writeList(String name, List<dynamic> data) async {
    await _write(name, jsonEncode(data));
  }

  Future<void> writeMap(String name, Map<String, dynamic> data) async {
    await _write(name, jsonEncode(data));
  }
}
