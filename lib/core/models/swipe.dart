/// Swipe model - Represents a user's swipe action
class Swipe {
  const Swipe({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.movieId,
    required this.swipedRight,
    this.movieData,
    required this.swipedAt,
  });

  final String id;
  final String sessionId;
  final String userId;
  final int movieId;
  final bool swipedRight;
  final Map<String, dynamic>? movieData;
  final DateTime swipedAt;

  /// Create Swipe from Supabase JSON
  factory Swipe.fromJson(Map<String, dynamic> json) {
    return Swipe(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      userId: json['user_id'] as String,
      movieId: json['movie_id'] as int,
      swipedRight: json['swiped_right'] as bool,
      movieData: json['movie_data'] as Map<String, dynamic>?,
      swipedAt: DateTime.parse(json['swiped_at'] as String),
    );
  }

  /// Convert Swipe to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'movie_id': movieId,
      'swiped_right': swipedRight,
      'movie_data': movieData,
      'swiped_at': swipedAt.toIso8601String(),
    };
  }

  /// Is this a like?
  bool get isLike => swipedRight;

  /// Is this a dislike?
  bool get isDislike => !swipedRight;

  /// Create a copy with modified fields
  Swipe copyWith({
    String? id,
    String? sessionId,
    String? userId,
    int? movieId,
    bool? swipedRight,
    Map<String, dynamic>? movieData,
    DateTime? swipedAt,
  }) {
    return Swipe(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      movieId: movieId ?? this.movieId,
      swipedRight: swipedRight ?? this.swipedRight,
      movieData: movieData ?? this.movieData,
      swipedAt: swipedAt ?? this.swipedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Swipe && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Swipe(id: $id, movieId: $movieId, swipedRight: $swipedRight)';
  }
}
