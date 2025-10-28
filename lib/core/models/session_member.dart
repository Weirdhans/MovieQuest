/// SessionMember model - Represents a member of a session
///
/// Contains all member information including:
/// - User identification (id, userId, userName)
/// - Session participation (sessionId, joinedAt, isHost)
/// - Activity metrics (swipeCount, likesCount)
///
/// The [userName] can be null, in which case [displayName] will generate
/// a fun movie-themed name automatically.
class SessionMember {
  const SessionMember({
    required this.id,
    required this.sessionId,
    required this.userId,
    this.userName,
    required this.joinedAt,
    this.swipeCount = 0,
    this.likesCount = 0,
    this.isHost = false,
  });

  /// Unique identifier for this session member record
  final String id;

  /// The session this member belongs to
  final String sessionId;

  /// The user's unique identifier (UUID)
  final String userId;

  /// Optional user-provided name (can be null)
  final String? userName;

  /// Timestamp when the user joined this session
  final DateTime joinedAt;

  /// Total number of swipes (left + right) made by this member
  final int swipeCount;

  /// Number of right swipes (likes) made by this member
  final int likesCount;

  /// Whether this member is the session host
  final bool isHost;

  /// Create SessionMember from Supabase JSON
  factory SessionMember.fromJson(Map<String, dynamic> json) {
    // Handle different field name formats (snake_case from DB)
    final id = json['id'] as String?;
    final sessionId = json['session_id'] as String?;
    final userId = json['user_id'] as String?;
    final userName = json['user_name'] as String?;
    final joinedAtStr = json['joined_at'] as String?;
    final swipeCount = json['swipe_count'];
    final likesCount = json['likes_count'];
    final isHost = json['is_host'] as bool?;

    if (id == null || sessionId == null || userId == null) {
      throw FormatException(
        'Missing required fields in SessionMember.fromJson: id=$id, sessionId=$sessionId, userId=$userId. Full JSON: $json',
      );
    }

    return SessionMember(
      id: id,
      sessionId: sessionId,
      userId: userId,
      userName: userName,
      joinedAt: joinedAtStr != null ? DateTime.parse(joinedAtStr) : DateTime.now(),
      swipeCount: swipeCount is int ? swipeCount : int.tryParse(swipeCount.toString()) ?? 0,
      likesCount: likesCount is int ? likesCount : int.tryParse(likesCount.toString()) ?? 0,
      isHost: isHost ?? false,
    );
  }

  /// Convert SessionMember to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'user_name': userName,
      'joined_at': joinedAt.toIso8601String(),
      'swipe_count': swipeCount,
      'likes_count': likesCount,
      'is_host': isHost,
    };
  }

  /// Get display name (userName or fun random fallback)
  ///
  /// Returns the user's provided name if available, otherwise generates
  /// a fun movie-themed name based on their user ID (deterministic).
  String get displayName {
    if (userName != null && userName!.isNotEmpty) {
      return userName!;
    }
    // Generate a deterministic fun name based on user ID
    return generateFunName(userId);
  }

  /// Generate a fun movie-themed name from user ID
  ///
  /// Creates a deterministic name by combining a movie-related prefix
  /// (e.g., "Popcorn", "Cinema") with a fun suffix (e.g., "Piraat", "Meester").
  /// The same userId always produces the same name.
  ///
  /// Examples: "Popcorn Piraat", "Cinema Meester", "Film Held"
  static String generateFunName(String userId) {
    // Movie-themed prefixes
    const prefixes = [
      'Popcorn', 'Cinema', 'Movie', 'Film', 'Trailer',
      'Blockbuster', 'Oscar', 'Premiere', 'Hollywood', 'Netflix',
      'Bioscoop', 'Ticket', 'Screen', 'Reel', 'Scene',
    ];

    // Fun suffixes
    const suffixes = [
      'Piraat', 'Meester', 'Tovenaar', 'Held', 'Koning',
      'Koningin', 'Ninja', 'Kapitein', 'Legende', 'Expert',
      'Guru', 'Fanaat', 'Liefhebber', 'Junkie', 'Addict',
    ];

    // Use hash of userId for deterministic selection
    final hash = userId.hashCode.abs();
    final prefix = prefixes[hash % prefixes.length];
    final suffix = suffixes[(hash ~/ prefixes.length) % suffixes.length];

    return '$prefix $suffix';
  }

  /// Create a copy with modified fields
  SessionMember copyWith({
    String? id,
    String? sessionId,
    String? userId,
    String? userName,
    DateTime? joinedAt,
    int? swipeCount,
    int? likesCount,
    bool? isHost,
  }) {
    return SessionMember(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      joinedAt: joinedAt ?? this.joinedAt,
      swipeCount: swipeCount ?? this.swipeCount,
      likesCount: likesCount ?? this.likesCount,
      isHost: isHost ?? this.isHost,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SessionMember && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SessionMember(id: $id, userName: $userName, swipeCount: $swipeCount, likesCount: $likesCount, isHost: $isHost)';
  }
}
