import 'package:flutter/material.dart';

import '../models/place_review.dart';
import '../models/tourism_place.dart';
import '../services/tourism_service.dart';
import '../widgets/tourism_bottom_nav.dart';
import 'add_review.dart';
import 'reviews.dart';

/// Rating summary for a place, loaded from the Spring Boot API.
class RatingsAndReviewsScreen extends StatefulWidget {
  const RatingsAndReviewsScreen({super.key, required this.placeId});
  final int placeId;
  @override
  State<RatingsAndReviewsScreen> createState() =>
      _RatingsAndReviewsScreenState();
}

class _RatingsAndReviewsScreenState extends State<RatingsAndReviewsScreen> {
  TourismPlace? _place;
  PlaceRatingSummary? _summary;
  String? _error;
  bool _loading = true;

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
      final results = await Future.wait([
        TourismService.instance.getPlace(widget.placeId),
        TourismService.instance.getRatingSummary(widget.placeId),
      ]);
      if (mounted)
        setState(() {
          _place = results[0] as TourismPlace;
          _summary = results[1] as PlaceRatingSummary;
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

  Future<void> _openReviews() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewsScreen(
          placeId: widget.placeId,
          placeName: _place?.name ?? 'Place',
        ),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _writeReview(TourismPlace place) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddReviewScreen(placeId: place.id, placeName: place.name),
      ),
    );
    if (mounted) _load();
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ratings & Reviews',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          Text(
            _place?.name ?? 'Place reviews',
            style: const TextStyle(fontSize: 10, color: Color(0xFF68716D)),
          ),
        ],
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Could not load ratings: $_error',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFB3261E),
                    ),
                  ),
                  TextButton(onPressed: _load, child: const Text('Try again')),
                ],
              ),
            ),
          )
        : _content(_place!, _summary!),
    bottomNavigationBar: const TourismBottomNav(currentIndex: 0),
  );

  Widget _content(TourismPlace place, PlaceRatingSummary summary) => ListView(
    padding: const EdgeInsets.fromLTRB(17, 8, 17, 24),
    children: [
      Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB4C5C0), Color(0xFFDAAA7E), Color(0xFF5C716B)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              right: 26,
              top: 24,
              child: Icon(
                Icons.wb_twilight,
                color: Color(0xFFFFE0A1),
                size: 42,
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    place.category,
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(13),
        decoration: _boxDecoration(),
        child: Row(
          children: [
            SizedBox(
              width: 77,
              child: Column(
                children: [
                  Text(
                    summary.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    '★★★★★',
                    style: TextStyle(fontSize: 10, color: Color(0xFFE99030)),
                  ),
                  Text(
                    'out of 5',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF87918B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                children: [
                  for (var stars = 5; stars >= 1; stars--)
                    _RatingBar(
                      stars: stars,
                      count: summary.countFor(stars),
                      total: summary.reviewCount,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 15),
      const Text(
        'Rating Breakdown',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      for (var stars = 5; stars >= 1; stars--)
        _BreakdownRow(stars: stars, count: summary.countFor(stars)),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _openReviews,
              style: _outlineStyle(),
              child: const Text(
                'Read All Reviews',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              onPressed: () => _writeReview(place),
              style: _filledStyle(),
              child: const Text(
                'Write Review',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

BoxDecoration _boxDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(15),
  border: Border.all(color: const Color(0xFFE9E2DB)),
);
ButtonStyle _outlineStyle() => OutlinedButton.styleFrom(
  foregroundColor: const Color(0xFF824A2B),
  side: const BorderSide(color: Color(0xFFE9E2DB)),
  padding: const EdgeInsets.symmetric(vertical: 12),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
);
ButtonStyle _filledStyle() => FilledButton.styleFrom(
  backgroundColor: const Color(0xFF824A2B),
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(vertical: 12),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
);

class _RatingBar extends StatelessWidget {
  const _RatingBar({
    required this.stars,
    required this.count,
    required this.total,
  });
  final int stars;
  final int count, total;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(
          width: 22,
          child: Text('$stars ★', style: const TextStyle(fontSize: 9)),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : count / total,
              minHeight: 5,
              backgroundColor: const Color(0xFFF2ECE6),
              color: const Color(0xFF824A2B),
            ),
          ),
        ),
      ],
    ),
  );
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.stars, required this.count});
  final int stars, count;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
    decoration: _boxDecoration(),
    child: Row(
      children: [
        const Icon(Icons.task_alt, size: 15, color: Color(0xFF824A2B)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            '$stars-star reviews',
            style: const TextStyle(fontSize: 10, color: Color(0xFF53605A)),
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
