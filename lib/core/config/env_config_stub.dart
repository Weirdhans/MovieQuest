/// Stub implementation for unsupported platforms
/// This file should never be used in practice

String getSupabaseUrl() => throw UnsupportedError('Platform not supported');
String getSupabaseAnonKey() => throw UnsupportedError('Platform not supported');
String getTmdbApiKey() => throw UnsupportedError('Platform not supported');
String getTmdbBaseUrl() => throw UnsupportedError('Platform not supported');
String getTmdbImageBase() => throw UnsupportedError('Platform not supported');

Future<void> initEnv() async {
  throw UnsupportedError('Platform not supported');
}

bool validateEnv() {
  throw UnsupportedError('Platform not supported');
}
