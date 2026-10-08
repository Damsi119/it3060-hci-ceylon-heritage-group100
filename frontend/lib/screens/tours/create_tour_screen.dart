import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/api_config.dart';
import '../../services/api_client.dart';
import '../../services/token_store.dart';

const _tourPrimary = Color(0xFF9A4F2D);
const _tourBackground = Color(0xFFF8F3ED);
const _tourHeading = Color(0xFF3A241B);
const _tourMuted = Color(0xFF6F6A66);
const _tourSurface = Color(0xFFF1E7DC);
const _tourBorder = Color(0xFFEADFD5);

enum _TourLeaveAction { discard, save }

ThemeData _tourTheme(BuildContext context) {
  final theme = Theme.of(context);

  return theme.copyWith(
    textTheme: GoogleFonts.interTextTheme(theme.textTheme).apply(
      bodyColor: _tourHeading,
      displayColor: _tourHeading,
    ),
    scaffoldBackgroundColor: _tourBackground,
  );
}

TextStyle _tourTitleStyle(double size) {
  return GoogleFonts.playfairDisplay(
    fontSize: size,
    fontWeight: FontWeight.bold,
    color: _tourHeading,
  );
}

class CreateTourScreen extends StatefulWidget {
  const CreateTourScreen({
    super.key,
    required this.onHome,
    required this.onExplore,
    required this.onCommunity,
    required this.onProfile,
    this.onSignIn,
    this.onSaved,
    this.tourId,
    this.initialPlaces = const [],
  });

  final VoidCallback onHome;
  final VoidCallback onExplore;
  final VoidCallback onCommunity;
  final VoidCallback onProfile;
  final VoidCallback? onSignIn;
  final ValueChanged<Map<String, dynamic>>? onSaved;

  /// Provide an existing tour ID to open edit mode.
  final int? tourId;

  /// Places selected from Explore or Historical Place Details.
  final List<Map<String, dynamic>> initialPlaces;

  @override
  State<CreateTourScreen> createState() => _CreateTourScreenState();
}

