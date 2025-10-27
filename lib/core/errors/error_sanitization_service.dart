import 'package:flutter/foundation.dart';
import 'app_error.dart';

/// Converts internal errors to user-friendly messages
/// In production: Never expose internal error details
/// In debug: Show detailed messages for debugging
class ErrorSanitizationService {
  /// Convert internal errors to safe user-facing messages
  static String sanitize(AppError error) {
    // In production: Use generic, user-friendly messages
    if (kReleaseMode) {
      return _getGenericMessage(error);
    }

    // In debug mode: Show detailed messages for debugging
    return error.message;
  }

  static String _getGenericMessage(AppError error) {
    if (error is NetworkError) {
      return 'Verbinding mislukt. Controleer je internetverbinding en probeer opnieuw.';
    }

    if (error is ValidationError) {
      // Validation errors are usually safe to show
      return error.message;
    }

    if (error is ApiError) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return 'Je bent niet geautoriseerd om deze actie uit te voeren.';
      }
      if (error.statusCode == 404) {
        return 'De gevraagde gegevens zijn niet gevonden.';
      }
      if (error.statusCode == 429) {
        return 'Te veel verzoeken. Wacht even en probeer opnieuw.';
      }
      if (error.statusCode != null && error.statusCode! >= 500) {
        return 'Er is een probleem met de server. Probeer het later opnieuw.';
      }
      return 'Er is een fout opgetreden bij het verwerken van je verzoek.';
    }

    if (error is AuthError) {
      return 'Authenticatie mislukt. Log opnieuw in.';
    }

    if (error is DatabaseError) {
      return 'Er is een probleem met het opslaan van gegevens. Probeer opnieuw.';
    }

    // Unknown errors: Generic message
    return 'Er is een onverwachte fout opgetreden. Probeer het opnieuw.';
  }

  /// Get a short error title for snackbars/toasts
  static String getErrorTitle(AppError error) {
    if (error is NetworkError) return 'Verbindingsfout';
    if (error is ValidationError) return 'Ongeldige invoer';
    if (error is ApiError) return 'API Fout';
    if (error is AuthError) return 'Authenticatiefout';
    if (error is DatabaseError) return 'Database Fout';
    return 'Fout';
  }
}
