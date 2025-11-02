import '../errors/result.dart';

/// Interface for TMDB Service - Enables dependency injection and testing
abstract class ITmdbService {
  Future<Result<Map<String, dynamic>>> fetchMovies({
    required List<String> providers,
    required List<String> genres,
    required String maxCertification,
    String genreMatchMode = 'or',
    List<String>? excludedGenres,
    String? sessionId,
    int page = 1,
    double? minRating,
    int? minYear,
    int? maxYear,
    String sortBy = 'popularity.desc',
  });

  String getPosterUrl(String? posterPath, {String size = 'w500'});

  Future<void> prefetchNextPage({
    required List<String> providers,
    required List<String> genres,
    required String maxCertification,
    String genreMatchMode = 'or',
    List<String>? excludedGenres,
    String? sessionId,
    required int currentPage,
  });

  void clearCache();

  Future<Result<String?>> fetchMovieTrailer(int movieId);
  Future<Result<Map<String, dynamic>>> getMovieDetails(int movieId);
  Future<Result<List<dynamic>>> searchMovies(String query);
  Future<Result<Map<String, dynamic>>> getMovieCredits(int movieId);
  Future<Result<List<Map<String, dynamic>>>> fetchMovieProviders(int movieId);
}
