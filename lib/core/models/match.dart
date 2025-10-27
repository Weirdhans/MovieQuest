import 'movie.dart';

/// Match model - Represents a matched movie
class Match {
  const Match({
    required this.id,
    required this.sessionId,
    required this.movieId,
    required this.movieData,
    required this.likesCount,
    required this.matchedAt,
  });

  final String id;
  final String sessionId;
  final int movieId;
  final Map<String, dynamic> movieData;
  final int likesCount;
  final DateTime matchedAt;

  /// Create Match from Supabase JSON
  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      movieId: json['movie_id'] as int,
      movieData: json['movie_data'] as Map<String, dynamic>,
      likesCount: json['likes_count'] as int? ?? 0,
      matchedAt: DateTime.parse(json['matched_at'] as String),
    );
  }

  /// Convert Match to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'movie_id': movieId,
      'movie_data': movieData,
      'likes_count': likesCount,
      'matched_at': matchedAt.toIso8601String(),
    };
  }

  /// Get Movie object from movieData
  Movie get movie => Movie.fromJson(movieData);

  /// Create a copy with modified fields
  Match copyWith({
    String? id,
    String? sessionId,
    int? movieId,
    Map<String, dynamic>? movieData,
    int? likesCount,
    DateTime? matchedAt,
  }) {
    return Match(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      movieId: movieId ?? this.movieId,
      movieData: movieData ?? this.movieData,
      likesCount: likesCount ?? this.likesCount,
      matchedAt: matchedAt ?? this.matchedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Match && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Match(id: $id, movieId: $movieId, likesCount: $likesCount)';
  }
}
