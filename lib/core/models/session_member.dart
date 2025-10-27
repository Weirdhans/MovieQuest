/// SessionMember model - Represents a member of a session
class SessionMember {
  final String id;
  final String sessionId;
  final String userId;
  final String? userName;
  final DateTime joinedAt;
  final int swipeCount;
  final bool isHost;

  const SessionMember({
    required this.id,
    required this.sessionId,
    required this.userId,
    this.userName,
    required this.joinedAt,
    this.swipeCount = 0,
    this.isHost = false,
  });

  /// Create SessionMember from Supabase JSON
  factory SessionMember.fromJson(Map<String, dynamic> json) {
    // Handle different field name formats (snake_case from DB)
    final id = json['id'] as String?;
    final sessionId = json['session_id'] as String?;
    final userId = json['user_id'] as String?;
    final userName = json['user_name'] as String?;
    final joinedAtStr = json['joined_at'] as String?;
    final swipeCount = json['swipe_count'];
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
      'is_host': isHost,
    };
  }

  /// Get display name (userName or fallback)
  String get displayName => userName ?? 'Gebruiker ${userId.substring(0, 8)}';

  /// Create a copy with modified fields
  SessionMember copyWith({
    String? id,
    String? sessionId,
    String? userId,
    String? userName,
    DateTime? joinedAt,
    int? swipeCount,
    bool? isHost,
  }) {
    return SessionMember(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      joinedAt: joinedAt ?? this.joinedAt,
      swipeCount: swipeCount ?? this.swipeCount,
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
    return 'SessionMember(id: $id, userName: $userName, swipeCount: $swipeCount, isHost: $isHost)';
  }
}
