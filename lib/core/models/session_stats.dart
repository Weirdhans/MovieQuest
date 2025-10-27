/// SessionStats model - Statistics about a swipe session
class SessionStats {
  final int totalSwipes;
  final int memberCount;
  final int totalMovies;
  final int likeCount;
  final int dislikeCount;

  const SessionStats({
    required this.totalSwipes,
    required this.memberCount,
    required this.totalMovies,
    required this.likeCount,
    required this.dislikeCount,
  });

  /// Create SessionStats from Supabase JSON response
  factory SessionStats.fromJson(Map<String, dynamic> json) {
    return SessionStats(
      totalSwipes: json['total_swipes'] as int? ?? 0,
      memberCount: json['member_count'] as int? ?? 0,
      totalMovies: json['total_movies'] as int? ?? 0,
      likeCount: json['like_count'] as int? ?? 0,
      dislikeCount: json['dislike_count'] as int? ?? 0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'total_swipes': totalSwipes,
      'member_count': memberCount,
      'total_movies': totalMovies,
      'like_count': likeCount,
      'dislike_count': dislikeCount,
    };
  }

  /// Get like percentage (0-100)
  double get likePercentage {
    if (totalSwipes == 0) return 0.0;
    return (likeCount / totalSwipes) * 100;
  }

  /// Get average swipes per member
  double get averageSwipesPerMember {
    if (memberCount == 0) return 0.0;
    return totalSwipes / memberCount;
  }

  /// Create a copy with modified fields
  SessionStats copyWith({
    int? totalSwipes,
    int? memberCount,
    int? totalMovies,
    int? likeCount,
    int? dislikeCount,
  }) {
    return SessionStats(
      totalSwipes: totalSwipes ?? this.totalSwipes,
      memberCount: memberCount ?? this.memberCount,
      totalMovies: totalMovies ?? this.totalMovies,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SessionStats &&
        other.totalSwipes == totalSwipes &&
        other.memberCount == memberCount &&
        other.totalMovies == totalMovies &&
        other.likeCount == likeCount &&
        other.dislikeCount == dislikeCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      totalSwipes,
      memberCount,
      totalMovies,
      likeCount,
      dislikeCount,
    );
  }

  @override
  String toString() {
    return 'SessionStats(totalSwipes: $totalSwipes, memberCount: $memberCount, '
        'totalMovies: $totalMovies, likeCount: $likeCount, dislikeCount: $dislikeCount)';
  }
}
