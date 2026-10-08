class TourPlan {
  const TourPlan({
    required this.title,
    required this.destination,
    required this.preference,
    required this.startingLocation,
    required this.durationDays,
    required this.totalBudget,
    required this.totalEstimatedCost,
    required this.mapsUrl,
    required this.confidenceLabel,
    required this.detectedKeywords,
    required this.notes,
    required this.expenses,
    required this.itinerary,
    required this.places,
  });

  final String title;
  final String destination;
  final String preference;
  final String startingLocation;
  final int durationDays;
  final int totalBudget;
  final int totalEstimatedCost;
  final String mapsUrl;
  final String confidenceLabel;
  final List<String> detectedKeywords;
  final List<String> notes;
  final List<TourPlanExpense> expenses;
  final List<TourPlanDay> itinerary;
  final List<TourPlanPlace> places;

  factory TourPlan.fromJson(Map<String, dynamic> json) {
    return TourPlan(
      title: _text(json['title']),
      destination: _text(json['destination']),
      preference: _text(json['preference']),
      startingLocation: _text(json['startingLocation']),
      durationDays: _integer(json['durationDays']),
      totalBudget: _integer(json['totalBudget']),
      totalEstimatedCost: _integer(json['totalEstimatedCost']),
      mapsUrl: _text(json['mapsUrl']),
      confidenceLabel: _text(json['confidenceLabel']),
      detectedKeywords: _stringList(json['detectedKeywords']),
      notes: _stringList(json['notes']),
      expenses: _mapList(json['expenses'], TourPlanExpense.fromJson),
      itinerary: _mapList(json['itinerary'], TourPlanDay.fromJson),
      places: _mapList(json['places'], TourPlanPlace.fromJson),
    );
  }
}

class TourPlanExpense {
  const TourPlanExpense({required this.name, required this.estimatedCost});

  final String name;
  final int estimatedCost;

  factory TourPlanExpense.fromJson(Map<String, dynamic> json) {
    return TourPlanExpense(
      name: _text(json['name']),
      estimatedCost: _integer(json['estimatedCost']),
    );
  }
}

class TourPlanDay {
  const TourPlanDay({required this.day, required this.activities});

  final int day;
  final List<String> activities;

  factory TourPlanDay.fromJson(Map<String, dynamic> json) {
    return TourPlanDay(
      day: _integer(json['day']),
      activities: _stringList(json['activities']),
    );
  }
}

class TourPlanPlace {
  const TourPlanPlace({
    required this.id,
    required this.name,
    required this.city,
    required this.category,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.climateType,
    required this.travelTags,
    required this.mapsUrl,
  });

  final int id;
  final String name;
  final String city;
  final String category;
  final String imageUrl;
  final double? latitude;
  final double? longitude;
  final String climateType;
  final List<String> travelTags;
  final String mapsUrl;

  factory TourPlanPlace.fromJson(Map<String, dynamic> json) {
    return TourPlanPlace(
      id: _integer(json['id']),
      name: _text(json['name']),
      city: _text(json['city']),
      category: _text(json['category']),
      imageUrl: _text(json['imageUrl']),
      latitude: _double(json['latitude']),
      longitude: _double(json['longitude']),
      climateType: _text(json['climateType']),
      travelTags: _stringList(json['travelTags']),
      mapsUrl: _text(json['mapsUrl']),
    );
  }
}

List<T> _mapList<T>(dynamic value, T Function(Map<String, dynamic>) mapper) {
  if (value is! List) return const [];

  final items = <T>[];

  for (final item in value) {
    if (item is Map) {
      items.add(mapper(Map<String, dynamic>.from(item)));
    }
  }

  return items;
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];

  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}

String _text(dynamic value) {
  return value?.toString().trim() ?? '';
}

int _integer(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
