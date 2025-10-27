import '../errors/result.dart';

/// Interface for Utils Service - Enables dependency injection and testing
abstract class IUtilsService {
  Future<Result<String>> getUserId();
  String? getSessionIdFromUrl(String url);
  String generateShareLink(String sessionId, String baseUrl);
  Future<Result<bool>> copyToClipboard(String text);
  Future<Result<void>> shareText(String text, {String? subject});
}
