/// Session model - Represents a movie matching session
class Session {
  const Session({
    required this.id,
    required this.hostUserId,
    required this.streamingProviders,
    required this.genres,
    required this.maxCertification,
    required this.isActive,
    required this.totalMembers,
    required this.requiredVotes,
    required this.createdAt,
    this.excludedGenres,
    this.updatedAt,
    this.minRating,
    this.minYear,
    this.maxYear,
    this.sortBy,
  });

  final String id;
  final String hostUserId;
  final List<String> streamingProviders;
  final List<String> genres;
  final String maxCertification;
  final bool isActive;
  final int totalMembers;
  final int requiredVotes;
  final DateTime createdAt;
  final List<String>? excludedGenres; // Optional for backward compatibility
  final DateTime? updatedAt;

  // Filter and sort options (added for filtering/sorting features)
  final double? minRating;        // Minimum TMDB rating (1.0-10.0), null = no filter
  final int? minYear;             // Release year start (1888-present), null = no filter
  final int? maxYear;             // Release year end (saved as DateTime.now().year at creation)
  final String? sortBy;           // Sort option, null/'popularity.desc' = default

  /// Create Session from Supabase JSON
  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      hostUserId: json['host_user_id'] as String,
      streamingProviders: (json['streaming_providers'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      genres: (json['genres'] as List<dynamic>).map((e) => e.toString()).toList(),
      maxCertification: json['max_certification'] as String,
      isActive: json['is_active'] as bool? ?? true,
      totalMembers: json['total_members'] as int? ?? 1,
      requiredVotes: json['required_votes'] as int? ?? 2,
      createdAt: DateTime.parse(json['created_at'] as String),
      excludedGenres: json['excluded_genres'] != null
          ? (json['excluded_genres'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      minRating: json['min_rating'] as double?,
      minYear: json['min_year'] as int?,
      maxYear: json['max_year'] as int?,
      sortBy: json['sort_by'] as String?,
    );
  }

  /// Convert Session to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'host_user_id': hostUserId,
      'streaming_providers': streamingProviders,
      'genres': genres,
      'max_certification': maxCertification,
      'is_active': isActive,
      'total_members': totalMembers,
      'required_votes': requiredVotes,
      'created_at': createdAt.toIso8601String(),
      if (excludedGenres != null) 'excluded_genres': excludedGenres,
      'updated_at': updatedAt?.toIso8601String(),
      if (minRating != null) 'min_rating': minRating,
      if (minYear != null) 'min_year': minYear,
      if (maxYear != null) 'max_year': maxYear,
      if (sortBy != null) 'sort_by': sortBy,
    };
  }

  /// Create a copy with modified fields
  Session copyWith({
    String? id,
    String? hostUserId,
    List<String>? streamingProviders,
    List<String>? genres,
    String? maxCertification,
    bool? isActive,
    int? totalMembers,
    int? requiredVotes,
    DateTime? createdAt,
    List<String>? excludedGenres,
    DateTime? updatedAt,
    double? minRating,
    int? minYear,
    int? maxYear,
    String? sortBy,
  }) {
    return Session(
      id: id ?? this.id,
      hostUserId: hostUserId ?? this.hostUserId,
      streamingProviders: streamingProviders ?? this.streamingProviders,
      genres: genres ?? this.genres,
      maxCertification: maxCertification ?? this.maxCertification,
      isActive: isActive ?? this.isActive,
      totalMembers: totalMembers ?? this.totalMembers,
      requiredVotes: requiredVotes ?? this.requiredVotes,
      createdAt: createdAt ?? this.createdAt,
      excludedGenres: excludedGenres ?? this.excludedGenres,
      updatedAt: updatedAt ?? this.updatedAt,
      minRating: minRating ?? this.minRating,
      minYear: minYear ?? this.minYear,
      maxYear: maxYear ?? this.maxYear,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Session && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Session(id: $id, hostUserId: $hostUserId, totalMembers: $totalMembers, requiredVotes: $requiredVotes)';
  }
}
