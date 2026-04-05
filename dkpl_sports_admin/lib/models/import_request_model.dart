import 'model_utils.dart';

class ImportRequestModel {
  final String id;
  final String staffId;
  final String status;
  final String? createdAt;

  ImportRequestModel({
    required this.id,
    required this.staffId,
    required this.status,
    required this.createdAt,
  });

  factory ImportRequestModel.fromMap(Map<String, dynamic> map) {
    return ImportRequestModel(
      id: ModelUtils.readString(map['id']),
      staffId: ModelUtils.readString(map['staffId']),
      status: ModelUtils.readString(map['status']),
      createdAt: ModelUtils.readDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'staffId': staffId,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
