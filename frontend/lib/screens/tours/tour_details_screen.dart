import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/api_config.dart';
import '../../services/api_client.dart';
import 'create_tour_screen.dart';
import '../navigation/member4_navigation_screen.dart';

const _detailsPrimary = Color(0xFF9A4F2D);
const _detailsBackground = Color(0xFFF8F3ED);
const _detailsHeading = Color(0xFF3A241B);
const _detailsMuted = Color(0xFF6F6A66);
const _detailsSurface = Color(0xFFF1E7DC);
const _detailsBorder = Color(0xFFEADFD5);

class TourDetailsScreen extends StatefulWidget {
  const TourDetailsScreen({
    super.key,
    required this.tourId,
    required this.onHome,
    required this.onExplore,
    required this.onCommunity,
    required this.onProfile,
    this.initialTour,
    this.onSignIn,
    this.onPlaceSelected,
    this.onUpdated,
    this.onStartTour,
  });

  final int tourId;
  final Map<String, dynamic>? initialTour;

  final VoidCallback onHome;
  final VoidCallback onExplore;
  final VoidCallback onCommunity;
  final VoidCallback onProfile;
  final VoidCallback? onSignIn;

  final ValueChanged<int>? onPlaceSelected;
  final ValueChanged<Map<String, dynamic>>? onUpdated;

  /// Connect this when the Active Tour screen is available.
  final Future<void> Function(Map<String, dynamic> tour)? onStartTour;

  @override
  State<TourDetailsScreen> createState() => _TourDetailsScreenState();
}

class _TourDetailsScreenState extends State<TourDetailsScreen> {
  Map<String, dynamic>? _tour;

  bool _loading = true;
  bool _editing = false;
  bool _starting = false;

  String? _error;
  int _requestId = 0;

  bool get _busy => _loading || _editing || _starting;

