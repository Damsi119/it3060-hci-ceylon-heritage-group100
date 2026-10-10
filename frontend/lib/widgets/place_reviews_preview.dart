import 'package:flutter/material.dart';

import '../models/place_review.dart';
import '../services/tourism_service.dart';

/// Inline rating summary and recent visitor reviews for a place detail page.
class PlaceReviewsPreview extends StatefulWidget {
  const PlaceReviewsPreview({
    super.key,
    required this.placeId,
    required this.placeName,
    required this.initialRating,
    required this.initialReviewCount,
  });

  final int placeId;
  final String placeName;
  final double initialRating;
  final int initialReviewCount;

  @override
  State<PlaceReviewsPreview> createState() => _PlaceReviewsPreviewState();
}

class _PlaceReviewsPreviewState extends State<PlaceReviewsPreview> {
  PlaceRatingSummary? _summary;
  List<PlaceReview> _reviews = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    PlaceRatingSummary? summary;
    List<PlaceReview> reviews = const [];
    try {
      summary = await TourismService.instance.getRatingSummary(widget.placeId);
    } catch (_) {}
    try {
      reviews = await TourismService.instance.getReviews(widget.placeId);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _reviews = reviews.take(3).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rating = _summary?.averageRating ?? widget.initialRating;
    final count = _summary?.reviewCount ?? widget.initialReviewCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ratings & Reviews',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            const Icon(Icons.star, color: Color(0xFFE99030), size: 22),
            const SizedBox(width: 4),
            Text(
              rating > 0 ? rating.toStringAsFixed(1) : 'Be the first to rate',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 7),
            Text(
              count > 0 ? '$count ${count == 1 ? 'review' : 'reviews'}' : 'Share your experience',
              style: const TextStyle(fontSize: 10, color: Color(0xFF68716D)),
            ),
          ],
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_reviews.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'No written reviews for ${widget.placeName} yet. Be the first to share your visit.',
              style: const TextStyle(fontSize: 11, color: Color(0xFF68716D)),
            ),
          )
        else ...[
          const SizedBox(height: 8),
          for (final review in _reviews)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9E2DB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          review.authorName,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '★' * review.rating,
                        style: const TextStyle(fontSize: 11, color: Color(0xFFE99030)),
                      ),
                    ],
                  ),
                  if (review.comment.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      review.comment,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, height: 1.45, color: Color(0xFF53605A)),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }
}
