class GuideApplication {
  const GuideApplication({
    required this.id,
    this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.primaryServiceArea,
    required this.languages,
    required this.experience,
    required this.status,
    this.reviewNote,
    this.createdAt,
    this.reviewedAt,
  });

  final int id;
  final int? userId;
  final String name;
  final String email;
  final String phone;
  final String primaryServiceArea;
  final String languages;
  final String experience;
  final String status;
  final String? reviewNote;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  factory GuideApplication.fromJson(Map<String, dynamic> json) {
    return GuideApplication(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      primaryServiceArea: json['primaryServiceArea'] as String? ?? '',
      languages: json['languages'] as String? ?? '',
      experience: json['experience'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      reviewNote: json['reviewNote'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      reviewedAt: DateTime.tryParse(json['reviewedAt'] as String? ?? ''),
    );
  }
}
