import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration for mobile platforms
/// Loads API keys and URLs from .env file
String getSupabaseUrl() => dotenv.env['SUPABASE_URL'] ?? '';
String getSupabaseAnonKey() => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
String getTmdbApiKey() => dotenv.env['TMDB_API_KEY'] ?? '';
String getTmdbBaseUrl() =>
    dotenv.env['TMDB_BASE_URL'] ?? 'https://api.themoviedb.org/3';
String getTmdbImageBase() =>
    dotenv.env['TMDB_IMAGE_BASE'] ?? 'https://image.tmdb.org/t/p/w500';

Future<void> initEnv() async {
  await dotenv.load(fileName: '.env');
}

bool validateEnv() {
  return getSupabaseUrl().isNotEmpty &&
      getSupabaseAnonKey().isNotEmpty &&
      getTmdbApiKey().isNotEmpty;
}
