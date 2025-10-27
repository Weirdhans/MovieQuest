import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../../core/services/base_service.dart';
import '../../core/errors/result.dart';
import '../../core/utils/dev_log.dart';
import '../../core/interfaces/i_utils_service.dart';

/// Utilities Service - Helper functions
/// Port of utils.js from web version
class UtilsService extends BaseService implements IUtilsService {
  static const _uuid = Uuid();
  static const _userIdKey = 'user_id';

  static final UtilsService _instance = UtilsService._();
  UtilsService._();
  factory UtilsService() => _instance;

  /// Get or generate user ID (persisted in SharedPreferences)
  Future<Result<String>> getUserId() async {
    return executeWithErrorHandling(
      () async {
        final prefs = await SharedPreferences.getInstance();
        String? userId = prefs.getString(_userIdKey);

        if (userId == null) {
          userId = _uuid.v4();
          await prefs.setString(_userIdKey, userId);
          devLogSuccess('Nieuwe User ID aangemaakt: $userId');
        } else {
          devLog('Bestaande User ID geladen: $userId');
        }

        return userId;
      },
      'getUserId',
    );
  }

  /// Get session ID from URL (for deep linking)
  String? getSessionIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final sessionId = uri.queryParameters['session'];
      if (sessionId != null && sessionId.isNotEmpty) {
        return sessionId;
      }
      return null;
    } catch (e) {
      devLogError('Fout bij parsen URL', e);
      return null;
    }
  }

  /// Generate share link for session
  String generateShareLink(String sessionId, String baseUrl) {
    return '$baseUrl?session=$sessionId';
  }

  /// Copy text to clipboard
  Future<Result<bool>> copyToClipboard(String text) async {
    return executeWithErrorHandling(
      () async {
        await Clipboard.setData(ClipboardData(text: text));
        devLogSuccess('Gekopieerd naar clipboard: $text');
        return true;
      },
      'copyToClipboard',
    );
  }

  /// Share text using native share dialog
  Future<Result<void>> shareText(String text, {String? subject}) async {
    return executeWithErrorHandling(
      () async {
        await Share.share(text, subject: subject);
      },
      'shareText',
    );
  }

  /// Format date string
  static String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Onbekend';
    }
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}-${date.month}-${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  /// Format duration (minutes to hours:minutes)
  static String formatDuration(int? minutes) {
    if (minutes == null || minutes == 0) {
      return 'Onbekend';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}u ${mins}m';
    }
    return '${mins}m';
  }

  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  /// Generate random color for avatars
  static int getColorFromString(String text) {
    int hash = 0;
    for (int i = 0; i < text.length; i++) {
      hash = text.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return hash;
  }
}
