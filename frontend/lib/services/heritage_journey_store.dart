import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/heritage_journey.dart';

class HeritageJourneyStore {
  HeritageJourneyStore(this.scope);
  final String scope;
  static const _storage = FlutterSecureStorage();
  String get _key => 'member4_journeys_$scope';
  Future<List<HeritageJourney>> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((j) => HeritageJourney.fromJson(Map<String, dynamic>.from(j as Map))).toList();
  }
  Future<void> save(HeritageJourney journey) async {
    final journeys = await read();
    journeys.removeWhere((j) => j.id == journey.id);
    journeys.insert(0, journey);
    await _write(journeys);
  }
  Future<void> delete(String id) async {
    final journeys = await read();
    journeys.removeWhere((j) => j.id == id);
    await _write(journeys);
  }
  Future<void> _write(List<HeritageJourney> journeys) => _storage.write(
    key: _key, value: jsonEncode(journeys.map((j) => j.toJson()).toList()));
}