class _CreateTourScreenState extends State<CreateTourScreen> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

  List<_TourPlace> _places = [];
  final List<_TourPlace> _selected = [];

  int? _tourId;
  int? _version;

  bool _loading = true;
  bool _saving = false;
  bool _saved = false;
  bool _dirty = false;
  bool _leaving = false;
  bool _reviewing = false;

  String? _error;

  bool get _editing => _tourId != null;

  @override
  void initState() {
    super.initState();
    _tourId = widget.tourId;

    for (final json in widget.initialPlaces) {
      final place = _TourPlace.fromJson(json);

      if (place.id > 0 &&
          !_selected.any((item) => item.id == place.id) &&
          _selected.length < 20) {
        _selected.add(place);
      }
    }

    _dirty = _selected.isNotEmpty;
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorText(Object error) {
    if (error is TimeoutException) {
      return 'The request timed out. Please check your connection.';
    }

    if (error is ApiException) {
      switch (error.statusCode) {
        case 401:
          return 'Please sign in to manage your tours.';
        case 403:
          return 'You do not have permission to access this tour.';
        case 404:
          return 'This tour or historical place could not be found.';
        case 409:
          return 'This tour was changed elsewhere. Reload it before editing.';
        default:
          return error.message;
      }
    }

    if (error is FormatException) {
      return 'The backend returned an unexpected response.';
    }

    return 'Could not connect. Check the backend connection and try again.';
  }

  Future<void> _load() async {
    if (!mounted || _saving) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final placesResponse = await ApiClient.instance
          .get('/api/places', authenticated: false)
          .timeout(const Duration(seconds: 25));

      if (placesResponse is! List) {
        throw const FormatException('Invalid places response');
      }

      final loadedPlaces = <_TourPlace>[];

      for (final json in placesResponse) {
        if (json is Map) {
          final place = _TourPlace.fromJson(
            Map<String, dynamic>.from(json),
          );

          if (place.id > 0 &&
              !loadedPlaces.any((item) => item.id == place.id)) {
            loadedPlaces.add(place);
          }
        }
      }

      loadedPlaces.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      Map<String, dynamic>? loadedTour;

      if (_tourId != null) {
        final response = await ApiClient.instance
            .get('/api/tours/$_tourId')
            .timeout(const Duration(seconds: 25));

        if (response is! Map) {
          throw const FormatException('Invalid tour response');
        }

        loadedTour = Map<String, dynamic>.from(response);

        if (_integer(loadedTour['version']) == null) {
          throw const FormatException('Missing tour version');
        }
      }

      if (!mounted) return;

      final tour = loadedTour;

      setState(() {
        _places = loadedPlaces;

        if (tour != null) {
          _nameController.text = tour['name']?.toString() ?? '';
          _version = _integer(tour['version']);

          final stops = <Map<String, dynamic>>[];
          final rawStops = tour['stops'];

          if (rawStops is List) {
            for (final stop in rawStops) {
              if (stop is Map) {
                stops.add(Map<String, dynamic>.from(stop));
              }
            }
          }

          stops.sort(
                (a, b) => (_integer(a['stopOrder']) ?? 0).compareTo(
              _integer(b['stopOrder']) ?? 0,
            ),
          );

          _selected.clear();

          for (final stop in stops) {
            final place = _TourPlace.fromStop(stop);

            if (place.id > 0 &&
                !_selected.any((item) => item.id == place.id)) {
              _selected.add(place);
            }
          }

          _dirty = false;
        }

        _loading = false;
        _saved = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _errorText(error);
      });
    }
  }

  List<_TourPlace> get _filteredPlaces {
    final keyword = _searchController.text.trim().toLowerCase();

    if (keyword.isEmpty) return _places;

    return _places.where((place) {
      return place.name.toLowerCase().contains(keyword) ||
          place.city.toLowerCase().contains(keyword);
    }).toList();
  }

  void _add(_TourPlace place) {
    if (_saving || _saved || _leaving || _reviewing) return;

    if (_selected.any((item) => item.id == place.id)) {
      _message('This place is already in your tour.');
      return;
    }

    if (_selected.length >= 20) {
      _message('A tour can contain at most 20 places.');
      return;
    }

    setState(() {
      _selected.add(place);
      _dirty = true;
    });
  }

  void _remove(_TourPlace place) {
    if (_saving || _saved || _leaving || _reviewing) return;

    setState(() {
      _selected.removeWhere((item) => item.id == place.id);
      _dirty = true;
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    if (_saving || _saved || _leaving || _reviewing) return;
    if (oldIndex == newIndex) return;

    // onReorderItem already adjusts newIndex after removing the item.
    setState(() {
      final place = _selected.removeAt(oldIndex);
      _selected.insert(newIndex, place);
      _dirty = true;
    });
  }

  bool _validateTour({bool forReview = false}) {
    if (!mounted) return false;

    FocusScope.of(context).unfocus();

    final form = _formKey.currentState;
    final valid = form?.validate() ?? true;
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _message(
        forReview
            ? 'Please enter a tour name before reviewing your tour.'
            : 'Please enter a tour name before saving your tour.',
      );

      if (form != null) {
        _nameFocusNode.requestFocus();
      }
      return false;
    }

    if (name.length > 150 || !valid) {
      _message('Please enter a tour name using at most 150 characters.');

      if (form != null) {
        _nameFocusNode.requestFocus();
      }
      return false;
    }

    if (_selected.isEmpty) {
      _message('Select at least one historical place.');
      return false;
    }

    if (_selected.length > 20) {
      _message('A tour can contain at most 20 places.');
      return false;
    }

    return true;
  }

  Future<bool> _canLeave() async {
    if (!mounted || _saving) return false;
    if (!_dirty) return true;

    FocusScope.of(context).unfocus();

    final action = await showDialog<_TourLeaveAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _tourBackground,
          scrollable: true,
          title: Text(
            'Save your tour before leaving?',
            style: _tourTitleStyle(22),
          ),
          content: const Text(
            'You have unsaved changes. Save your tour or discard '
                'the changes to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(
                  _TourLeaveAction.discard,
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: _tourPrimary,
              ),
              child: const Text('Discard'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(
                  _TourLeaveAction.save,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: _tourPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save & continue'),
            ),
          ],
        );
      },
    );

    if (!mounted) return false;

    switch (action) {
      case _TourLeaveAction.discard:
        return true;

      case _TourLeaveAction.save:
      // Navigate only to the destination the user selected.
        return await _save(
          notifyOnSaved: false,
          navigateToSignIn: false,
        );

      case null:
        return false;
    }
  }

  Future<void> _navigate(VoidCallback callback) async {
    if (!mounted || _saving || _leaving || _reviewing) return;

    _leaving = true;

    try {
      final allowed = await _canLeave();

      if (!mounted || !allowed) return;

      setState(() => _dirty = false);

      // Update PopScope before a callback pops this route.
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) return;
      callback();
    } finally {
      _leaving = false;
    }
  }

  Future<void> _back() async {
    if (!mounted || _saving || _leaving || _reviewing) return;

    _leaving = true;

    try {
      final allowed = await _canLeave();

      if (!mounted || !allowed) return;

      setState(() => _dirty = false);
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) return;

      final navigator = Navigator.of(context);

      if (navigator.canPop()) {
        navigator.pop();
      } else {
        widget.onHome();
      }
    } finally {
      _leaving = false;
    }
  }

  Future<void> _review() async {
    if (!mounted ||
        _loading ||
        _saving ||
        _saved ||
        _leaving ||
        _reviewing ||
        _error != null) {
      return;
    }

    if (!_validateTour(forReview: true)) return;

    _reviewing = true;
    bool? approved;

    try {
      approved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => _TourReviewScreen(
            name: _nameController.text.trim(),
            places: List<_TourPlace>.unmodifiable(_selected),
            editing: _editing,
          ),
        ),
      );
    } finally {
      _reviewing = false;
    }

    if (!mounted || approved != true) return;
    await _save();
  }

  Future<bool> _save({
    bool notifyOnSaved = true,
    bool navigateToSignIn = true,
  }) async {
    if (!mounted || _saving) return false;
    if (_saved && !_dirty) return true;

    if (_loading) {
      _message('Please wait until your tour finishes loading.');
      return false;
    }

    if (_error != null) {
      _message('Please retry loading your tour before saving.');
      return false;
    }

    if (!_validateTour()) return false;

    final name = _nameController.text.trim();

    setState(() => _saving = true);

    Map<String, dynamic>? savedTour;

    try {
      final token = await TokenStore.getAccessToken();

      if (!mounted) return false;

      if (token == null || token.trim().isEmpty) {
        _message('Please sign in to save your tour.');

        if (navigateToSignIn) {
          widget.onSignIn?.call();
        }
        return false;
      }

      final body = <String, dynamic>{
        'name': name,
        'placeIds': _selected.map((place) => place.id).toList(),
      };

      dynamic response;

      if (_editing) {
        if (_version == null) {
          _message('Reload this tour before saving changes.');
          return false;
        }

        body['version'] = _version;

        response = await ApiClient.instance.put(
          '/api/tours/$_tourId',
          body: body,
        );
      } else {
        response = await ApiClient.instance.post(
          '/api/tours',
          body: body,
        );
      }

      if (response is! Map) {
        throw const FormatException('Invalid saved tour response');
      }

      final tour = Map<String, dynamic>.from(response);
      final savedId = _integer(tour['id']);
      final savedVersion = _integer(tour['version']);

      if (savedId == null || savedId <= 0 || savedVersion == null) {
        throw const FormatException('Missing saved tour ID or version');
      }

      if (!mounted) return false;

      savedTour = tour;

      setState(() {
        _tourId = savedId;
        _version = savedVersion;
        _dirty = false;
        _saved = true;
      });

      _message('Tour saved successfully.');
    } catch (error) {
      _message(_errorText(error));
      return false;
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }

    if (!mounted || savedTour == null) return false;

    if (notifyOnSaved) {
      widget.onSaved?.call(savedTour);
    }

    return true;
  }

  Widget _heading(String text) {
    return Text(text, style: _tourTitleStyle(21));
  }

  Widget _placeCard(_TourPlace place) {
    final added = _selected.any((item) => item.id == place.id);
    final rating = place.rating;

    return SizedBox(
      width: 136,
      child: Card(
        margin: const EdgeInsets.only(right: 9),
        elevation: 0,
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: _tourBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 86,
              width: double.infinity,
              child: _TourPlaceImage(place: place),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 30,
                      child: Text(
                        place.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: _tourHeading,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: _tourMuted,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            place.city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: _tourMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: rating != null && rating > 0
                              ? Text(
                            '★ ${rating.toStringAsFixed(1)}'
                                '${place.reviewCount > 0 ? ' (${place.reviewCount})' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: _tourPrimary,
                            ),
                          )
                              : const SizedBox.shrink(),
                        ),
                        IconButton(
                          tooltip: added ? 'Already added' : 'Add to tour',
                          onPressed: added || _saving || _saved || _leaving
                              ? null
                              : () => _add(place),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          iconSize: 23,
                          icon: Icon(
                            added ? Icons.check_circle : Icons.add_circle,
                            color: added ? Colors.green : _tourPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectedRow(_TourPlace place, int index) {
    return Container(
      key: ValueKey(place.id),
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _tourBorder),
      ),
      child: Row(
        children: [
          if (!_saving && !_saved)
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  Icons.drag_indicator,
                  size: 20,
                  color: _tourMuted,
                ),
              ),
            ),
          CircleAvatar(
            radius: 12,
            backgroundColor: _tourPrimary,
            child: Text(
              '${index + 1}',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
          const SizedBox(width: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 48,
              height: 46,
              child: _TourPlaceImage(place: place),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  place.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: _tourHeading,
                  ),
                ),
                if (place.city.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    place.city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: _tourMuted),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  place.visitDurationLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.3,
                    color: _tourMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove place',
            onPressed: _saving || _saved || _leaving
                ? null
                : () => _remove(place),
            iconSize: 20,
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBody(String message) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 42, color: _tourMuted),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _load,
              style: FilledButton.styleFrom(
                backgroundColor: _tourPrimary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formBody(List<_TourPlace> filtered) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          Text(
            _editing ? 'Edit Your Tour' : 'Create a Tour',
            style: _tourTitleStyle(31),
          ),
          const SizedBox(height: 5),
          const Text(
            'Plan your own heritage journey',
            style: TextStyle(fontSize: 12, color: _tourMuted),
          ),
          const SizedBox(height: 22),
          TextFormField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            enabled: !_saving && !_saved,
            maxLength: 150,
            textCapitalization: TextCapitalization.words,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Tour Name',
              hintText: 'e.g. Anuradhapura Heritage Tour',
              prefixIcon: const Icon(
                Icons.map_outlined,
                color: _tourPrimary,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: _tourPrimary,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (_) => setState(() => _dirty = true),
            validator: (value) {
              final name = value?.trim() ?? '';
              if (name.isEmpty) return 'Tour name is required.';
              if (name.length > 150) return 'Use at most 150 characters.';
              return null;
            },
          ),
          const SizedBox(height: 18),
          _heading('Add Places to Your Tour'),
          const SizedBox(height: 6),
          const Text(
            'Search and select historical places to include',
            style: TextStyle(fontSize: 11, color: _tourMuted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            enabled: !_saving && !_saved,
            style: const TextStyle(fontSize: 12),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search places or cities...',
              prefixIcon: const Icon(Icons.search, size: 21),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                tooltip: 'Clear search',
                onPressed: _saving || _saved
                    ? null
                    : () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close, size: 20),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 25),
              child: Text(
                'No historical places found.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _tourMuted),
              ),
            )
          else
            SizedBox(
              height: 175,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filtered.length,
                itemBuilder: (_, index) => _placeCard(filtered[index]),
              ),
            ),
          const SizedBox(height: 20),
          _heading(
            'Your Tour (${_selected.length} '
                '${_selected.length == 1 ? 'place' : 'places'})',
          ),
          const SizedBox(height: 8),
          if (_selected.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Tap + on a place to add it to your tour.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: _tourMuted),
              ),
            )
          else ...[
            const Text(
              'Drag the handle to change the visit order.',
              style: TextStyle(fontSize: 11, color: _tourMuted),
            ),
            const SizedBox(height: 10),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _selected.length,
              onReorderItem: _reorder,
              itemBuilder: (_, index) => _selectedRow(
                _selected[index],
                index,
              ),
            ),
          ],
          const SizedBox(height: 22),
          if (_saved) ...[
            const Text(
              'Tour saved successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _saving
                  ? null
                  : () => setState(() => _saved = false),
              style: OutlinedButton.styleFrom(
                foregroundColor: _tourPrimary,
                side: const BorderSide(color: _tourPrimary),
              ),
              child: const Text('Edit this tour'),
            ),
          ] else
            FilledButton(
              onPressed: _saving ? null : _review,
              style: FilledButton.styleFrom(
                backgroundColor: _tourPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Review Tour',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 21),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bottomNavigation() {
    return NavigationBar(
      selectedIndex: 2,
      backgroundColor: Colors.white,
      indicatorColor: _tourSurface,
      onDestinationSelected: _saving
          ? null
          : (index) {
        switch (index) {
          case 0:
            _navigate(widget.onHome);
            break;
          case 1:
            _navigate(widget.onExplore);
            break;
          case 2:
            break;
          case 3:
            _navigate(widget.onCommunity);
            break;
          case 4:
            _navigate(widget.onProfile);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPlaces;
    final error = _error;

    return Theme(
      data: _tourTheme(context),
      child: PopScope(
        canPop: !_saving && !_dirty,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop || _saving || _leaving || _reviewing) return;
          if (ModalRoute.of(context)?.isCurrent != true) return;
          _back();
        },
        child: Scaffold(
          backgroundColor: _tourBackground,
          appBar: AppBar(
            backgroundColor: _tourBackground,
            foregroundColor: _tourHeading,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            leading: IconButton(
              onPressed: _saving ? null : _back,
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                const Icon(Icons.spa, color: _tourPrimary, size: 30),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CEYLON HERITAGE',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _tourTitleStyle(15),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'EXPLORE · DISCOVER · PRESERVE',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 6,
                          letterSpacing: 1,
                          color: _tourMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: _loading
              ? const Center(
            child: CircularProgressIndicator(color: _tourPrimary),
          )
              : error != null
              ? _errorBody(error)
              : _formBody(filtered),
          bottomNavigationBar: _bottomNavigation(),
        ),
      ),
    );
  }
}

class _TourReviewScreen extends StatelessWidget {
  const _TourReviewScreen({
    required this.name,
    required this.places,
    required this.editing,
  });

  final String name;
  final List<_TourPlace> places;
  final bool editing;

  String _minutesLabel(int minutes) {
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;

    if (hours == 0) return '$remaining min';
    if (remaining == 0) return '$hours hr';
    return '$hours hr $remaining min';
  }

  String _visitLabel(_TourPlace place) {
    return place.visitDurationLabel;
  }

  Widget _panel(Widget child) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _tourBorder),
      ),
      child: child,
    );
  }

  Widget _summaryCard(IconData icon, String label, String value) {
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _tourPrimary, size: 24),
          const SizedBox(height: 9),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _tourMuted),
          ),
          const SizedBox(height: 5),
          Text(value, style: _tourTitleStyle(18)),
        ],
      ),
    );
  }

  Widget _placeRow(_TourPlace place, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _panel(
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: _tourSurface,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: _tourPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 76,
                height: 68,
                child: _TourPlaceImage(place: place),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name, style: _tourTitleStyle(15)),
                  if (place.city.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: _tourPrimary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            place.city,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _tourMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: _tourPrimary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _visitLabel(place),
                          style: const TextStyle(
                            fontSize: 12,
                            color: _tourMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeline() {
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tour Stops', style: _tourTitleStyle(23)),
          const SizedBox(height: 16),
          for (var index = 0; index < places.length; index++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 34,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: _tourPrimary,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (index < places.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: _tourPrimary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3, bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            places[index].name,
                            style: _tourTitleStyle(16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _visitLabel(places[index]),
                            style: const TextStyle(
                              fontSize: 12,
                              color: _tourMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(color: _tourBorder),
          const SizedBox(height: 5),
          const Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: _tourPrimary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Stops follow your selected order.',
                  style: TextStyle(fontSize: 12, color: _tourMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allDurationsKnown = places.isNotEmpty &&
        places.every((place) {
          final minutes = place.visitMinutes;
          return minutes != null && minutes > 0;
        });

    final visitMinutes = places.fold<int>(
      0,
          (total, place) => total + (place.visitMinutes ?? 0),
    );

    return Theme(
      data: _tourTheme(context),
      child: Scaffold(
        backgroundColor: _tourBackground,
        appBar: AppBar(
          backgroundColor: _tourBackground,
          foregroundColor: _tourHeading,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          leading: IconButton(
            tooltip: 'Continue editing',
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              const Icon(Icons.spa, color: _tourPrimary, size: 30),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CEYLON HERITAGE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _tourTitleStyle(15),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'EXPLORE · DISCOVER · PRESERVE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8,
                        letterSpacing: 1,
                        color: _tourMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            Text('Review Tour', style: _tourTitleStyle(31)),
            const SizedBox(height: 5),
            const Text(
              'Review your tour before saving',
              style: TextStyle(fontSize: 12, color: _tourMuted),
            ),
            const SizedBox(height: 20),
            _panel(
              Row(
                children: [
                  if (places.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 74,
                        height: 60,
                        child: _TourPlaceImage(place: places.first),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(name, style: _tourTitleStyle(19)),
                  ),
                  IconButton(
                    tooltip: 'Edit tour',
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: _tourPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final visitCard = _summaryCard(
                  Icons.access_time,
                  'Total visit time',
                  allDurationsKnown
                      ? _minutesLabel(visitMinutes)
                      : 'Not configured',
                );

                final placesCard = _summaryCard(
                  Icons.account_balance_outlined,
                  'Total places',
                  '${places.length} '
                      '${places.length == 1 ? 'place' : 'places'}',
                );

                if (constraints.maxWidth < 300) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      visitCard,
                      const SizedBox(height: 10),
                      placesCard,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: visitCard),
                    const SizedBox(width: 10),
                    Expanded(child: placesCard),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Places in this Tour (${places.length})',
              style: _tourTitleStyle(21),
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < places.length; index++)
              _placeRow(places[index], index),
            const SizedBox(height: 10),
            _timeline(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Tour'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _tourPrimary,
                      side: const BorderSide(color: _tourPrimary),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: places.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: _tourPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      editing ? 'Save Changes' : 'Start Tour',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TourPlace {
  const _TourPlace({
    required this.id,
    required this.name,
    required this.city,
    required this.imageUrl,
    required this.duration,
    required this.visitMinutes,
    required this.rating,
    required this.reviewCount,
  });

  final int id;
  final String name;
  final String city;
  final String imageUrl;
  final String duration;
  final int? visitMinutes;
  final double? rating;
  final int reviewCount;

  String get visitDurationLabel {
    final text = duration.trim();
    if (text.isNotEmpty) return text;

    final minutes = visitMinutes;

    if (minutes == null || minutes <= 0) {
      return 'Visit duration not provided';
    }

    final hours = minutes ~/ 60;
    final remaining = minutes % 60;

    if (hours == 0) return '$minutes min';
    if (remaining == 0) return '$hours hr';
    return '$hours hr $remaining min';
  }

  factory _TourPlace.fromJson(Map<String, dynamic> json) {
    return _TourPlace(
      id: _integer(json['id']) ?? 0,
      name: json['name']?.toString() ?? 'Historical place',
      city: json['city']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      duration: json['visitDuration']?.toString() ?? '',
      visitMinutes: _integer(json['visitDurationMinutes']),
      rating: _decimal(json['rating']),
      reviewCount: _integer(json['reviewCount']) ?? 0,
    );
  }

  factory _TourPlace.fromStop(Map<String, dynamic> json) {
    return _TourPlace.fromJson({
      ...json,
      'id': json['placeId'],
      'name': json['placeName'],
      'city': json['placeCity'],
    });
  }

  String? get asset {
    final normalized = name.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );

    const assets = <String, String>{
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
      'ruwanwelisaya': 'ruwanwelisaya.png',
      'ruwanwalisaya': 'ruwanwelisaya.png',
      'polonnaruwaancientcity': 'polonnaruwa.png',
      'gallefort': 'galle_fort.png',
      'galvihara': 'gal_vihara.png',
      'rankothvehera': 'rankoth_vehera.png',
      'lankathilakatemple': 'lankathilaka_temple.png',
      'lankatilakatemple': 'lankathilaka_temple.png',
      'parakramasamudraya': 'parakrama_samudraya.png',
      'sigiriya': 'sigiriya.png',
      'sigiriyarockfortress': 'sigiriya.png',
      'templeofthetooth': 'temple_of_the_tooth.png',
      'jaffnafort': 'jaffna_fort.png',
      'mihintale': 'mihintale.png',
    };

    final filename = assets[normalized];
    return filename == null ? null : 'assets/images/$filename';
  }
}

class _TourPlaceImage extends StatelessWidget {
  const _TourPlaceImage({required this.place});

  final _TourPlace place;

  Widget _placeholder() {
    return Container(
      color: _tourSurface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.account_balance_outlined,
        color: _tourMuted,
      ),
    );
  }

  Widget _networkImage() {
    final raw = place.imageUrl.trim();
    if (raw.isEmpty) return _placeholder();

    if (raw.startsWith('assets/')) {
      return Image.asset(
        raw,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => _placeholder(),
      );
    }

    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(raw);

    final url = uri != null && uri.hasScheme
        ? raw
        : '$base/${raw.replaceFirst(RegExp(r'^/+'), '')}';

    final resolved = Uri.tryParse(url);

    if (resolved == null ||
        (resolved.scheme != 'http' && resolved.scheme != 'https')) {
      return _placeholder();
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) => _placeholder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asset = place.asset;
    if (asset == null) return _networkImage();

    return Image.asset(
      asset,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) => _networkImage(),
    );
  }
}

int? _integer(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _decimal(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}