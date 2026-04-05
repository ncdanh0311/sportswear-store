class ColorModel {
  final String id;
  final String name;

  ColorModel({
    required this.id,
    required this.name,
  });

  factory ColorModel.fromMap(Map<String, dynamic> map) {
    return ColorModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}
