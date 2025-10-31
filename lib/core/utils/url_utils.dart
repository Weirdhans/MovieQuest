import 'package:flutter/foundation.dart';
import '../config/env_config.dart';

/// Utility class for generating dynamic URLs based on the current environment.
///
/// Supports:
/// - Runtime URL detection for web (localhost, Vercel previews, production)
/// - Environment variable fallback for mobile/desktop apps
/// - Future custom domain support
class UrlUtils {
  UrlUtils._(); // Private constructor to prevent instantiation

  /// Gets the base URL of the application.
  ///
  /// Priority order:
  /// 1. Web: Runtime detection via Uri.base.origin
  ///    - Works with localhost (http://localhost:xxxx)
  ///    - Works with Vercel previews (https://preview-xyz.vercel.app)
  ///    - Works with production (https://movie-quests.vercel.app)
  ///    - Works with custom domains (https://moviequest.app)
  /// 2. Mobile/Desktop: Uses EnvConfig.webAppUrl as fallback
  static String getBaseUrl() {
    if (kIsWeb) {
      // Runtime detection for web platform
      final origin = Uri.base.origin;

      // Localhost detection (optional logging for debugging)
      if (origin.contains('localhost') || origin.contains('127.0.0.1')) {
        debugPrint('UrlUtils: Using localhost URL: $origin');
      }

      return origin;
    }

    // Mobile/Desktop fallback: use environment configuration
    return EnvConfig.webAppUrl;
  }

  /// Generates a join URL for a session.
  ///
  /// Example: https://movie-quests.vercel.app/join/abc123
  static String getJoinUrl(String sessionId) {
    return '${getBaseUrl()}/join/$sessionId';
  }

  /// Generates share text for a session with join URL.
  ///
  /// Used for sharing via native share dialog or clipboard.
  static String getShareText(String sessionId, String sessionName) {
    return 'Join my MovieQuest session "$sessionName"!\n${getJoinUrl(sessionId)}';
  }

  /// Gets the QR code data (join URL).
  ///
  /// This is a convenience method that returns the same as getJoinUrl,
  /// but makes the intent clearer when generating QR codes.
  static String getQrCodeData(String sessionId) {
    return getJoinUrl(sessionId);
  }
}
