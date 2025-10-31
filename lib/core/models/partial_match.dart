import 'movie.dart';

/// PartialMatch model - Represents a movie that has some likes but not enough for a full match
class PartialMatch {
  const PartialMatch({
    required this.movieId,
    required this.likeCount,
    required this.requiredVotes,
    required this.movieData,
    this.voterNames = const [],
  });

  final int movieId;
  final int likeCount;
  final int requiredVotes;
  final Map<String, dynamic> movieData;
  final List<String> voterNames;

  /// Create PartialMatch from Supabase JSON
  ///
  /// Expects data from get_partial_matches RPC function with fields:
  /// - movie_id: TMDB movie ID
  /// - like_count: Number of likes this movie has received
  /// - required_votes: Total votes needed for a match (from session.required_votes)
  /// - movie_data: Full TMDB movie data (title, poster, etc.)
  /// - voter_names: Array of user names who liked this movie (optional)
  factory PartialMatch.fromJson(Map<String, dynamic> json) {
    // Parse required fields from Supabase RPC response
    final movieId = json['movie_id'];
    final likeCount = json['like_count'];
    final requiredVotes = json['required_votes'];
    final movieData = json['movie_data'];
    // Try both 'voter_names' and 'voters' field names for backward compatibility
    final voterNames = json['voter_names'] ?? json['voters'];

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
      voterNames: voterNames != null ? List<String>.from(voterNames as List) : [],
    );
  }

  /// Convert PartialMatch to JSON
  Map<String, dynamic> toJson() {
    return {
      'movie_id': movieId,
      'like_count': likeCount,
      'required_votes': requiredVotes,
      'movie_data': movieData,
      'voter_names': voterNames,
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
    List<String>? voterNames,
  }) {
    return PartialMatch(
      movieId: movieId ?? this.movieId,
      likeCount: likeCount ?? this.likeCount,
      requiredVotes: requiredVotes ?? this.requiredVotes,
      movieData: movieData ?? this.movieData,
      voterNames: voterNames ?? this.voterNames,
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
