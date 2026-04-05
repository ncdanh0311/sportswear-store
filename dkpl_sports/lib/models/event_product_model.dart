class EventProductModel {
  final String eventId;
  final String productId;

  EventProductModel({
    required this.eventId,
    required this.productId,
  });

  factory EventProductModel.fromMap(Map<String, dynamic> map) {
    return EventProductModel(
      eventId: (map['eventId'] ?? '').toString(),
      productId: (map['productId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'productId': productId,
    };
  }
}
