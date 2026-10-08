import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../models/heritage_journey.dart';
import '../../services/api_client.dart';
import '../../services/heritage_journey_store.dart';

const _brown = Color(0xFF9A4F2D);
const _cream = Color(0xFFF8F3ED);
const _soft = Color(0xFFF1E7DC);

enum _Page {
  map,
  location,
  start,
  active,
  navigation,
  progress,
  complete,
  saved,
}

class Member4NavigationScreen extends StatefulWidget {
  const Member4NavigationScreen({
    super.key,
    this.initialTour,
    this.storageScope = 'device',
  });
  final Map<String, dynamic>? initialTour;
  final String storageScope;
  @override
  State<Member4NavigationScreen> createState() =>
      _Member4NavigationScreenState();
}

class _Member4NavigationScreenState extends State<Member4NavigationScreen> {
  _Page _page = _Page.map;
  List<HeritageStop> _stops = List.of(coastalHeritageStops);
  List<HeritageJourney> _saved = [];
  HeritageJourney? _journey;
  late final HeritageJourneyStore _store;
  String _name = 'Colombo Fort → Galle Fort';
  String _search = '';
  String? _error;
  bool _busy = false;
  Position? _position;
  StreamSubscription<Position>? _gps;
  List<LatLng> _route = [];
  List<Map<String, dynamic>> _steps = [];
  double? _meters, _seconds;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _store = HeritageJourneyStore(widget.storageScope);
    _load();
  }

  @override
  void dispose() {
    _gps?.cancel();
    _request++;
    super.dispose();
  }

  void _go(_Page page) => setState(() => _page = page);
  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _saved = await _store.read();
      final tour = widget.initialTour;
      if (tour != null) {
        final raw = (tour['stops'] as List)
            .map((s) => Map<String, dynamic>.from(s as Map))
            .toList();
        raw.sort(
          (a, b) => ((a['stopOrder'] as num?) ?? 0).compareTo(
            (b['stopOrder'] as num?) ?? 0,
          ),
        );
        final stops = <HeritageStop>[];
        for (final stop in raw) {
          final place = await ApiClient.instance
              .get('/api/places/${stop['placeId']}', authenticated: false)
              .timeout(const Duration(seconds: 20));
          stops.add(
            HeritageStop.fromJson(Map<String, dynamic>.from(place as Map)),
          );
        }
        if (stops.isEmpty)
          throw const FormatException('This tour has no stops.');
        _stops = stops;
        _name = '${tour['name'] ?? tour['title'] ?? 'My heritage tour'}';
        _page = _Page.start;
      }
    } catch (e) {
      _error = 'Could not load journey: $e';
      if (widget.initialTour != null) _stops = [];
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (_stops.isNotEmpty && _error == null) await _calculateRoute();
  }

  Future<void> _location() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled())
        throw StateError('Turn on location services and refresh.');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Enable location permission in device settings.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      setState(() => _position = position);
      await _gps?.cancel();
      _gps =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen(
            _updatePosition,
            onError: (Object e) {
              if (mounted)
                setState(
                  () => _error = 'GPS interrupted. Refresh location to retry.',
                );
            },
          );
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _updatePosition(Position next) {
    if (!mounted) return;
    final previous = _position;
    final journey = _journey;
    if (previous != null &&
        journey != null &&
        !journey.isComplete &&
        next.accuracy <= 50 &&
        previous.accuracy <= 50) {
      final meters = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        next.latitude,
        next.longitude,
      );
      final seconds = next.timestamp.difference(previous.timestamp).inSeconds;
      if (seconds > 0 && meters / seconds < 55 && meters >= 5)
        journey.distanceMeters += meters;
    }
    setState(() => _position = next);
  }

  Future<void> _calculateRoute() async {
    if (_stops.isEmpty) return;
    final request = ++_request;
    setState(() {
      _busy = true;
      _error = null;
      _route = [];
      _steps = [];
      _meters = null;
      _seconds = null;
    });
    try {
      final points = <LatLng>[
        if (_position != null && _journey != null)
          LatLng(_position!.latitude, _position!.longitude),
        ..._stops.skip(_journey?.completed ?? 0).map((s) => s.point),
      ];
      if (points.length < 2) {
        _route = points;
        if (_journey != null && !_journey!.isComplete) {
          _error = 'Refresh your location to get directions to the final stop.';
        }
        return;
      }
      final coordinates = points
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');
      final response = await http
          .get(
            Uri.parse(
              'https://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=geojson&steps=true',
            ),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200)
        throw const FormatException('Routing service unavailable.');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok')
        throw const FormatException('No road route available.');
      final route = (data['routes'] as List).first as Map<String, dynamic>;
      if (!mounted || request != _request) return;
      _route = ((route['geometry'] as Map)['coordinates'] as List)
          .map(
            (p) => LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble()),
          )
          .toList();
      _steps = (route['legs'] as List)
          .expand((leg) => leg['steps'] as List)
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();
      _meters = (route['distance'] as num).toDouble();
      _seconds = (route['duration'] as num).toDouble();
    } catch (_) {
      if (mounted && request == _request)
        _error =
            'Directions unavailable. Check your connection and recalculate.';
    } finally {
      if (mounted && request == _request) setState(() => _busy = false);
    }
  }

  Future<void> _begin() async {
    if (_stops.isEmpty || _busy) return;
    setState(() => _busy = true);
    final now = DateTime.now();
    final journey = HeritageJourney(
      id: '${now.microsecondsSinceEpoch}',
      name: _name,
      stops: List.of(_stops),
      startedAt: now,
    );
    try {
      await _store.save(journey);
      if (mounted)
        setState(() {
          _journey = journey;
          _page = _Page.active;
        });
    } catch (_) {
      _message('Could not save your tour. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkpoint({bool undo = false}) async {
    final journey = _journey;
    if (journey == null || _busy) return;
    setState(() => _busy = true);
    final previous = journey.completed;
    final finished = journey.finishedAt;
    if (undo) {
      journey.undoStop();
    } else {
      journey.completeStop();
    }
    try {
      await _store.save(journey);
      if (!mounted) return;
      setState(
        () => _page = journey.isComplete ? _Page.complete : _Page.active,
      );
      if (!journey.isComplete) await _calculateRoute();
    } catch (_) {
      journey.completed = previous;
      journey.finishedAt = finished;
      _message('Checkpoint not saved. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _savedJourneys() async {
    try {
      final saved = await _store.read();
      if (mounted)
        setState(() {
          _saved = saved;
          _page = _Page.saved;
        });
    } catch (_) {
      _message('Could not read saved journeys.');
    }
  }

  Future<void> _rename(HeritageJourney journey) async {
    var name = journey.name;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename journey'),
        content: TextFormField(
          initialValue: name,
          maxLength: 80,
          onChanged: (v) => name = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (name.trim().isNotEmpty) Navigator.pop(context, name.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final old = journey.name;
    journey.name = result;
    try {
      await _store.save(journey);
      await _savedJourneys();
    } catch (_) {
      journey.name = old;
      _message('Could not rename journey.');
    }
  }

  Future<void> _delete(HeritageJourney journey) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete saved journey?'),
        content: Text(journey.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _store.delete(journey.id);
      await _savedJourneys();
    } catch (_) {
      _message('Could not delete journey.');
    }
  }

  Widget _card(List<Widget> children, {Color color = Colors.white}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEADFD5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );
  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: Color(0xFF3A241B),
      ),
    ),
  );
  Widget _button(String label, VoidCallback action, {bool secondary = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SizedBox(
          width: double.infinity,
          child: secondary
              ? OutlinedButton(
                  onPressed: _busy ? null : action,
                  child: Text(label),
                )
              : FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _brown,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: _busy ? null : action,
                  child: Text(label),
                ),
        ),
      );
  Widget _metric(String label, String value) => Expanded(
    child: Container(
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.brown),
          ),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
  Widget _map({double height = 280}) {
    if (_stops.isEmpty)
      return _card([const Text('No valid destinations available.')]);
    final points = [
      ..._stops.map((s) => s.point),
      ..._route,
      if (_position != null) LatLng(_position!.latitude, _position!.longitude),
    ];
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
      child: FlutterMap(
        key: ValueKey('${_page.name}_${_route.length}_${_journey?.completed}'),
        options: MapOptions(
          initialCenter: points.first,
          initialZoom: 13,
          initialCameraFit: points.length > 1
              ? CameraFit.bounds(
                  bounds: LatLngBounds.fromPoints(points),
                  padding: const EdgeInsets.all(32),
                  maxZoom: 16,
                )
              : null,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.ceylonheritage.frontend',
          ),
          if (_route.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(points: _route, color: _brown, strokeWidth: 4),
              ],
            ),
          MarkerLayer(
            markers: [
              for (var i = 0; i < _stops.length; i++)
                Marker(
                  point: _stops[i].point,
                  width: 34,
                  height: 34,
                  child: Tooltip(
                    message: _stops[i].name,
                    child: CircleAvatar(
                      backgroundColor: _brown,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              if (_position != null)
                Marker(
                  point: LatLng(_position!.latitude, _position!.longitude),
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
            ],
          ),
          const SimpleAttributionWidget(
            source: Text('© OpenStreetMap contributors'),
          ),
        ],
      ),
    );
  }

  List<Widget> _metrics() => [
    Row(
      children: [
        _metric(
          'Road distance',
          _meters == null
              ? 'Unavailable'
              : '${(_meters! / 1000).toStringAsFixed(1)} km',
        ),
        _metric(
          'Driving estimate',
          _seconds == null ? 'Unavailable' : '${(_seconds! / 60).ceil()} min',
        ),
      ],
    ),
    const SizedBox(height: 8),
    const Text(
      'Driving estimates exclude time spent visiting places.',
      style: TextStyle(fontSize: 11, color: Colors.brown),
    ),
  ];
  List<Widget> _body() {
    final journey = _journey;
    switch (_page) {
      case _Page.map:
        return [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search route stops',
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 16),
          _map(),
          _card([_heading(_name), ..._metrics()]),
          for (final stop in _stops.where(
            (s) => s.name.toLowerCase().contains(_search.toLowerCase()),
          ))
            _card([_heading(stop.name), Text(stop.description)]),
          if (_stops.isNotEmpty) _button('Start Tour', () => _go(_Page.start)),
          _button(
            'Current Location',
            () => _go(_Page.location),
            secondary: true,
          ),
        ];
      case _Page.location:
        return [
          _map(),
          _card([
            _heading(_position == null ? 'GPS not connected' : 'GPS active'),
            if (_position != null) ...[
              Text('Latitude   ${_position!.latitude.toStringAsFixed(6)}'),
              Text('Longitude   ${_position!.longitude.toStringAsFixed(6)}'),
              Text('Accuracy   ±${_position!.accuracy.toStringAsFixed(0)} m'),
              Text('Updated   ${_position!.timestamp.toLocal()}'),
            ] else
              const Text('Allow location access to see your actual position.'),
          ]),
          _button('Refresh Location', _location),
          _button('Location Settings', () async {
            await Geolocator.openLocationSettings();
          }, secondary: true),
          _button('Permission Settings', () async {
            await Geolocator.openAppSettings();
          }, secondary: true),
        ];
      case _Page.start:
        return [
          _card([
            _heading(_name),
            const Text('Review your heritage route before you begin.'),
            const SizedBox(height: 12),
            ..._metrics(),
          ]),
          _map(height: 220),
          _heading('Places to visit'),
          for (var i = 0; i < _stops.length; i++)
            _card([Text('${i + 1}. ${_stops[i].name}')]),
          if (_stops.isNotEmpty) _button('Begin Tour', _begin),
        ];
      case _Page.active:
        if (journey == null)
          return [const Text('Start or resume a journey first.')];
        if (journey.isComplete) return _completion(journey);
        final i = journey.completed;
        return [
          _card([
            Text(
              'CURRENT STOP   ${i + 1} of ${_stops.length}',
              style: const TextStyle(color: _brown),
            ),
            const SizedBox(height: 10),
            _heading(_stops[i].name),
            Text(_stops[i].description),
          ]),
          _map(),
          if (i + 1 < _stops.length)
            _card([const Text('NEXT STOP'), _heading(_stops[i + 1].name)]),
          _button('View Directions', () {
            _go(_Page.navigation);
            _calculateRoute();
          }),
          _button('Mark Stop Visited', _checkpoint),
          _button('Tour Progress', () => _go(_Page.progress), secondary: true),
          _button(
            'Current Location',
            () => _go(_Page.location),
            secondary: true,
          ),
        ];
      case _Page.navigation:
        return [
          _card([
            _heading('Road directions'),
            const Text('Driving route • refresh GPS before recalculating.'),
          ]),
          _map(height: 320),
          _card(_metrics()),
          for (final step in _steps)
            _card([
              Text(
                _instruction(step),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${((step['distance'] as num) / 1000).toStringAsFixed(2)} km',
              ),
            ]),
          _button('Recalculate Route', _calculateRoute),
          _button('Refresh Location', _location, secondary: true),
          if (journey != null)
            _button(
              'Back to Active Tour',
              () => _go(_Page.active),
              secondary: true,
            ),
        ];
      case _Page.progress:
        if (journey == null)
          return [const Text('Start or resume a journey first.')];
        return [
          _card([
            const Text('Journey completed'),
            _heading('${(journey.progress * 100).round()}%'),
            LinearProgressIndicator(
              value: journey.progress,
              color: _brown,
              backgroundColor: _soft,
            ),
            const SizedBox(height: 12),
            Text(
              '${journey.completed} of ${_stops.length} destinations visited',
            ),
          ]),
          _card([
            _heading('Destination checkpoints'),
            for (var i = 0; i < _stops.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  i < journey.completed
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: i <= journey.completed ? _brown : Colors.grey,
                ),
                title: Text(_stops[i].name),
                subtitle: Text(
                  i < journey.completed
                      ? 'Completed'
                      : i == journey.completed
                      ? 'Current stop'
                      : 'Upcoming',
                ),
              ),
          ]),
          if (journey.completed > 0)
            _button(
              'Undo Last Checkpoint',
              () => _checkpoint(undo: true),
              secondary: true,
            ),
          _button(
            journey.isComplete ? 'View Summary' : 'Continue Tour',
            () => _go(journey.isComplete ? _Page.complete : _Page.active),
          ),
        ];
      case _Page.complete:
        return journey == null
            ? [const Text('No completed journey selected.')]
            : _completion(journey);
      case _Page.saved:
        return [
          if (_saved.isEmpty)
            _card([
              _heading('Your journeys will appear here'),
              const Text('Begin a tour to save your progress.'),
            ]),
          for (final saved in _saved)
            _card([
              _heading(saved.name),
              Text(
                '${saved.completed}/${saved.stops.length} places • ${saved.isComplete ? 'Completed' : 'In progress'}',
              ),
              const SizedBox(height: 10),
              _button(saved.isComplete ? 'View Summary' : 'Resume Tour', () {
                setState(() {
                  _journey = saved;
                  _stops = List.of(saved.stops);
                  _name = saved.name;
                  _page = saved.isComplete ? _Page.complete : _Page.active;
                });
                if (!saved.isComplete) _calculateRoute();
              }),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _rename(saved),
                    child: const Text('Rename'),
                  ),
                  TextButton(
                    onPressed: () => _delete(saved),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ]),
        ];
    }
  }

  String _instruction(Map<String, dynamic> step) {
    final maneuver = step['maneuver'] as Map;
    final type = '${maneuver['type']}'.replaceAll('_', ' ');
    final road = '${step['name'] ?? ''}';
    final words = [
      type,
      '${maneuver['modifier'] ?? ''}',
      if (road.isNotEmpty) 'on $road',
    ].where((word) => word.isNotEmpty).join(' ');
    return words.isEmpty
        ? 'Continue along the route'
        : '${words[0].toUpperCase()}${words.substring(1)}';
  }

  List<Widget> _completion(HeritageJourney journey) => [
    _card([
      const Center(
        child: Icon(Icons.workspace_premium_outlined, size: 54, color: _brown),
      ),
      const SizedBox(height: 14),
      _heading('You reached ${journey.stops.last.name}'),
      const Text('All heritage checkpoints completed.'),
    ], color: _soft),
    _card([
      _heading('Tour summary'),
      Row(
        children: [
          _metric('Places visited', '${journey.completed}'),
          _metric(
            'GPS distance',
            '${(journey.distanceMeters / 1000).toStringAsFixed(1)} km',
          ),
        ],
      ),
      Row(
        children: [
          _metric('Tour duration', '${journey.elapsed.inMinutes} min'),
          _metric('Completion', '${(journey.progress * 100).round()}%'),
        ],
      ),
      const SizedBox(height: 8),
      const Text(
        'Distance records movement while GPS is active in this screen.',
        style: TextStyle(fontSize: 11),
      ),
    ]),
    _heading('Badges earned'),
    _card([
      const Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          Chip(
            avatar: Icon(Icons.account_balance_outlined),
            label: Text('History Explorer'),
          ),
          Chip(
            avatar: Icon(Icons.flag_outlined),
            label: Text('Route Finisher'),
          ),
        ],
      ),
    ]),
    _button('Save Summary', () async {
      try {
        await _store.save(journey);
        _message('Summary saved on this device.');
      } catch (_) {
        _message('Could not save summary.');
      }
    }),
    _button('Copy Tour Summary', () async {
      await Clipboard.setData(
        ClipboardData(
          text:
              '${journey.name}\n${journey.completed} places visited\n${(journey.distanceMeters / 1000).toStringAsFixed(1)} km recorded\n${journey.elapsed.inMinutes} minutes',
        ),
      );
      _message('Summary copied. Paste it into your preferred app.');
    }, secondary: true),
    _button('View Progress', () => _go(_Page.progress), secondary: true),
  ];
  @override
  Widget build(BuildContext context) {
    const titles = [
      'HeritageGuide',
      'Current Location',
      'Start Tour',
      'Active Tour',
      'Navigation',
      'Tour Progress',
      'Tour Complete!',
      'Saved Journeys',
    ];
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        foregroundColor: _brown,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_busy) return;
            if (_page == _Page.map) {
              if (Navigator.canPop(context)) Navigator.pop(context);
            } else {
              _go(
                _journey != null &&
                        !_journey!.isComplete &&
                        _page != _Page.active
                    ? _Page.active
                    : _Page.map,
              );
            }
          },
        ),
        title: Text(
          titles[_page.index],
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Saved journeys',
            onPressed: _busy ? null : _savedJourneys,
            icon: const Icon(Icons.bookmark_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(color: _brown),
                  ),
                if (_error != null)
                  _card([
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    TextButton(
                      onPressed: _busy ? null : _calculateRoute,
                      child: const Text('Retry directions'),
                    ),
                  ]),
                ..._body(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: _soft,
        selectedIndex: _page == _Page.saved
            ? 2
            : (_page == _Page.map || _page == _Page.location)
            ? 0
            : 1,
        onDestinationSelected: _busy
            ? null
            : (i) {
                if (i == 0) _go(_Page.map);
                if (i == 1)
                  _go(
                    _journey == null
                        ? _Page.start
                        : _journey!.isComplete
                        ? _Page.complete
                        : _Page.active,
                  );
                if (i == 2) _savedJourneys();
              },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.route), label: 'Tours'),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            label: 'Saved',
          ),
        ],
      ),
    );
  }
}
