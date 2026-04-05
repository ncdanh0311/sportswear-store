import 'package:cloud_firestore/cloud_firestore.dart';

class ModelUtils {
  ModelUtils._();

  static String readString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  static bool readBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase();
      return v == 'true' || v == '1' || v == 'yes';
    }
    return fallback;
  }

  static int readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double readDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.replaceAll(',', '').replaceAll(' ', '');
      final cleaned = normalized.replaceAll(RegExp(r'[^0-9.\-]'), '');
      if (cleaned.isEmpty) return fallback;
      final parts = cleaned.split('.');
      final compact =
          parts.length <= 2 ? cleaned : '${parts.first}.${parts.skip(1).join()}';
      return double.tryParse(compact) ?? fallback;
    }
    return fallback;
  }

  static String? readDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toIso8601String();
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value).toIso8601String();
    }
    return value.toString();
  }

  static DateTime? readDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static Timestamp? readTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value;
    if (value is DateTime) return Timestamp.fromDate(value);
    if (value is int) {
      return Timestamp.fromDate(DateTime.fromMillisecondsSinceEpoch(value));
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return Timestamp.fromDate(parsed);
    }
    return null;
  }

  static List<String> readStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return <String>[];
  }
}
