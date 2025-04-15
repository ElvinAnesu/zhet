class Profile {
  final String id;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final double rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.rating = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      username: json['username'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      rating: json['rating'] != null ? json['rating'].toDouble() : 0.0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  Profile copyWith({
    String? username,
    String? fullName,
    String? avatarUrl,
    double? rating,
  }) {
    return Profile(
      id: id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
