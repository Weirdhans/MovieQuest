import 'package:dio/dio.dart';
import '../../core/config/env_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/base_service.dart';
import '../../core/errors/result.dart';
import '../../core/errors/app_error.dart';
import '../../core/utils/dev_log.dart';
import '../../core/utils/string_utils.dart';
import '../../core/interfaces/i_tmdb_service.dart';

/// TMDB Service - Handles all TMDB API interactions
/// Direct port of tmdb.js from web version
class TmdbService extends BaseService implements ITmdbService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: EnvConfig.tmdbBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static final TmdbService _instance = TmdbService._();
  TmdbService._();
  factory TmdbService() => _instance;

  // Cache for fetched movies to prevent duplicate API calls
  static final Map<String, Map<String, dynamic>> _moviesCache = {};

  /// Seeded random number generator (mulberry32 algorithm)
  static double Function() _seededRandom(int seed) {
    return () {
      seed = (seed + 0x6D2B79F5) & 0xFFFFFFFF;
      int t = (seed ^ (seed >>> 15)) & 0xFFFFFFFF;
      t = (t | 1) & 0xFFFFFFFF;
      t = (t + ((t ^ (t >>> 7)) & 0x3FFFFFFF)) & 0xFFFFFFFF;
      final int result = ((t ^ (t >>> 14)) >>> 0) & 0xFFFFFFFF;
      return result / 4294967296;
    };
  }

  /// Shuffle array with seeded random (Fisher-Yates shuffle)
  static List<T> _seededShuffle<T>(List<T> array, String seed) {
    // Convert string seed to numeric seed
    @override
    int numericSeed = 0;
    for (int i = 0; i < seed.length; i++) {
      numericSeed = ((numericSeed << 5) - numericSeed + seed.codeUnitAt(i)) & 0xFFFFFFFF;
    }

    final rng = _seededRandom(numericSeed);
    final shuffled = List<T>.from(array);

    // Fisher-Yates shuffle with seeded random
    for (int i = shuffled.length - 1; i > 0; i--) {
      final j = (rng() * (i + 1)).floor();
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }

    return shuffled;
  }

  /// Enrich movies with English titles for non-Dutch/English titles
  ///
  /// Fetches English titles from TMDB API with `language=en-US` for movies that likely
  /// need translation (non-English/Dutch originals or non-Latin scripts).
  ///
  /// Strategy: Always prefer English over other languages (Spanish, French, Japanese, etc.)
  /// Users can still see original titles on movie posters.
  ///
  /// This fixes cases like:
  /// - "劇場版 呪術廻戦 0" → "Jujutsu Kaisen 0"
  /// - "Batman Azteca: Choque de imperios" → "Aztec Batman: Clash of Empires"
  /// - "Le Fabuleux Destin d'Amélie Poulain" → "Amélie"
  static Future<List<dynamic>> _enrichMoviesWithEnglishTitles(List<dynamic> movies) async {
    final enrichedMovies = <dynamic>[];

    for (final movie in movies) {
      final currentTitle = movie['title'] as String?;
      final originalTitle = movie['original_title'] as String?;
      final originalLanguage = movie['original_language'] as String?;

      if (currentTitle == null) {
        enrichedMovies.add(movie);
        continue;
      }

      // Skip enrichment if:
      // 1. Original language is already English or Dutch (no need for English fallback)
      // 2. Title and original_title are the same AND it's Latin script (likely already English)
      final isEnglishOrDutchOriginal = originalLanguage == 'en' || originalLanguage == 'nl';
      final titleMatchesOriginal = currentTitle == originalTitle;
      final isLatinScript = !containsNonLatinScript(currentTitle);

      if (isEnglishOrDutchOriginal || (titleMatchesOriginal && isLatinScript)) {
        enrichedMovies.add(movie);
        continue;
      }

      // Fetch English title for likely non-English/Dutch films
      try {
        final movieId = movie['id'] as int;
        final response = await _dio.get<dynamic>(
          '/movie/$movieId',
          queryParameters: {
            'api_key': EnvConfig.tmdbApiKey,
            'language': 'en-US',
          },
        );

        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          final englishTitle = data['title'] as String?;

          // Replace title with English version if:
          // 1. English title exists and is different from current
          // 2. English title is readable (Latin script)
          if (englishTitle != null &&
              englishTitle != currentTitle &&
              !containsNonLatinScript(englishTitle)) {
            movie['title'] = englishTitle;
            devLog('Enriched movie $movieId: "$currentTitle" → "$englishTitle"');
          }
        }
      } catch (e) {
        // Silently continue if enrichment fails - not critical
        devLogError('Failed to enrich movie ${movie['id']} with English title',
          AppError.unknown(message: e.toString()));
      }

      enrichedMovies.add(movie);
    }

    return enrichedMovies;
  }

  /// Fetch movies from TMDB Discover API with filters
  @override
  Future<Result<Map<String, dynamic>>> fetchMovies({
    required List<String> providers,
    required List<String> genres,
    required String maxCertification,
    String genreMatchMode = 'or',
    List<String>? excludedGenres,
    String? sessionId,
    int page = 1,
  }) async {
    return executeWithErrorHandling(
      () async {
        // Check cache
        final excludedKey = excludedGenres?.join(',') ?? '';
        final cacheKey = '${providers.join(',')}-${genres.join(',')}-$maxCertification-$genreMatchMode-$excludedKey-$page';
        if (_moviesCache.containsKey(cacheKey)) {
          devLog('Films geladen uit cache: $cacheKey');
          return _moviesCache[cacheKey]!;
        }

        // Build query parameters
        final params = {
          'api_key': EnvConfig.tmdbApiKey,
          'language': AppConstants.language,
          'region': AppConstants.region,
          'watch_region': AppConstants.region,
          'sort_by': AppConstants.defaultSort,
          'vote_count.gte': AppConstants.minVoteCount,
          'page': page,
        };

        // Add streaming providers
        if (providers.isNotEmpty) {
          params['with_watch_providers'] = providers.join('|');
        }

        // Add genres (OR vs AND logic)
        if (genres.isNotEmpty) {
          if (genreMatchMode == 'all' || genreMatchMode == 'and') {
            params['with_genres'] = genres.join(','); // AND: comma-separated
          } else {
            params['with_genres'] = genres.join('|'); // OR: pipe-separated (default)
          }
        }

        // Add excluded genres (always AND logic)
        if (excludedGenres != null && excludedGenres.isNotEmpty) {
          params['without_genres'] = excludedGenres.join(',');
        }

        // Add certification (max age rating)
        if (maxCertification != 'AL') {
          params['certification_country'] = 'NL';
          params['certification.lte'] = maxCertification;
        }

        // Make API request
        final response = await _dio.get<dynamic>('/discover/movie', queryParameters: params);

        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          List<dynamic> results = (data['results'] as List<dynamic>?) ?? [];

          // Enrich movies with English titles for non-Latin scripts
          if (results.isNotEmpty) {
            results = await _enrichMoviesWithEnglishTitles(results);
          }

          // Apply seeded shuffle if sessionId provided
          if (sessionId != null && results.isNotEmpty) {
            results = _seededShuffle(results, sessionId);
          }

          final result = {
            'results': results,
            'page': data['page'] ?? page,
            'totalPages': data['total_pages'] ?? 0,
            'totalResults': data['total_results'] ?? 0,
          };

          // Cache result
          _moviesCache[cacheKey] = result;

          devLogSuccess('${results.length} films opgehaald van TMDB (pagina $page)');
          return result;
        } else {
          throw AppError.api(
            message: 'TMDB API error: ${response.statusCode}',
            statusCode: response.statusCode,
          );
        }
      },
      'fetchMovies',
      metadata: {'page': page, 'providers': providers.length, 'genres': genres.length},
    );
  }

  /// Get poster URL for a movie
  @override
  String getPosterUrl(String? posterPath, {String size = 'w500'}) {
    if (posterPath == null || posterPath.isEmpty) {
      return 'https://via.placeholder.com/500x750/1A1A1A/FFB800?text=No+Poster';
    }
    return '${EnvConfig.tmdbImageBase.replaceAll('w500', size)}$posterPath';
  }

  /// Prefetch next page of movies (for smooth pagination)
  @override
  Future<void> prefetchNextPage({
    required List<String> providers,
    required List<String> genres,
    required String maxCertification,
    String genreMatchMode = 'or',
    List<String>? excludedGenres,
    String? sessionId,
    required int currentPage,
  }) async {
    final nextPage = currentPage + 1;
    devLog('Prefetching pagina $nextPage...');

    await fetchMovies(
      providers: providers,
      genres: genres,
      maxCertification: maxCertification,
      genreMatchMode: genreMatchMode,
      excludedGenres: excludedGenres,
      sessionId: sessionId,
      page: nextPage,
    );
  }

  /// Clear movies cache
  @override
  void clearCache() {
    _moviesCache.clear();
    devLogSuccess('Movies cache geleegd');
  }

  /// Fetch movie trailer from YouTube with multi-language fallback
  /// Priority system:
  /// 1. Dutch Official Trailer
  /// 2. English Official Trailer
  /// 3. Any Dutch Trailer
  /// 4. Any English Trailer
  /// 5. English Teaser
  /// 6. First YouTube video (any type)
  @override
  Future<Result<String?>> fetchMovieTrailer(int movieId) async {
    return executeWithErrorHandling(
      () async {
        // Fetch ALL videos (without language filter for maximum results)
        final response = await _dio.get<dynamic>(
          '/movie/$movieId/videos',
          queryParameters: {
            'api_key': EnvConfig.tmdbApiKey,
            // No language parameter - fetch all languages
          },
        );

        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          final videos = (data['results'] as List<dynamic>?)
              ?.where((v) => (v as Map<String, dynamic>)['site'] == 'YouTube')
              .cast<Map<String, dynamic>>()
              .toList();

          if (videos == null || videos.isEmpty) {
            return null;
          }

          Map<String, dynamic>? trailer;

          // Priority 1: Dutch Official Trailer
          trailer = videos.cast<Map<String, dynamic>?>().firstWhere(
            (v) =>
                v != null &&
                v['iso_639_1'] == 'nl' &&
                v['type'] == 'Trailer' &&
                v['official'] == true,
            orElse: () => null,
          );

          // Priority 2: English Official Trailer
          trailer ??= videos.cast<Map<String, dynamic>?>().firstWhere(
            (v) =>
                v != null &&
                v['iso_639_1'] == 'en' &&
                v['type'] == 'Trailer' &&
                v['official'] == true,
            orElse: () => null,
          );

          // Priority 3: Any Dutch Trailer
          trailer ??= videos.cast<Map<String, dynamic>?>().firstWhere(
            (v) =>
                v != null &&
                v['iso_639_1'] == 'nl' &&
                v['type'] == 'Trailer',
            orElse: () => null,
          );

          // Priority 4: Any English Trailer
          trailer ??= videos.cast<Map<String, dynamic>?>().firstWhere(
            (v) =>
                v != null &&
                v['iso_639_1'] == 'en' &&
                v['type'] == 'Trailer',
            orElse: () => null,
          );

          // Priority 5: English Teaser
          trailer ??= videos.cast<Map<String, dynamic>?>().firstWhere(
            (v) =>
                v != null &&
                v['iso_639_1'] == 'en' &&
                v['type'] == 'Teaser',
            orElse: () => null,
          );

          // Priority 6: First YouTube video (any type)
          if (trailer == null && videos.isNotEmpty) {
            trailer = videos.first;
          }

          if (trailer != null) {
            final youtubeKey = trailer['key'] as String?;
            if (youtubeKey != null) {
              devLog(
                'Trailer gevonden: ${trailer['name']} (${trailer['iso_639_1']}, ${trailer['type']})',
              );
              return youtubeKey; // Return just the video ID for youtube_player_iframe
            }
          }
        }

        // No trailer found
        return null;
      },
      'fetchMovieTrailer',
      metadata: {'movieId': movieId},
    );
  }

  /// Get movie details
  @override
  Future<Result<Map<String, dynamic>>> getMovieDetails(int movieId) async {
    return executeWithErrorHandling(
      () async {
        final response = await _dio.get<dynamic>(
          '/movie/$movieId',
          queryParameters: {
            'api_key': EnvConfig.tmdbApiKey,
            'language': AppConstants.language,
          },
        );

        if (response.statusCode == 200) {
          return response.data as Map<String, dynamic>;
        }

        throw AppError.api(
          message: 'Failed to fetch movie details',
          statusCode: response.statusCode,
        );
      },
      'getMovieDetails',
      metadata: {'movieId': movieId},
    );
  }

  /// Search movies by title
  @override
  Future<Result<List<dynamic>>> searchMovies(String query) async {
    return executeWithErrorHandling(
      () async {
        final response = await _dio.get<dynamic>(
          '/search/movie',
          queryParameters: {
            'api_key': EnvConfig.tmdbApiKey,
            'language': AppConstants.language,
            'query': query,
            'region': AppConstants.region,
          },
        );

        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          return (data['results'] as List<dynamic>?) ?? [];
        }

        throw AppError.api(
          message: 'Failed to search movies',
          statusCode: response.statusCode,
        );
      },
      'searchMovies',
      metadata: {'query': query},
    );
  }

  /// Get movie credits (cast & crew)
  @override
  Future<Result<Map<String, dynamic>>> getMovieCredits(int movieId) async {
    return executeWithErrorHandling(
      () async {
        final response = await _dio.get<dynamic>(
          '/movie/$movieId/credits',
          queryParameters: {
            'api_key': EnvConfig.tmdbApiKey,
          },
        );

        if (response.statusCode == 200) {
          return response.data as Map<String, dynamic>;
        }

        throw AppError.api(
          message: 'Failed to fetch movie credits',
          statusCode: response.statusCode,
        );
      },
      'getMovieCredits',
      metadata: {'movieId': movieId},
    );
  }
}
