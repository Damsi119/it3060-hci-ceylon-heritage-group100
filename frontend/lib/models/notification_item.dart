class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.read,
    this.readAt,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String message;
  final bool read;
  final DateTime? readAt;
  final DateTime createdAt;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      read: json['read'] as bool? ?? false,
      readAt: json['readAt'] == null ? null : DateTime.tryParse(json['readAt']),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
