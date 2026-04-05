import 'model_utils.dart';

class MembershipLevelModel {
  final String id;
  final String name;
  final int minPoints;

  MembershipLevelModel({
    required this.id,
    required this.name,
    required this.minPoints,
  });

  factory MembershipLevelModel.fromMap(Map<String, dynamic> map) {
    return MembershipLevelModel(
      id: ModelUtils.readString(map['id']),
      name: ModelUtils.readString(map['name']),
      minPoints: ModelUtils.readInt(map['minPoints']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'minPoints': minPoints,
    };
  }
}
