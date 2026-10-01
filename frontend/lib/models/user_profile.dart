class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    this.firstName,
    this.lastName,
    this.address,
    required this.role,
    required this.provider,
    required this.emailVerified,
    required this.passwordChangeRequired,
  });

  final int id;
  final String username;
  final String email;
  final String? phone;
  final String? firstName;
  final String? lastName;
  final String? address;
  final String role;
  final String provider;
  final bool emailVerified;
  final bool passwordChangeRequired;

  String get displayName {
    final parts = <String>[];
    for (final part in [firstName, lastName]) {
      final trimmed = part?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        parts.add(trimmed);
      }
    }
    final name = parts.join(' ');
    return name.isEmpty ? username : name;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      address: json['address'] as String?,
      role: json['role'] as String? ?? 'TOURIST',
      provider: json['provider'] as String? ?? 'LOCAL',
      emailVerified: json['emailVerified'] as bool? ?? false,
      passwordChangeRequired: json['passwordChangeRequired'] as bool? ?? false,
    );
  }
}
