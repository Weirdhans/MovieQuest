import 'package:supabase_flutter/supabase_flutter.dart';
import '../errors/result.dart';

/// Interface for Supabase Service - Enables dependency injection and testing
abstract class ISupabaseService {
  // Session Management
  Future<Result<bool>> checkIfSessionMember(String sessionId, String userId);
  Future<Result<Map<String, dynamic>>> createSession({
    required String hostUserId,
    required List<String> streamingProviders,
    required List<String> genres,
    required String maxCertification,
    required int requiredVotes,
    String genreMatchMode = 'any',
    List<String>? excludedGenres,
  });
  Future<Result<Map<String, dynamic>>> getSession(String sessionId);
  Future<Result<Map<String, dynamic>>> getSessionPreview(String sessionId);
  Future<Result<Map<String, dynamic>>> joinSession({
    required String sessionId,
    required String userId,
    String? userName,
  });

  // Swipe Management
  Future<Result<Map<String, dynamic>>> recordSwipe({
    required String sessionId,
    required String userId,
    required int movieId,
    required bool swipedRight,
    Map<String, dynamic>? movieData,
  });
  Future<Result<Map<String, dynamic>>> checkAndCreateMatch({
    required String sessionId,
    required int movieId,
    required Map<String, dynamic> movieData,
  });

  // Matches
  Future<Result<List<Map<String, dynamic>>>> getMatches(String sessionId);

  // Realtime Subscriptions
  RealtimeChannel subscribeToMatches(
    String sessionId,
    void Function(Map<String, dynamic>) onMatch,
  );
  RealtimeChannel subscribeToMembers(
    String sessionId,
    void Function(Map<String, dynamic>) onNewMember,
  );

  // V2 Features
  Future<Result<List<Map<String, dynamic>>>> getPartialMatches(
    String sessionId, {
    int minVotes = 1,
  });
  Future<Result<Map<String, dynamic>>> undoLastSwipe({
    required String sessionId,
    required String userId,
  });
  Future<Result<List<Map<String, dynamic>>>> getMemberSwipeCounts(
    String sessionId,
  );
  Future<Result<bool>> updateSessionFilters({
    required String sessionId,
    required List<String> streamingProviders,
    required List<String> genres,
    required String maxCertification,
  });
  Future<Result<Map<String, dynamic>>> getSessionStats(String sessionId);
}
