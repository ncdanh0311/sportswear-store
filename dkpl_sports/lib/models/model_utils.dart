import 'package:cloud_firestore/cloud_firestore.dart';

class ModelUtils {
  ModelUtils._();

  static String? readDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toIso8601String();
    if (value is Timestamp) return value.toDate().toIso8601String();
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
}
