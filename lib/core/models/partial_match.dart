import 'movie.dart';

/// PartialMatch model - Represents a movie that has some likes but not enough for a full match
class PartialMatch {
  const PartialMatch({
    required this.movieId,
    required this.likeCount,
    required this.requiredVotes,
    required this.movieData,
  });

  final int movieId;
  final int likeCount;
  final int requiredVotes;
  final Map<String, dynamic> movieData;

  /// Create PartialMatch from Supabase JSON
  factory PartialMatch.fromJson(Map<String, dynamic> json) {
    // Handle nullable fields from Supabase RPC
    final movieId = json['movie_id'];
    final likeCount = json['like_count'];
    final requiredVotes = json['required_votes'];
    final movieData = json['movie_data'];

    if (movieId == null || likeCount == null || requiredVotes == null || movieData == null) {
      throw FormatException(
        'Missing required fields in PartialMatch.fromJson: '
        'movieId=$movieId, likeCount=$likeCount, requiredVotes=$requiredVotes, movieData=$movieData. '
        'Full JSON: $json'
      );
    }

    return PartialMatch(
      movieId: movieId as int,
      likeCount: likeCount as int,
      requiredVotes: requiredVotes as int,
      movieData: movieData as Map<String, dynamic>,
    );
  }

  /// Convert PartialMatch to JSON
  Map<String, dynamic> toJson() {
    return {
      'movie_id': movieId,
      'like_count': likeCount,
      'required_votes': requiredVotes,
      'movie_data': movieData,
    };
  }

  /// Get Movie object from movieData
  Movie get movie => Movie.fromJson(movieData);

  /// Display text for badge: "X/Y likes"
  String get displayText => '$likeCount/$requiredVotes likes';

  /// How many more likes are needed
  int get likesNeeded => requiredVotes - likeCount;

  /// Subtitle text: "Nog X like(s) nodig"
  String get subtitle {
    final needed = likesNeeded;
    return 'Nog $needed like${needed == 1 ? '' : 's'} nodig';
  }

  /// Create a copy with modified fields
  PartialMatch copyWith({
    int? movieId,
    int? likeCount,
    int? requiredVotes,
    Map<String, dynamic>? movieData,
  }) {
    return PartialMatch(
      movieId: movieId ?? this.movieId,
      likeCount: likeCount ?? this.likeCount,
      requiredVotes: requiredVotes ?? this.requiredVotes,
      movieData: movieData ?? this.movieData,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PartialMatch && other.movieId == movieId;
  }

  @override
  int get hashCode => movieId.hashCode;

  @override
  String toString() {
    return 'PartialMatch(movieId: $movieId, likeCount: $likeCount/$requiredVotes)';
  }
}
