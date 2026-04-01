import 'package:cloud_firestore/cloud_firestore.dart';

class EventConditionsModel {
  final bool applyAll;
  final List<String> categories;
  final List<String> sports;
  final List<String> brands;

  const EventConditionsModel({
    required this.applyAll,
    required this.categories,
    required this.sports,
    required this.brands,
  });

  factory EventConditionsModel.fromJson(Map<String, dynamic> json) {
    return EventConditionsModel(
      applyAll: json['apply_all'] ?? false,
      categories: (json['categories'] ?? []).map<String>((e) => e.toString()).toList(),
      sports: (json['sports'] ?? []).map<String>((e) => e.toString()).toList(),
      brands: (json['brands'] ?? []).map<String>((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'apply_all': applyAll,
        'categories': categories,
        'sports': sports,
        'brands': brands,
      };
}

class EventModel {
  final String id;
  final String name;
  final String eventType;
  final String discountType;
  final double discountValue;
  final bool isActive;
  final String bannerUrl;
  final Timestamp? startDate;
  final Timestamp? endDate;
  final EventConditionsModel conditions;

  const EventModel({
    required this.id,
    required this.name,
    required this.eventType,
    required this.discountType,
    required this.discountValue,
    required this.isActive,
    required this.bannerUrl,
    required this.startDate,
    required this.endDate,
    required this.conditions,
  });

  factory EventModel.fromJson(Map<String, dynamic> json, String documentId) {
    return EventModel(
      id: documentId,
      name: json['name'] ?? 'Chua co ten',
      eventType: json['event_type'] ?? json['eventType'] ?? 'Khac',
      discountType: json['discount_type'] ?? 'percent',
      discountValue: (json['discount_value'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? false,
      bannerUrl: json['banner_url'] ?? '',
      startDate: json['start_date'],
      endDate: json['end_date'],
      conditions: EventConditionsModel.fromJson(json['conditions'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'event_type': eventType,
        'discount_type': discountType,
        'discount_value': discountValue,
        'is_active': isActive,
        'banner_url': bannerUrl,
        'start_date': startDate,
        'end_date': endDate,
        'conditions': conditions.toJson(),
      };
}
