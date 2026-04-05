import 'package:cloud_firestore/cloud_firestore.dart';
import 'model_utils.dart';

class EventModel {
  final String id;
  final String name;
  final Timestamp? startDate;
  final Timestamp? endDate;

  const EventModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  factory EventModel.fromJson(Map<String, dynamic> json, String documentId) {
    return EventModel(
      id: documentId,
      name: ModelUtils.readString(json['name']),
      startDate: ModelUtils.readTimestamp(json['startDate']),
      endDate: ModelUtils.readTimestamp(json['endDate']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'startDate': startDate,
        'endDate': endDate,
      };
}
