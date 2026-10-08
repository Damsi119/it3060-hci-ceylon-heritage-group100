import 'package:flutter/material.dart';

import '../models/tourism_place.dart';
import '../services/tourism_service.dart';
import '../widgets/tourism_bottom_nav.dart';
import '../widgets/place_image.dart';
import 'saved_place_details.dart';

/// Curated places loaded and ranked by the API.
class PlaceRecommendationsScreen extends StatefulWidget {
  const PlaceRecommendationsScreen({super.key});
  @override
  State<PlaceRecommendationsScreen> createState() =>
      _PlaceRecommendationsScreenState();
}

class _PlaceRecommendationsScreenState
    extends State<PlaceRecommendationsScreen> {
  String _filter = 'Nearby';
  List<TourismPlace> _places = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final places = await TourismService.instance.getRecommendations(
        _filter.toLowerCase(),
      );
      if (mounted)
        setState(() {
          _places = places;
          _loading = false;
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _error = error.toString();
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAF8F5),
    appBar: AppBar(
      backgroundColor: const Color(0xFFFAF8F5),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.chevron_left),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          Text(
            'Curated places across Sri Lanka',
            style: TextStyle(fontSize: 10, color: Color(0xFF68716D)),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(17, 8, 17, 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recommended for You',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 9),
              Row(
                children: ['Nearby', 'Popular', 'Trending'].map((name) {
                  final active = name == _filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text(
                        name,
                        style: TextStyle(
                          fontSize: 10,
                          color: active
                              ? Colors.white
                              : const Color(0xFF47514D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: active,
                      showCheckmark: false,
                      onSelected: (_) {
                        setState(() => _filter = name);
                        _load();
                      },
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF824A2B),
                      side: BorderSide(
                        color: active
                            ? const Color(0xFF824A2B)
                            : const Color(0xFFE9E2DB),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Could not load recommendations: $_error',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFB3261E),
                          ),
                        ),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(17, 4, 17, 20),
                  itemCount: _places.length + 1,
                  separatorBuilder: (_, index) =>
                      SizedBox(height: index == _places.length - 1 ? 12 : 9),
                  itemBuilder: (context, index) {
                    if (index == _places.length) {
                      return OutlinedButton(
                        onPressed: _load,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF824A2B),
                          side: const BorderSide(color: Color(0xFF824A2B)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'View All Recommendations',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }
                    final place = _places[index];
                    return _RecommendationCard(
                      place: place,
                      photoColumn: index % 3,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SavedPlaceDetailsScreen(place: place),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
    bottomNavigationBar: const TourismBottomNav(currentIndex: 0),
  );
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.place,
    required this.photoColumn,
    required this.onTap,
  });
  final TourismPlace place;
  final int photoColumn;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE9E2DB)),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          _RecommendationPhoto(
            place: place,
            column: photoColumn,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8EEE8),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    place.category,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Color(0xFF824A2B),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 13, color: Color(0xFFE99A26)),
                    Text(
                      ' ${place.rating.toStringAsFixed(1)} · ${place.distanceLabel}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF59625E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.near_me_outlined,
            color: Color(0xFF9AA6A0),
            size: 17,
          ),
        ],
      ),
    ),
  );
}

class _RecommendationPhoto extends StatelessWidget {
  const _RecommendationPhoto({
    required this.place,
    required this.column,
  });

  final TourismPlace place;
  final int column;

  @override
  Widget build(BuildContext context) => PlaceImage(
    place: place,
    width: 61,
    height: 61,
    galleryIndex: column,
    showAttribution: true,
  );
}
