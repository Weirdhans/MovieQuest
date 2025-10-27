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
    this.updatedAt,
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
  final DateTime? updatedAt;

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
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
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
      'updated_at': updatedAt?.toIso8601String(),
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
    DateTime? updatedAt,
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
      updatedAt: updatedAt ?? this.updatedAt,
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
