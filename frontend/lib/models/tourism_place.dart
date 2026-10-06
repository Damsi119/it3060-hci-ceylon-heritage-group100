class TourismPlace {
  const TourismPlace({
    required this.id,
    required this.slug,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    required this.city,
    required this.province,
    required this.rating,
    required this.reviewCount,
    required this.distanceMeters,
    required this.isOpen,
    this.openingHours,
    this.priceRange,
    this.latitude,
    this.longitude,
    this.imageUrl,
  });

  final int id;
  final String slug, name, category, description, address, city, province;
  final double rating;
  final int reviewCount, distanceMeters;
  final bool isOpen;
  final String? openingHours, priceRange, imageUrl;
  final double? latitude, longitude;

  String get distanceLabel => distanceMeters >= 1000
      ? '${(distanceMeters / 1000).toStringAsFixed(1)} km'
      : '$distanceMeters m';

  factory TourismPlace.fromJson(Map<String, dynamic> json) => TourismPlace(
        id: (json['id'] as num).toInt(),
        slug: json['slug'] as String? ?? '',
        name: json['name'] as String? ?? '',
        category: json['category'] as String? ?? '',
        description: json['description'] as String? ?? '',
        address: json['address'] as String? ?? '',
        city: json['city'] as String? ?? '',
        province: json['province'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
        distanceMeters: (json['distanceMeters'] as num?)?.toInt() ?? 0,
        isOpen: json['open'] as bool? ?? false,
        openingHours: json['openingHours'] as String?,
        priceRange: json['priceRange'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        imageUrl: json['imageUrl'] as String?,
      );
}
