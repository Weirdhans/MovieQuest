import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/supabase_service.dart';
import '../../shared/services/tmdb_service.dart';
import '../../shared/services/utils_service.dart';
import '../interfaces/i_supabase_service.dart';
import '../interfaces/i_tmdb_service.dart';
import '../interfaces/i_utils_service.dart';
import '../utils/dev_log.dart';

// ============================================
// SERVICE PROVIDERS (Singletons)
// ============================================

/// Supabase Service Provider
final supabaseServiceProvider = Provider<ISupabaseService>((ref) {
  return SupabaseService();
});

/// TMDB Service Provider
final tmdbServiceProvider = Provider<ITmdbService>((ref) {
  return TmdbService();
});

/// Utils Service Provider
final utilsServiceProvider = Provider<IUtilsService>((ref) {
  return UtilsService();
});

// ============================================
// USER STATE PROVIDERS
// ============================================

/// Current User ID Provider
final userIdProvider = FutureProvider<String>((ref) async {
  final utilsService = ref.watch(utilsServiceProvider);
  final result = await utilsService.getUserId();

  return result.when(
    success: (userId) => userId,
    error: (error) => throw error,
  );
});

// ============================================
// SESSION STATE PROVIDERS
// ============================================

/// Current Session ID Provider (nullable)
final currentSessionIdProvider = StateProvider<String?>((ref) => null);

/// Current Session Provider
final currentSessionProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final sessionId = ref.watch(currentSessionIdProvider);
  if (sessionId == null) return null;

  final supabaseService = ref.watch(supabaseServiceProvider);
  final result = await supabaseService.getSession(sessionId);

  return result.when(
    success: (session) => session,
    error: (error) {
      // Log error but return null instead of throwing
      return null;
    },
  );
});

/// Session Members Provider
/// This provider auto-refreshes when swipes happen by watching currentMovieIndexProvider
final sessionMembersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final sessionId = ref.watch(currentSessionIdProvider);
  // Watch movie index to refresh members when swipes happen
  final movieIndex = ref.watch(currentMovieIndexProvider);

  devLog('🔄 [sessionMembersProvider] Called - sessionId=$sessionId, movieIndex=$movieIndex');

  if (sessionId == null) {
    devLog('⚠️ [sessionMembersProvider] No session ID, returning empty list');
    return [];
  }

  final supabaseService = ref.watch(supabaseServiceProvider);
  devLog('📞 [sessionMembersProvider] Calling getMemberSwipeCounts for session: $sessionId');
  final result = await supabaseService.getMemberSwipeCounts(sessionId);

  return result.when(
    success: (members) {
      devLogSuccess('✅ [sessionMembersProvider] Received ${members.length} members from service');
      if (members.isNotEmpty) {
        devLog('👥 [sessionMembersProvider] Members summary:');
        for (var member in members) {
          devLog('  - ${member['user_name'] ?? 'Unknown'} (${member['user_id']?.toString().substring(0, 8) ?? 'no-id'}): ${member['swipe_count']} swipes');
        }
      } else {
        devLog('⚠️ [sessionMembersProvider] No members received!');
      }
      return members;
    },
    error: (error) {
      devLogError('❌ [sessionMembersProvider] Error fetching members', error);
      return [];
    },
  );
});

/// Session Matches Provider
final sessionMatchesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final sessionId = ref.watch(currentSessionIdProvider);
  if (sessionId == null) return [];

  final supabaseService = ref.watch(supabaseServiceProvider);
  final result = await supabaseService.getMatches(sessionId);

  return result.when(
    success: (matches) => matches,
    error: (error) => [],
  );
});

/// Session Partial Matches Provider
final sessionPartialMatchesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final sessionId = ref.watch(currentSessionIdProvider);
  if (sessionId == null) return [];

  final supabaseService = ref.watch(supabaseServiceProvider);
  final result = await supabaseService.getPartialMatches(sessionId, minVotes: 1);

  return result.when(
    success: (partialMatches) => partialMatches,
    error: (error) => [],
  );
});

/// Session Stats Provider
final sessionStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final sessionId = ref.watch(currentSessionIdProvider);
  if (sessionId == null) return null;

  final supabaseService = ref.watch(supabaseServiceProvider);
  final result = await supabaseService.getSessionStats(sessionId);

  return result.when(
    success: (stats) => stats,
    error: (error) => null,
  );
});

// ============================================
// MOVIES STATE PROVIDERS
// ============================================

/// Current Movies Provider
final moviesProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

/// Current Movie Index Provider
final currentMovieIndexProvider = StateProvider<int>((ref) => 0);

/// Current Movie Provider
final currentMovieProvider = Provider<Map<String, dynamic>?>((ref) {
  final movies = ref.watch(moviesProvider);
  final index = ref.watch(currentMovieIndexProvider);

  if (movies.isEmpty || index >= movies.length) return null;
  return movies[index];
});

// ============================================
// UI STATE PROVIDERS
// ============================================

/// Loading State Provider
final isLoadingProvider = StateProvider<bool>((ref) => false);

/// Error Message Provider
final errorMessageProvider = StateProvider<String?>((ref) => null);

/// Show Matches Dialog Provider
final showMatchesDialogProvider = StateProvider<bool>((ref) => false);

// ============================================
// SESSION FILTERS PROVIDERS
// ============================================

/// Selected Streaming Providers
final selectedProvidersProvider = StateProvider<List<String>>((ref) => []);

/// Selected Genres
final selectedGenresProvider = StateProvider<List<String>>((ref) => []);

/// Selected Max Certification
final selectedCertificationProvider = StateProvider<String>((ref) => 'AL');

/// Required Votes Count
final requiredVotesProvider = StateProvider<int>((ref) => 2);

/// Host Name Provider (for session creation)
final hostNameProvider = StateProvider<String>((ref) => '');

/// Genre Match Mode Provider (OR vs AND logic for genres)
final genreMatchModeProvider = StateProvider<String>((ref) => 'any');
