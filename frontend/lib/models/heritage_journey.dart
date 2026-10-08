import 'package:latlong2/latlong.dart';

class HeritageStop {
  const HeritageStop(this.name, this.point, this.description);
  final String name;
  final LatLng point;
  final String description;
  Map<String, dynamic> toJson() => {'name': name, 'latitude': point.latitude,
    'longitude': point.longitude, 'description': description};
  factory HeritageStop.fromJson(Map<String, dynamic> json) {
    final lat = double.tryParse('${json['latitude']}');
    final lon = double.tryParse('${json['longitude']}');
    if (lat == null || lon == null || !lat.isFinite || !lon.isFinite || lat.abs() > 90 || lon.abs() > 180) {
      throw const FormatException('This place has no valid map coordinates.');
    }
    return HeritageStop('${json['name'] ?? 'Heritage stop'}', LatLng(lat, lon),
      '${json['description'] ?? 'Explore this heritage destination.'}');
  }
}

const coastalHeritageStops = [
  HeritageStop('Colombo Fort', LatLng(6.9344, 79.8428), 'Begin your coastal heritage journey in Colombo Fort.'),
  HeritageStop('Kalutara Bodhiya', LatLng(6.5854, 79.9607), 'Discover the sacred Bodhi tree and riverside temple.'),
  HeritageStop('Richmond Castle', LatLng(6.6068, 79.9762), 'Explore the historic mansion and its landscaped gardens.'),
  HeritageStop('Galle Lighthouse', LatLng(6.0248, 80.2185), 'Visit the lighthouse overlooking the Indian Ocean.'),
  HeritageStop('Galle Fort', LatLng(6.0267, 80.2170), 'Walk through the streets and ramparts of Galle Fort.'),
];

class HeritageJourney {
  HeritageJourney({required this.id, required this.name, required this.stops,
    required this.startedAt, this.completed = 0, this.distanceMeters = 0, this.finishedAt});
  final String id;
  String name;
  final List<HeritageStop> stops;
  final DateTime startedAt;
  int completed;
  double distanceMeters;
  DateTime? finishedAt;
  double get progress => stops.isEmpty ? 0 : completed / stops.length;
  bool get isComplete => stops.isNotEmpty && completed == stops.length;
  Duration get elapsed => (finishedAt ?? DateTime.now()).difference(startedAt);
  void completeStop() {
    if (isComplete || stops.isEmpty) return;
    completed++;
    if (isComplete) finishedAt = DateTime.now();
  }
  void undoStop() {
    if (completed == 0) return;
    completed--;
    finishedAt = null;
  }
  Map<String, dynamic> toJson() => {'id': id, 'name': name,
    'stops': stops.map((s) => s.toJson()).toList(), 'startedAt': startedAt.toIso8601String(),
    'completed': completed, 'distanceMeters': distanceMeters, 'finishedAt': finishedAt?.toIso8601String()};
  factory HeritageJourney.fromJson(Map<String, dynamic> json) {
    final stops = (json['stops'] as List).map((s) => HeritageStop.fromJson(Map<String, dynamic>.from(s as Map))).toList();
    return HeritageJourney(id: json['id'] as String, name: json['name'] as String,
      stops: stops, startedAt: DateTime.parse(json['startedAt'] as String),
      completed: (json['completed'] as int).clamp(0, stops.length),
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      finishedAt: DateTime.tryParse('${json['finishedAt']}'));
  }
}
