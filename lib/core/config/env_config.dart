import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration
/// Loads API keys and URLs from .env file
class EnvConfig {
  // Supabase
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // TMDB
  static String get tmdbApiKey => dotenv.env['TMDB_API_KEY'] ?? '';
  static String get tmdbBaseUrl =>
      dotenv.env['TMDB_BASE_URL'] ?? 'https://api.themoviedb.org/3';
  static String get tmdbImageBase =>
      dotenv.env['TMDB_IMAGE_BASE'] ?? 'https://image.tmdb.org/t/p/w500';

  /// Initialize environment variables
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
  }

  /// Validate that all required environment variables are set
  static bool validate() {
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        tmdbApiKey.isNotEmpty;
  }
}