  @override
  void initState() {
    super.initState();

    final initial = widget.initialTour;

    if (initial != null &&
        _detailInteger(initial['id']) == widget.tourId) {
      _tour = Map<String, dynamic>.from(initial);
      _loading = false;
    } else {
      _load();
    }
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text)),
      );
  }

  String _errorText(Object error) {
    if (error is TimeoutException) {
      return 'The request timed out. Please try again.';
    }

    if (error is ApiException) {
      switch (error.statusCode) {
        case 401:
          return 'Please sign in to view your tour.';
        case 403:
          return 'You do not have permission to view this tour.';
        case 404:
          return 'This tour could not be found.';
        default:
          return error.message;
      }
    }

    if (error is FormatException) {
      return 'The backend returned an unexpected tour response.';
    }

    return 'Could not load this tour. Check your backend connection.';
  }

  Future<void> _load() async {
    if (!mounted || _editing || _starting) return;

    final requestId = ++_requestId;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (widget.tourId <= 0) {
        throw const FormatException('Invalid tour ID');
      }

      final response = await ApiClient.instance
          .get('/api/tours/${widget.tourId}')
          .timeout(const Duration(seconds: 25));

      if (response is! Map) {
        throw const FormatException('Invalid tour response');
      }

      final tour = Map<String, dynamic>.from(response);

      if (_detailInteger(tour['id']) != widget.tourId) {
        throw const FormatException('Unexpected tour ID');
      }

      if (!mounted || requestId != _requestId) return;

      setState(() {
        _tour = tour;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;

      setState(() {
        _loading = false;
        _error = _errorText(error);
      });
    }
  }

  List<_DetailStop> get _stops {
    final raw = _tour?['stops'];
    final stops = <_DetailStop>[];

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          stops.add(
            _DetailStop.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    stops.sort((a, b) => a.order.compareTo(b.order));
    return stops;
  }

  void _back() {
    if (_editing || _starting) return;

    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop();
    } else {
      widget.onHome();
    }
  }

  Future<void> _editTour() async {
    if (_busy || _tour == null) return;

    setState(() => _editing = true);

    try {
      final saved = await Navigator.of(context)
          .push<Map<String, dynamic>>(
        MaterialPageRoute<Map<String, dynamic>>(
          builder: (editorContext) {
            return CreateTourScreen(
              tourId: widget.tourId,
              onHome: widget.onHome,
              onExplore: widget.onExplore,
              onCommunity: widget.onCommunity,
              onProfile: widget.onProfile,
              onSignIn: widget.onSignIn,
              onSaved: (updatedTour) async {
                // Wait until the editor's saved state has rebuilt.
                await WidgetsBinding.instance.endOfFrame;

                if (!editorContext.mounted) return;

                Navigator.of(editorContext).pop(updatedTour);
              },
            );
          },
        ),
      );

      if (!mounted || saved == null) return;

      setState(() {
        _tour = Map<String, dynamic>.from(saved);
        _error = null;
      });

      widget.onUpdated?.call(saved);
    } catch (error) {
      _message(_errorText(error));
    } finally {
      if (mounted) {
        setState(() => _editing = false);
      }
    }
  }

  void _openPlace(_DetailStop stop) {
    if (_busy) return;

    if (stop.placeId <= 0) {
      _message('This place does not have a valid ID.');
      return;
    }

    final callback = widget.onPlaceSelected;

    if (callback == null) {
      _message('Place Details navigation has not been connected.');
      return;
    }

    callback(stop.placeId);
  }

  Future<void> _startTour() async {
    if (_busy || _tour == null) return;

    if (_stops.isEmpty) {
      _message('This tour does not contain any places.');
      return;
    }

    final callback = widget.onStartTour;

    if (callback == null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => Member4NavigationScreen(initialTour: _tour)),
      );
      return;
    }

    final tour = Map<String, dynamic>.from(_tour ?? {});

    setState(() => _starting = true);

    try {
      await callback(tour);
    } catch (error) {
      _message(_errorText(error));
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  TextStyle _titleStyle(double size) {
    return GoogleFonts.playfairDisplay(
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: _detailsHeading,
    );
  }

  Widget _panel({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _detailsBorder),
      ),
      child: child,
    );
  }

  String _distanceText() {
    final distance = _detailDecimal(_tour?['totalDistanceKm']);

    if (distance == null || !distance.isFinite || distance < 0) {
      return 'Unavailable';
    }

    return '${distance.toStringAsFixed(2)} km';
  }

  String _durationText() {
    final minutes = _detailInteger(
      _tour?['estimatedDurationMinutes'],
    );

    if (minutes == null || minutes < 0) {
      return 'Unavailable';
    }

    return _formatDetailMinutes(minutes);
  }

  String _calculationNote() {
    final notes = <String>[];

    final distanceMethod =
        _tour?['distanceCalculationMethod']?.toString().trim() ?? '';

    final durationMethod =
        _tour?['durationCalculationMethod']?.toString().trim() ?? '';

    if (distanceMethod.isNotEmpty) {
      final normalized = distanceMethod.toUpperCase();

      if (normalized.contains('HAVERSINE') ||
          normalized.contains('STRAIGHT')) {
        notes.add('Straight-line distance');
      } else if (normalized.contains('ROAD') ||
          normalized.contains('ROUTING') ||
          normalized.contains('OSRM')) {
        notes.add('Route distance');
      } else {
        notes.add(
          'Distance: ${_readableDetailMethod(distanceMethod)}',
        );
      }
    }

    final estimated = _detailInteger(
      _tour?['estimatedDurationMinutes'],
    );

    final travel = _detailInteger(
      _tour?['travelDurationMinutes'],
    );

    final visits = _detailInteger(
      _tour?['totalVisitDurationMinutes'],
    );

    if (estimated != null && travel != null && visits != null) {
      notes.add('Includes travel and planned visits');
    } else if (durationMethod.isNotEmpty) {
      notes.add(
        'Duration: ${_readableDetailMethod(durationMethod)}',
      );
    }

    return notes.join(' • ');
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return _panel(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _detailsSurface,
            child: Icon(
              icon,
              size: 21,
              color: _detailsPrimary,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: _detailsMuted,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            style: _titleStyle(16),
          ),
        ],
      ),
    );
  }

  Widget _tourNameCard(List<_DetailStop> stops) {
    final name = _tour?['name']?.toString().trim() ?? '';

    return _panel(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              width: 72,
              height: 58,
              child: stops.isEmpty
                  ? const _DetailImagePlaceholder()
                  : _DetailPlaceImage(stop: stops.first),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name.isEmpty ? 'Heritage Tour' : name,
              style: _titleStyle(18),
            ),
          ),
          IconButton(
            tooltip: 'Edit tour',
            onPressed: _busy ? null : _editTour,
            icon: const Icon(
              Icons.edit_outlined,
              color: _detailsPrimary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stopCard(_DetailStop stop, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: _panel(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: _detailsSurface,
              child: Text(
                '${index + 1}',
                style: _titleStyle(16),
              ),
            ),
            const SizedBox(width: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 76,
                height: 66,
                child: _DetailPlaceImage(stop: stop),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.name,
                    style: _titleStyle(15),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: _detailsPrimary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          stop.city.isEmpty ? 'Sri Lanka' : stop.city,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _detailsMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: _detailsPrimary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          stop.durationLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            color: _detailsMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Change the order through the existing tour editor.
            IconButton(
              tooltip: 'Edit visit order',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 40,
              ),
              onPressed: _busy ? null : _editTour,
              icon: const Icon(
                Icons.drag_indicator,
                size: 20,
                color: _detailsMuted,
              ),
            ),
            IconButton(
              tooltip: 'View place details',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 40,
              ),
              onPressed: _busy ? null : () => _openPlace(stop),
              icon: const Icon(
                Icons.chevron_right,
                color: _detailsHeading,
                size: 23,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeline(List<_DetailStop> stops) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tour Stops',
            style: _titleStyle(22),
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < stops.length; index++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 36,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: _detailsPrimary,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (index < stops.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: _detailsPrimary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 17),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stops[index].name,
                            style: _titleStyle(17),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stops[index].durationLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _detailsMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(color: _detailsBorder),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 17,
                color: _detailsPrimary,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Stops follow your selected order',
                  style: TextStyle(
                    fontSize: 11,
                    color: _detailsMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _busy ? null : _editTour,
            style: OutlinedButton.styleFrom(
              foregroundColor: _detailsPrimary,
              side: const BorderSide(color: _detailsPrimary),
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit_outlined, size: 19),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Edit Tour',
                    style: _titleStyle(16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: _busy ? null : _startTour,
            style: FilledButton.styleFrom(
              backgroundColor: _detailsPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: _starting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'Start Tour',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 19),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _content() {
    final stops = _stops;
    final note = _calculationNote();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        Text(
          'Tour Details',
          style: _titleStyle(32),
        ),
        const SizedBox(height: 5),
        const Text(
          'Review your tour before you start',
          style: TextStyle(
            fontSize: 13,
            color: _detailsMuted,
          ),
        ),
        const SizedBox(height: 19),
        _tourNameCard(stops),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.location_on,
                label: 'Approx. Distance',
                value: _distanceText(),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _statCard(
                icon: Icons.access_time,
                label: 'Estimated Duration',
                value: _durationText(),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _statCard(
                icon: Icons.account_balance,
                label: 'Total Places',
                value: '${stops.length} '
                    '${stops.length == 1 ? 'place' : 'places'}',
              ),
            ),
          ],
        ),
        if (note.isNotEmpty) ...[
          const SizedBox(height: 9),
          Text(
            note,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: _detailsMuted,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Places in this Tour ',
                style: _titleStyle(21),
              ),
              TextSpan(
                text: '(${stops.length} places)',
                style: const TextStyle(
                  fontSize: 12,
                  color: _detailsMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (stops.isEmpty)
          _panel(
            child: const Text(
              'This tour does not contain any places.',
              style: TextStyle(color: _detailsMuted),
            ),
          )
        else ...[
          for (var index = 0; index < stops.length; index++)
            _stopCard(stops[index], index),
          const SizedBox(height: 5),
          _timeline(stops),
        ],
        const SizedBox(height: 16),
        _actionButtons(),
      ],
    );
  }

  Widget _errorBody(String error) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: _detailsMuted,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _load,
              style: FilledButton.styleFrom(
                backgroundColor: _detailsPrimary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final error = _error;

    return Theme(
      data: baseTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(
          baseTheme.textTheme,
        ).apply(
          bodyColor: _detailsHeading,
          displayColor: _detailsHeading,
        ),
      ),
      child: Scaffold(
        backgroundColor: _detailsBackground,
        appBar: AppBar(
          backgroundColor: _detailsBackground,
          foregroundColor: _detailsHeading,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: _editing || _starting ? null : _back,
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 19,
            ),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              const Icon(
                Icons.spa,
                color: _detailsPrimary,
                size: 31,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CEYLON HERITAGE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _titleStyle(15),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'EXPLORE · DISCOVER · PRESERVE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 6,
                        letterSpacing: 1,
                        color: _detailsMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh tour',
              onPressed: _busy ? null : _load,
              icon: const Icon(Icons.refresh, size: 20),
            ),
          ],
        ),
        body: _loading
            ? const Center(
          child: CircularProgressIndicator(
            color: _detailsPrimary,
          ),
        )
            : error != null
            ? _errorBody(error)
            : _content(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 2,
          backgroundColor: Colors.white,
          indicatorColor: _detailsSurface,
          onDestinationSelected: _editing || _starting
              ? null
              : (index) {
            switch (index) {
              case 0:
                widget.onHome();
                break;
              case 1:
                widget.onExplore();
                break;
              case 2:
                break;
              case 3:
                widget.onCommunity();
                break;
              case 4:
                widget.onProfile();
                break;
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.search),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline),
              label: 'Tours',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              label: 'Community',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailStop {
  const _DetailStop({
    required this.placeId,
    required this.order,
    required this.name,
    required this.city,
    required this.imageUrl,
    required this.visitDuration,
    required this.visitMinutes,
  });

  final int placeId;
  final int order;
  final String name;
  final String city;
  final String imageUrl;
  final String visitDuration;
  final int? visitMinutes;

  factory _DetailStop.fromJson(Map<String, dynamic> json) {
    return _DetailStop(
      placeId: _detailInteger(json['placeId']) ?? 0,
      order: _detailInteger(json['stopOrder']) ?? 0,
      name: json['placeName']?.toString() ?? 'Historical place',
      city: json['placeCity']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      visitDuration: json['visitDuration']?.toString() ?? '',
      visitMinutes: _detailInteger(json['visitDurationMinutes']),
    );
  }

  String get durationLabel {
    final minutes = visitMinutes;

    if (minutes != null && minutes >= 0) {
      return '${_formatDetailMinutes(minutes)} visit';
    }

    if (visitDuration.trim().isNotEmpty) {
      return visitDuration.trim();
    }

    return 'Visit time not configured';
  }

  String? get asset {
    final key = name.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );

    const images = <String, String>{
      'polonnaruwaancientcity': 'polonnaruwa.png',
      'rankothvehera': 'rankoth_vehera.png',
      'galvihara': 'gal_vihara.png',
      'gallefort': 'galle_fort.png',
      'ruwanwelisaya': 'ruwanwelisaya.png',
      'ruwanwalisaya': 'ruwanwelisaya.png',
      'lankathilakatemple': 'lankathilaka_temple.png',
      'lankatilakatemple': 'lankathilaka_temple.png',
      'parakramasamudraya': 'parakrama_samudraya.png',
      'isurumuniya': 'isurumuniya.png',
      'isurumuniyatemple': 'isurumuniya.png',
      'jethawanaramaya': 'jethawanaramaya.png',
      'jetavanaramaya': 'jethawanaramaya.png',
      'jetawanaramaya': 'jethawanaramaya.png',
      'samadhistatue': 'samadhi_statue.png',
      'samadhibuddhastatue': 'samadhi_statue.png',
      'srimahabodhi': 'sri_maha_bodhi.png',
      'jayasrimahabodhi': 'sri_maha_bodhi.png',
      'thuparamaya': 'thuparamaya.png',
      'thuparamayatemple': 'thuparamaya.png',
      'sigiriya': 'sigiriya.png',
      'sigiriyarockfortress': 'sigiriya.png',
      'templeofthetooth': 'temple_of_the_tooth.png',
      'jaffnafort': 'jaffna_fort.png',
      'mihintale': 'mihintale.png',
    };

    final file = images[key];

    return file == null ? null : 'assets/images/$file';
  }
}

class _DetailImagePlaceholder extends StatelessWidget {
  const _DetailImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _detailsSurface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.account_balance_outlined,
        color: _detailsMuted,
      ),
    );
  }
}

class _DetailPlaceImage extends StatelessWidget {
  const _DetailPlaceImage({required this.stop});

  final _DetailStop stop;

  Widget _networkImage() {
    final raw = stop.imageUrl.trim();

    if (raw.isEmpty) {
      return const _DetailImagePlaceholder();
    }

    if (raw.startsWith('assets/')) {
      return Image.asset(
        raw,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) {
          return const _DetailImagePlaceholder();
        },
      );
    }

    final base = ApiConfig.baseUrl.replaceFirst(
      RegExp(r'/+$'),
      '',
    );

    final uri = Uri.tryParse(raw);

    final url = uri != null && uri.hasScheme
        ? raw
        : '$base/${raw.replaceFirst(RegExp(r'^/+'), '')}';

    final resolved = Uri.tryParse(url);

    if (resolved == null ||
        (resolved.scheme != 'http' && resolved.scheme != 'https')) {
      return const _DetailImagePlaceholder();
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) {
        return const _DetailImagePlaceholder();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final asset = stop.asset;

    if (asset == null) return _networkImage();

    return Image.asset(
      asset,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) => _networkImage(),
    );
  }
}

int? _detailInteger(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value?.toString() ?? '');
}

double? _detailDecimal(dynamic value) {
  if (value is num) return value.toDouble();

  return double.tryParse(value?.toString() ?? '');
}

String _formatDetailMinutes(int minutes) {
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;

  if (hours == 0) return '$remaining min';
  if (remaining == 0) return '$hours hr';

  return '$hours hr $remaining min';
}

String _readableDetailMethod(String value) {
  return value
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .toLowerCase();
}
