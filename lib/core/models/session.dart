import '../enums/content_type.dart';

/// Session model - Represents a content matching session (movies or board games)
class Session {
  const Session({
    required this.id,
    required this.hostUserId,
    required this.isActive,
    required this.totalMembers,
    required this.requiredVotes,
    required this.createdAt,
    this.contentType = ContentType.movie, // Default to movie for backward compatibility
    this.streamingProviders,
    this.genres,
    this.maxCertification,
    this.excludedGenres,
    this.updatedAt,
    this.minRating,
    this.minYear,
    this.maxYear,
    this.sortBy,
    this.isChristmasMode,
    this.allowMemberCollections,
    this.gameTypes,
    this.gameCategories,
    this.gameMechanisms,
    this.minPlayers,
    this.maxPlayers,
    this.minAge,
    this.maxComplexity,
    this.minRank,
  });

  final String id;
  final String hostUserId;
  final bool isActive;
  final int totalMembers;
  final int requiredVotes;
  final DateTime createdAt;
  final ContentType contentType; // Type of content (movie, boardGame, etc.)
  final DateTime? updatedAt;

  // Movie-specific fields (nullable for board games)
  final List<String>? streamingProviders;
  final List<String>? genres;
  final String? maxCertification;
  final List<String>? excludedGenres;

  // Shared filter options (for both movies and board games)
  final double? minRating;        // Minimum rating (TMDB or BGG), null = no filter
  final int? minYear;             // Release/publish year start, null = no filter
  final int? maxYear;             // Release/publish year end, null = no filter
  final String? sortBy;           // Sort option, null = default
  final bool? isChristmasMode;    // Christmas filter enabled, null = false (backward compat)

  // Board game specific fields (nullable for movies)
  final bool? allowMemberCollections; // If true, all members can add their games
  final List<String>? gameTypes;      // Base game, expansion, etc.
  final List<String>? gameCategories; // Strategy, Family, Party, etc.
  final List<String>? gameMechanisms; // Worker placement, Deck building, etc.
  final int? minPlayers;              // Minimum player count
  final int? maxPlayers;              // Maximum player count
  final int? minAge;                  // Minimum age rating
  final double? maxComplexity;        // Maximum BGG complexity (1.0-5.0)
  final int? minRank;                 // Minimum BGG rank (lower is better)

  /// Create Session from Supabase JSON
  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      hostUserId: json['host_user_id'] as String,
      isActive: json['is_active'] as bool? ?? true,
      totalMembers: json['total_members'] as int? ?? 1,
      requiredVotes: json['required_votes'] as int? ?? 2,
      createdAt: DateTime.parse(json['created_at'] as String),
      contentType: json['content_type'] != null
          ? ContentType.fromString(json['content_type'] as String)
          : ContentType.movie, // Default for backward compatibility
      streamingProviders: json['streaming_providers'] != null
          ? (json['streaming_providers'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
          : null,
      genres: json['genres'] != null
          ? (json['genres'] as List<dynamic>).map((e) => e.toString()).toList()
          : null,
      maxCertification: json['max_certification'] as String?,
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
      isChristmasMode: json['is_christmas_mode'] as bool?,
      allowMemberCollections: json['allow_member_collections'] as bool?,
      gameTypes: json['game_types'] != null
          ? (json['game_types'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
          : null,
      gameCategories: json['game_categories'] != null
          ? (json['game_categories'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
          : null,
      gameMechanisms: json['game_mechanisms'] != null
          ? (json['game_mechanisms'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
          : null,
      minPlayers: json['min_players'] as int?,
      maxPlayers: json['max_players'] as int?,
      minAge: json['min_age'] as int?,
      maxComplexity: json['max_complexity'] != null
          ? (json['max_complexity'] as num).toDouble()
          : null,
      minRank: json['min_rank'] as int?,
    );
  }

  /// Convert Session to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'host_user_id': hostUserId,
      'is_active': isActive,
      'total_members': totalMembers,
      'required_votes': requiredVotes,
      'created_at': createdAt.toIso8601String(),
      'content_type': contentType.toJson(),
      if (streamingProviders != null) 'streaming_providers': streamingProviders,
      if (genres != null) 'genres': genres,
      if (maxCertification != null) 'max_certification': maxCertification,
      if (excludedGenres != null) 'excluded_genres': excludedGenres,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (minRating != null) 'min_rating': minRating,
      if (minYear != null) 'min_year': minYear,
      if (maxYear != null) 'max_year': maxYear,
      if (sortBy != null) 'sort_by': sortBy,
      if (isChristmasMode != null) 'is_christmas_mode': isChristmasMode,
      if (allowMemberCollections != null) 'allow_member_collections': allowMemberCollections,
      if (gameTypes != null) 'game_types': gameTypes,
      if (gameCategories != null) 'game_categories': gameCategories,
      if (gameMechanisms != null) 'game_mechanisms': gameMechanisms,
      if (minPlayers != null) 'min_players': minPlayers,
      if (maxPlayers != null) 'max_players': maxPlayers,
      if (minAge != null) 'min_age': minAge,
      if (maxComplexity != null) 'max_complexity': maxComplexity,
      if (minRank != null) 'min_rank': minRank,
    };
  }

  /// Create a copy with modified fields
  Session copyWith({
    String? id,
    String? hostUserId,
    bool? isActive,
    int? totalMembers,
    int? requiredVotes,
    DateTime? createdAt,
    ContentType? contentType,
    List<String>? streamingProviders,
    List<String>? genres,
    String? maxCertification,
    List<String>? excludedGenres,
    DateTime? updatedAt,
    double? minRating,
    int? minYear,
    int? maxYear,
    String? sortBy,
    bool? isChristmasMode,
    bool? allowMemberCollections,
    List<String>? gameTypes,
    List<String>? gameCategories,
    List<String>? gameMechanisms,
    int? minPlayers,
    int? maxPlayers,
    int? minAge,
    double? maxComplexity,
    int? minRank,
  }) {
    return Session(
      id: id ?? this.id,
      hostUserId: hostUserId ?? this.hostUserId,
      isActive: isActive ?? this.isActive,
      totalMembers: totalMembers ?? this.totalMembers,
      requiredVotes: requiredVotes ?? this.requiredVotes,
      createdAt: createdAt ?? this.createdAt,
      contentType: contentType ?? this.contentType,
      streamingProviders: streamingProviders ?? this.streamingProviders,
      genres: genres ?? this.genres,
      maxCertification: maxCertification ?? this.maxCertification,
      excludedGenres: excludedGenres ?? this.excludedGenres,
      updatedAt: updatedAt ?? this.updatedAt,
      minRating: minRating ?? this.minRating,
      minYear: minYear ?? this.minYear,
      maxYear: maxYear ?? this.maxYear,
      sortBy: sortBy ?? this.sortBy,
      isChristmasMode: isChristmasMode ?? this.isChristmasMode,
      allowMemberCollections: allowMemberCollections ?? this.allowMemberCollections,
      gameTypes: gameTypes ?? this.gameTypes,
      gameCategories: gameCategories ?? this.gameCategories,
      gameMechanisms: gameMechanisms ?? this.gameMechanisms,
      minPlayers: minPlayers ?? this.minPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      minAge: minAge ?? this.minAge,
      maxComplexity: maxComplexity ?? this.maxComplexity,
      minRank: minRank ?? this.minRank,
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
