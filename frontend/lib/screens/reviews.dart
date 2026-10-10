import 'package:flutter/material.dart';

import '../models/place_review.dart';
import '../services/tourism_service.dart';
import '../widgets/tourism_bottom_nav.dart';
import 'add_review.dart';

/// Guest reviews fetched from the API for a specific place.
class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({
    super.key,
    required this.placeId,
    this.placeName = 'Place',
  });
  final int placeId;
  final String placeName;
  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  String _filter = 'All';
  List<PlaceReview> _reviews = [];
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
      final reviews = await TourismService.instance.getReviews(
        widget.placeId,
        sort: _filter == 'Highest Rated' ? 'highest-rated' : 'latest',
      );
      if (mounted)
        setState(() {
          _reviews = reviews;
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

  Future<void> _writeReview() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddReviewScreen(
          placeId: widget.placeId,
          placeName: widget.placeName,
        ),
      ),
    );
    if (mounted) _load();
  }

  bool _isMyReview(PlaceReview review) =>
      review.authorName.toLowerCase() == 'you' ||
      review.authorLabel.toLowerCase() == 'your review';

  Future<void> _editReview(PlaceReview review) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddReviewScreen(
          placeId: widget.placeId,
          placeName: widget.placeName,
          review: review,
        ),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _deleteReview(PlaceReview review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete your review?'),
        content: const Text('This review will be removed from this place.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await TourismService.instance.deleteReview(widget.placeId, review);
      if (!mounted) return;
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your review was deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete review: $error')),
      );
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reviews',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          Text(
            'What visitors say about ${widget.placeName}',
            style: const TextStyle(fontSize: 10, color: Color(0xFF68716D)),
          ),
        ],
      ),
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(17, 4, 17, 11),
          child: Row(
            children: [
              ...['All', 'Latest', 'Highest Rated'].map((label) {
                final active = label == _filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        color: active ? Colors.white : const Color(0xFF47514D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: active,
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() => _filter = label);
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
              }),
              const Spacer(),
              TextButton.icon(
                onPressed: _writeReview,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add Review', style: TextStyle(fontSize: 9)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF824A2B),
                  visualDensity: VisualDensity.compact,
                ),
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
                          'Could not load reviews: $_error',
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
              : _reviews.isEmpty
              ? const Center(
                  child: Text('No reviews yet. Be the first to write one.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(17, 0, 17, 20),
                  itemCount: _reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    final review = _reviews[index];
                    return _ReviewCard(
                      review: review,
                      isMine: _isMyReview(review),
                      onEdit: () => _editReview(review),
                      onDelete: () => _deleteReview(review),
                    );
                  },
                ),
        ),
      ],
    ),
    bottomNavigationBar: const TourismBottomNav(currentIndex: 0),
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.isMine,
    required this.onEdit,
    required this.onDelete,
  });
  final PlaceReview review;
  final bool isMine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE9E2DB)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x09000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: const Color(0xFFD4B18F),
              child: const Icon(
                Icons.person,
                size: 17,
                color: Color(0xFF824A2B),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.authorName,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    review.authorLabel,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Color(0xFF87918B),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '★' * review.rating,
              style: const TextStyle(fontSize: 11, color: Color(0xFFE99030), letterSpacing: 1),
            ),
            if (isMine)
              PopupMenuButton<String>(
                tooltip: 'Manage your review',
                padding: EdgeInsets.zero,
                onSelected: (action) {
                  if (action == 'edit') onEdit();
                  if (action == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          review.comment,
          style: const TextStyle(
            fontSize: 9,
            height: 1.5,
            color: Color(0xFF53605A),
          ),
        ),
      ],
    ),
  );
}
