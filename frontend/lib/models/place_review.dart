class PlaceReview {
  const PlaceReview({
    required this.id,
    required this.authorName,
    required this.authorLabel,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final int id, rating;
  final String authorName, authorLabel, comment, createdAt;

  factory PlaceReview.fromJson(Map<String, dynamic> json) => PlaceReview(
        id: (json['id'] as num?)?.toInt() ?? 0,
        authorName: json['authorName'] as String? ?? 'Visitor',
        authorLabel: json['authorLabel'] as String? ?? 'Visitor',
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        comment: json['comment'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
      );
}

class PlaceRatingSummary {
  const PlaceRatingSummary({
    required this.averageRating,
    required this.reviewCount,
    required this.fiveStars,
    required this.fourStars,
    required this.threeStars,
    required this.twoStars,
    required this.oneStar,
  });

  final double averageRating;
  final int reviewCount, fiveStars, fourStars, threeStars, twoStars, oneStar;

  factory PlaceRatingSummary.fromJson(Map<String, dynamic> json) =>
      PlaceRatingSummary(
        averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
        fiveStars: (json['fiveStars'] as num?)?.toInt() ?? 0,
        fourStars: (json['fourStars'] as num?)?.toInt() ?? 0,
        threeStars: (json['threeStars'] as num?)?.toInt() ?? 0,
        twoStars: (json['twoStars'] as num?)?.toInt() ?? 0,
        oneStar: (json['oneStar'] as num?)?.toInt() ?? 0,
      );

  int countFor(int stars) => switch (stars) {
        5 => fiveStars,
        4 => fourStars,
        3 => threeStars,
        2 => twoStars,
        _ => oneStar,
      };
}
