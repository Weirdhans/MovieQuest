import '../utils/string_utils.dart';

/// Movie model - Represents a movie from TMDB
class Movie {
  const Movie({
    required this.id,
    required this.title,
    this.originalTitle,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.voteAverage,
    this.voteCount,
    this.releaseDate,
    this.genreIds,
    this.adult,
    this.originalLanguage,
    this.popularity,
    this.video,
  });

  final int id;
  final String title;
  final String? originalTitle;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final double? voteAverage;
  final int? voteCount;
  final String? releaseDate;
  final List<int>? genreIds;
  final bool? adult;
  final String? originalLanguage;
  final double? popularity;
  final bool? video;

  /// Create Movie from TMDB JSON
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int,
      title: json['title'] as String,
      originalTitle: json['original_title'] as String?,
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: json['vote_count'] as int?,
      releaseDate: json['release_date'] as String?,
      genreIds: (json['genre_ids'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      adult: json['adult'] as bool?,
      originalLanguage: json['original_language'] as String?,
      popularity: (json['popularity'] as num?)?.toDouble(),
      video: json['video'] as bool?,
    );
  }

  /// Convert Movie to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'original_title': originalTitle,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'vote_average': voteAverage,
      'vote_count': voteCount,
      'release_date': releaseDate,
      'genre_ids': genreIds,
      'adult': adult,
      'original_language': originalLanguage,
      'popularity': popularity,
      'video': video,
    };
  }

  /// Get full poster URL
  String? getPosterUrl({String size = 'w500'}) {
    if (posterPath == null) return null;
    return 'https://image.tmdb.org/t/p/$size$posterPath';
  }

  /// Get full backdrop URL
  String? getBackdropUrl({String size = 'w1280'}) {
    if (backdropPath == null) return null;
    return 'https://image.tmdb.org/t/p/$size$backdropPath';
  }

  /// Get release year
  int? get releaseYear {
    if (releaseDate == null || releaseDate!.isEmpty) return null;
    try {
      return DateTime.parse(releaseDate!).year;
    } catch (_) {
      return null;
    }
  }

  /// Get display title with smart fallback
  ///
  /// Returns a readable title with preference: Dutch → English → Original
  /// Fallback logic:
  /// 1. If `title` has non-Latin characters (Japanese, Chinese, etc.) → use `originalTitle` if readable
  /// 2. If `originalLanguage` is English or Dutch → prefer `originalTitle`
  /// 3. Otherwise use `title` (Dutch translation from TMDB)
  ///
  /// Examples:
  /// - title: "劇場版「鬼滅の刃」", originalTitle: "Demon Slayer: Mugen Train" → Returns "Demon Slayer: Mugen Train"
  /// - title: "Batman Azteca: Choque de imperios" (Spanish), originalLanguage: "en", originalTitle: "Batman Azteca: Clash of Empires" → Returns English original
  /// - title: "Squid Game" (Dutch), originalLanguage: "ko" → Returns "Squid Game" (Dutch translation)
  /// - title: "Inception", originalLanguage: "en" → Returns "Inception"
  String get displayTitle {
    // Priority 1: Avoid non-Latin scripts (Japanese, Chinese, Arabic, etc.)
    if (containsNonLatinScript(title)) {
      // Try to use originalTitle if it's readable (Latin script)
      if (originalTitle != null && !containsNonLatinScript(originalTitle!)) {
        return originalTitle!;
      }
      // Both have non-Latin characters, return title as fallback
      return title;
    }

    // Priority 2: Prefer English/Dutch originals over other language translations
    // If the original language is English or Dutch, use the original title
    if (originalLanguage != null &&
        (originalLanguage == 'en' || originalLanguage == 'nl') &&
        originalTitle != null &&
        originalTitle!.isNotEmpty) {
      return originalTitle!;
    }

    // Priority 3: Use TMDB's translated title (usually Dutch if available)
    return title;
  }

  /// Create a copy with modified fields
  Movie copyWith({
    int? id,
    String? title,
    String? originalTitle,
    String? overview,
    String? posterPath,
    String? backdropPath,
    double? voteAverage,
    int? voteCount,
    String? releaseDate,
    List<int>? genreIds,
    bool? adult,
    String? originalLanguage,
    double? popularity,
    bool? video,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      voteAverage: voteAverage ?? this.voteAverage,
      voteCount: voteCount ?? this.voteCount,
      releaseDate: releaseDate ?? this.releaseDate,
      genreIds: genreIds ?? this.genreIds,
      adult: adult ?? this.adult,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      popularity: popularity ?? this.popularity,
      video: video ?? this.video,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Movie && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Movie(id: $id, title: $title, releaseYear: $releaseYear)';
  }
}
