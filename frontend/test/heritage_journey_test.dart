import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/heritage_journey.dart';

void main() {
  HeritageJourney journey() => HeritageJourney(
    id: 'test',
    name: 'Coastal trail',
    stops: List.of(coastalHeritageStops),
    startedAt: DateTime(2026, 10, 8),
  );
  test('checkpoint completion is bounded and undo reopens the journey', () {
    final j = journey();
    for (var i = 0; i < 8; i++) {
      j.completeStop();
    }
    expect(j.completed, j.stops.length);
    expect(j.progress, 1);
    expect(j.finishedAt, isNotNull);
    j.undoStop();
    expect(j.isComplete, isFalse);
    expect(j.finishedAt, isNull);
    expect(j.completed, 4);
  });
  test('saved journey retains its destinations, progress and distance', () {
    final j = journey()
      ..completeStop()
      ..distanceMeters = 1234;
    final restored = HeritageJourney.fromJson(j.toJson());
    expect(restored.completed, 1);
    expect(restored.distanceMeters, 1234);
    expect(restored.stops.last.name, 'Galle Fort');
    expect(restored.startedAt, j.startedAt);
  });
  test('invalid coordinates are rejected', () {
    expect(
      () => HeritageStop.fromJson({'latitude': 100, 'longitude': 80}),
      throwsFormatException,
    );
    expect(
      () => HeritageStop.fromJson({'latitude': 'NaN', 'longitude': 80}),
      throwsFormatException,
    );
  });
}
