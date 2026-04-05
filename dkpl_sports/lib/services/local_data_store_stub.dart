class LocalDataStore {
  LocalDataStore._();
  static final LocalDataStore instance = LocalDataStore._();

  Future<List<dynamic>> readList(String name) async => [];
  Future<Map<String, dynamic>> readMap(String name) async => {};
  Future<void> writeList(String name, List<dynamic> data) async {}
  Future<void> writeMap(String name, Map<String, dynamic> data) async {}
}
