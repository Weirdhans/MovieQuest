import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/env_config.dart';
import '../../core/services/base_service.dart';
import '../../core/errors/result.dart';
import '../../core/errors/app_error.dart';
import '../../core/utils/dev_log.dart';
import '../../core/interfaces/i_supabase_service.dart';

/// Supabase Service - Manages all backend interactions
/// This is a direct port of supabase.js from the web version
class SupabaseService extends BaseService implements ISupabaseService {
  static SupabaseClient? _client;
  static final SupabaseService _instance = SupabaseService._();

  SupabaseService._();
  factory SupabaseService() => _instance;

  /// Initialize Supabase client
  static Future<void> init() async {
    try {
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      devLogSuccess('Supabase client geïnitialiseerd');
    } catch (e, stackTrace) {
      devLogError('Failed to initialize Supabase', e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get Supabase client instance
  static SupabaseClient get client {
    if (_client == null) {
      throw AppError.database(
        message: 'Supabase niet geïnitialiseerd. Roep init() aan.',
      );
    }
    return _client!;
  }

  // ============================================
  // SESSION MANAGEMENT
  // ============================================

  /// Check if user is member of a session
  @override
  Future<Result<bool>> checkIfSessionMember(
    String sessionId,
    String userId,
  ) async {
    return executeWithErrorHandling(
      () async {
        final response = await client
            .from('session_members')
            .select('id')
            .eq('session_id', sessionId)
            .eq('user_id', userId)
            .maybeSingle();

        return response != null;
      },
      'checkIfSessionMember',
      metadata: {'sessionId': sessionId, 'userId': userId},
    );
  }

  /// Create new session
  @override
  Future<Result<Map<String, dynamic>>> createSession({
    required String hostUserId,
    required List<String> streamingProviders,
    required List<String> genres,
    required String maxCertification,
    required int requiredVotes,
    String genreMatchMode = 'any',
  }) async {
    return executeWithErrorHandling(
      () async {
        final response = await client.from('sessions').insert({
          'host_user_id': hostUserId,
          'streaming_providers': streamingProviders,
          'genres': genres,
          'max_certification': maxCertification,
          'is_active': true,
          'total_members': 1,
          'required_votes': requiredVotes,
          'genre_match_mode': genreMatchMode,
        }).select().single();

        devLogSuccess('Sessie aangemaakt: ${response['id']}');
        return response;
      },
      'createSession',
      metadata: {'hostUserId': hostUserId},
    );
  }

  /// Get session by ID
  @override
  Future<Result<Map<String, dynamic>>> getSession(String sessionId) async {
    return executeWithErrorHandling(
      () async {
        final response = await client
            .from('sessions')
            .select()
            .eq('id', sessionId)
            .single();

        devLogSuccess('Sessie opgehaald: $sessionId');
        return response;
      },
      'getSession',
      metadata: {'sessionId': sessionId},
    );
  }

  /// Join existing session
  @override
  Future<Result<Map<String, dynamic>>> joinSession({
    required String sessionId,
    required String userId,
    String? userName,
  }) async {
    return executeWithErrorHandling(
      () async {
        // Check if user is already a member
        final existingMember = await client
            .from('session_members')
            .select('id')
            .eq('session_id', sessionId)
            .eq('user_id', userId)
            .maybeSingle();

        if (existingMember != null) {
          devLogSuccess('Gebruiker is al lid van deze sessie');
          return existingMember;
        }

        // Insert new member
        final member = await client.from('session_members').insert({
          'session_id': sessionId,
          'user_id': userId,
          'user_name': userName,
        }).select().single();

        // Update total_members count
        try {
          await client.rpc<void>('increment_total_members', params: {
            'session_id': sessionId,
          });
        } catch (rpcError) {
          // If RPC doesn't exist, do it manually
          final session = await client
              .from('sessions')
              .select('total_members')
              .eq('id', sessionId)
              .single();

          await client.from('sessions').update({
            'total_members': ((session['total_members'] as int?) ?? 0) + 1,
          }).eq('id', sessionId);
        }

        devLogSuccess('Gebruiker toegevoegd aan sessie');
        return member;
      },
      'joinSession',
      metadata: {'sessionId': sessionId, 'userId': userId},
    );
  }

  // ============================================
  // SWIPE MANAGEMENT
  // ============================================

  /// Record swipe action
  @override
  Future<Result<Map<String, dynamic>>> recordSwipe({
    required String sessionId,
    required String userId,
    required int movieId,
    required bool swipedRight,
    Map<String, dynamic>? movieData,
  }) async {
    return executeWithErrorHandling(
      () async {
        devLog('Swipe data naar DB: movieId=$movieId, swipedRight=$swipedRight');

        final response = await client.from('swipes').insert({
          'session_id': sessionId,
          'user_id': userId,
          'movie_id': movieId,
          'swiped_right': swipedRight,
          'movie_data': movieData,
        }).select().single();

        devLogSuccess('Swipe geregistreerd: ${swipedRight ? 'LIKE' : 'DISLIKE'} voor film $movieId');
        return response;
      },
      'recordSwipe',
      metadata: {'movieId': movieId, 'swipedRight': swipedRight},
    );
  }

  /// Check and create match (V2 with required_votes logic)
  @override
  Future<Result<Map<String, dynamic>>> checkAndCreateMatch({
    required String sessionId,
    required int movieId,
    required Map<String, dynamic> movieData,
  }) async {
    return executeWithErrorHandling(
      () async {
        final response = await client.rpc<dynamic>('check_and_create_match_v2', params: {
          'p_session_id': sessionId,
          'p_movie_id': movieId,
          'p_movie_data': movieData,
        }) as Map<String, dynamic>;

        if (response['is_match'] == true) {
          devLogSuccess('MATCH! Film: $movieId (${response['likes_count']}/${response['required_votes']} likes)');
        } else {
          devLog('Like geregistreerd (${response['likes_count']}/${response['required_votes']} likes)');
        }

        return {
          'is_match': response['is_match'] ?? false,
          'likes_count': response['likes_count'] ?? 0,
          'required_votes': response['required_votes'] ?? 0,
        };
      },
      'checkAndCreateMatch',
      metadata: {'movieId': movieId},
    );
  }

  // ============================================
  // MATCHES
  // ============================================

  /// Get all matches for a session
  @override
  Future<Result<List<Map<String, dynamic>>>> getMatches(String sessionId) async {
    return executeWithErrorHandling(
      () async {
        final response = await client
            .from('matches')
            .select()
            .eq('session_id', sessionId)
            .order('matched_at', ascending: false);

        devLogSuccess('${response.length} matches opgehaald');
        return List<Map<String, dynamic>>.from(response);
      },
      'getMatches',
      metadata: {'sessionId': sessionId},
    );
  }

  // ============================================
  // REALTIME SUBSCRIPTIONS
  // ============================================

  /// Subscribe to new matches for a session
  @override
  RealtimeChannel subscribeToMatches(
    String sessionId,
    void Function(Map<String, dynamic>) onMatch,
  ) {
    devLog('Subscribing op matches voor sessie: $sessionId');

    final channel = client
        .channel('matches-$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'matches',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (payload) {
            devLogSuccess('Nieuwe match ontvangen via Realtime!');
            onMatch(payload.newRecord);
          },
        )
        .subscribe();

    return channel;
  }

  /// Subscribe to new members for a session
  @override
  RealtimeChannel subscribeToMembers(
    String sessionId,
    void Function(Map<String, dynamic>) onNewMember,
  ) {
    devLog('Subscribing op members voor sessie: $sessionId');

    final channel = client
        .channel('members-$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'session_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (payload) {
            devLog('Nieuw lid toegevoegd');
            onNewMember(payload.newRecord);
          },
        )
        .subscribe();

    return channel;
  }

  // ============================================
  // V2 FEATURES
  // ============================================

  /// Get partial matches (films liked by some but not all)
  @override
  Future<Result<List<Map<String, dynamic>>>> getPartialMatches(
    String sessionId, {
    int minVotes = 1,
  }) async {
    return executeWithErrorHandling(
      () async {
        final response = await client.rpc<dynamic>('get_partial_matches', params: {
          'p_session_id': sessionId,
          'p_min_votes': minVotes,
        });

        final List<dynamic> responseList = response as List<dynamic>;
        devLogSuccess('${responseList.length} partial matches opgehaald');
        return List<Map<String, dynamic>>.from(responseList);
      },
      'getPartialMatches',
      metadata: {'sessionId': sessionId, 'minVotes': minVotes},
    );
  }

  /// Undo last swipe
  @override
  Future<Result<Map<String, dynamic>>> undoLastSwipe({
    required String sessionId,
    required String userId,
  }) async {
    return executeWithErrorHandling(
      () async {
        final response = await client.rpc<dynamic>('undo_last_swipe', params: {
          'p_session_id': sessionId,
          'p_user_id': userId,
        }) as Map<String, dynamic>;

        if (response['success'] == true) {
          devLogSuccess('Laatste swipe ongedaan gemaakt: ${response['movie_id']}');
        }

        return response;
      },
      'undoLastSwipe',
      metadata: {'sessionId': sessionId, 'userId': userId},
    );
  }

  /// Get swipe counts for all session members
  @override
  Future<Result<List<Map<String, dynamic>>>> getMemberSwipeCounts(
    String sessionId,
  ) async {
    return executeWithErrorHandling(
      () async {
        devLog('Fetching member swipe counts for session: $sessionId');

        final response = await client.rpc<dynamic>('get_member_swipe_counts', params: {
          'p_session_id': sessionId,
        });

        devLog('RPC response type: ${response.runtimeType}');
        devLog('RPC response: $response');

        final List<dynamic> responseList = response as List<dynamic>;
        final members = List<Map<String, dynamic>>.from(responseList);
        devLogSuccess('Swipe counts opgehaald voor ${members.length} members');

        // Log first member for debugging
        if (members.isNotEmpty) {
          devLog('First member data: ${members.first}');
        }

        return members;
      },
      'getMemberSwipeCounts',
      metadata: {'sessionId': sessionId},
    );
  }

  /// Update session filters (host only)
  @override
  Future<Result<bool>> updateSessionFilters({
    required String sessionId,
    required List<String> streamingProviders,
    required List<String> genres,
    required String maxCertification,
  }) async {
    return executeWithErrorHandling(
      () async {
        await client.rpc<dynamic>('update_session_filters', params: {
          'p_session_id': sessionId,
          'p_streaming_providers': streamingProviders,
          'p_genres': genres,
          'p_max_certification': maxCertification,
        });

        devLogSuccess('Session filters bijgewerkt');
        return true;
      },
      'updateSessionFilters',
      metadata: {'sessionId': sessionId},
    );
  }

  /// Get session statistics
  @override
  Future<Result<Map<String, dynamic>>> getSessionStats(String sessionId) async {
    return executeWithErrorHandling(
      () async {
        final response = await client.rpc<dynamic>('get_session_stats', params: {
          'p_session_id': sessionId,
        }) as Map<String, dynamic>;

        devLogSuccess('Session stats opgehaald');
        return response;
      },
      'getSessionStats',
      metadata: {'sessionId': sessionId},
    );
  }
}
