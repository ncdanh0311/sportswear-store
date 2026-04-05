import 'model_utils.dart';

class EventProductModel {
  final String eventId;
  final String productId;

  EventProductModel({
    required this.eventId,
    required this.productId,
  });

  factory EventProductModel.fromMap(Map<String, dynamic> map) {
    return EventProductModel(
      eventId: ModelUtils.readString(map['eventId']),
      productId: ModelUtils.readString(map['productId']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'productId': productId,
    };
  }
}
