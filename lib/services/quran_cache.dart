export 'quran_cache_stub.dart'
    if (dart.library.html) 'quran_cache_web.dart'
    if (dart.library.io) 'quran_cache_native.dart';
