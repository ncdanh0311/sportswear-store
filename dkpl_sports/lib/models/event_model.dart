import 'model_utils.dart';

class EventModel {
  final String id;
  final String name;
  final String? startDate;
  final String? endDate;

  EventModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      startDate: ModelUtils.readDate(map['startDate']),
      endDate: ModelUtils.readDate(map['endDate']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate,
      'endDate': endDate,
    };
  }
}
