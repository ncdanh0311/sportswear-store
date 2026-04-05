export 'local_data_store_stub.dart'
    if (dart.library.io) 'local_data_store_io.dart'
    if (dart.library.html) 'local_data_store_web.dart';
