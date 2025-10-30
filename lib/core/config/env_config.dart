// Conditional import: use web config for web platform, dotenv for mobile
import 'env_config_stub.dart'
    if (dart.library.html) 'env_config_web.dart'
    if (dart.library.io) 'env_config_mobile.dart';

/// Environment configuration
/// Uses compile-time constants for web, .env file for mobile
class EnvConfig {
  // Supabase
  static String get supabaseUrl => getSupabaseUrl();
  static String get supabaseAnonKey => getSupabaseAnonKey();

  // TMDB
  static String get tmdbApiKey => getTmdbApiKey();
  static String get tmdbBaseUrl => getTmdbBaseUrl();
  static String get tmdbImageBase => getTmdbImageBase();

  // Web App URL (for mobile share links fallback)
  static String get webAppUrl => getWebAppUrl();

  /// Initialize environment variables (only needed for mobile)
  static Future<void> init() async {
    await initEnv();
  }

  /// Validate that all required environment variables are set
  static bool validate() {
    return validateEnv();
  }
}
