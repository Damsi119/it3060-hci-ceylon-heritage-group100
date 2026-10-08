import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/heritage_journey.dart';
import 'package:frontend/services/heritage_journey_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'create, read, update and delete a journey without duplicating it',
    () async {
      final store = HeritageJourneyStore('test-account');
      final journey = HeritageJourney(
        id: 'journey-1',
        name: 'Coastal trail',
        stops: List.of(coastalHeritageStops),
        startedAt: DateTime(2026, 10, 8),
      );
      expect(await store.read(), isEmpty);
      await store.save(journey);
      expect((await store.read()).single.name, 'Coastal trail');
      journey.name = 'Renamed trail';
      journey.completeStop();
      await store.save(journey);
      final saved = await store.read();
      expect(saved, hasLength(1));
      expect(saved.single.name, 'Renamed trail');
      expect(saved.single.completed, 1);
      await store.delete(journey.id);
      expect(await store.read(), isEmpty);
    },
  );
  test('account scopes do not share saved journeys', () async {
    final journey = HeritageJourney(
      id: 'journey-1',
      name: 'My trail',
      stops: List.of(coastalHeritageStops),
      startedAt: DateTime(2026, 10, 8),
    );
    await HeritageJourneyStore('account-a').save(journey);
    expect(await HeritageJourneyStore('account-b').read(), isEmpty);
    expect(await HeritageJourneyStore('account-a').read(), hasLength(1));
  });
}
