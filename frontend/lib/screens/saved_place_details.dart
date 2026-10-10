import 'package:flutter/material.dart';

import '../models/tourism_place.dart';
import '../services/tourism_service.dart';
import '../widgets/tourism_bottom_nav.dart';
import '../widgets/place_image.dart';
import '../widgets/place_reviews_preview.dart';
import 'add_review.dart';
import 'reviews.dart';

/// Saved attraction details backed by the place and favourites APIs.
class SavedPlaceDetailsScreen extends StatefulWidget {
  const SavedPlaceDetailsScreen({
    super.key,
    required this.place,
    this.initiallySaved = false,
  });
  final TourismPlace place;
  final bool initiallySaved;
  @override
  State<SavedPlaceDetailsScreen> createState() =>
      _SavedPlaceDetailsScreenState();
}

class _SavedPlaceDetailsScreenState extends State<SavedPlaceDetailsScreen> {
  late bool _saved = widget.initiallySaved;
  String _tab = 'Overview';
  final _tabs = const ['Overview', 'Reviews', 'Photos'];

  Future<void> _toggleSaved() async {
    try {
      if (_saved) {
        await TourismService.instance.removeFavorite(widget.place.id);
      } else {
        await TourismService.instance.addFavorite(
          widget.place.id,
          place: widget.place,
        );
      }
      if (mounted) setState(() => _saved = !_saved);
    } catch (error) {
      if (mounted) _message('Sign in to save places: $error');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAF8F5),
    body: CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 210,
          pinned: false,
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF58776D),
          surfaceTintColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: PlaceImage(
                    place: widget.place,
                    showAttribution: true,
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x11000000), Color(0xAA000000)],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 15,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.place.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.place.category,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 34,
                  child: _CircleAction(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.maybePop(context),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 34,
                  child: Row(
                    children: [
                      _CircleAction(
                        icon: Icons.ios_share,
                        onTap: () => _message('Share is not connected yet.'),
                      ),
                      const SizedBox(width: 8),
                      _CircleAction(
                        icon: _saved ? Icons.favorite : Icons.favorite_border,
                        iconColor: const Color(0xFFE95C4C),
                        onTap: _toggleSaved,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 11, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Color(0xFFE99030)),
                    Text(
                      ' ${widget.place.rating.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE99030),
                      ),
                    ),
                    Text(
                      ' (${widget.place.distanceLabel} away)',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF68716D),
                      ),
                    ),
                    const Spacer(),
                    _SavedBadge(saved: _saved),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: _tabs.map((label) {
                    final selected = _tab == label;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 9,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF47514D),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          selected: selected,
                          showCheckmark: false,
                          onSelected: (_) async {
                            setState(() => _tab = label);
                            if (label == 'Reviews')
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReviewsScreen(
                                    placeId: widget.place.id,
                                    placeName: widget.place.name,
                                  ),
                                ),
                              );
                          },
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF824A2B),
                          side: BorderSide(
                            color: selected
                                ? const Color(0xFF824A2B)
                                : const Color(0xFFE9E2DB),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                if (_tab == 'Photos') ...[
                  Row(
                    children: [
                      for (var index = 0; index < 3; index++) ...[
                        if (index > 0) const SizedBox(width: 7),
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 0.9,
                            child: PlaceImage(
                              place: widget.place,
                              galleryIndex: index,
                              showAttribution: true,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _toggleSaved,
                        icon: Icon(
                          _saved ? Icons.favorite : Icons.favorite_border,
                          size: 15,
                          color: const Color(0xFFE95C4C),
                        ),
                        label: Text(
                          _saved ? 'Saved to Favourites' : 'Save to Favourites',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF343D39),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE9E2DB)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCustomList(context),
                        icon: const Icon(
                          Icons.add,
                          size: 15,
                          color: Color(0xFF824A2B),
                        ),
                        label: const Text(
                          'Add to Custom List',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF824A2B),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE9E2DB)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Text(
                  widget.place.description,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.55,
                    color: Color(0xFF53605A),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFE9E2DB)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            _message('Directions need a maps integration.'),
                        icon: const Icon(Icons.directions, size: 15),
                        label: const Text(
                          'Directions',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF824A2B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _message('Share location is not connected yet.'),
                        icon: const Icon(Icons.share_outlined, size: 15),
                        label: const Text(
                          'Share Location',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF824A2B),
                          side: const BorderSide(color: Color(0xFF824A2B)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewsScreen(
                            placeId: widget.place.id,
                            placeName: widget.place.name,
                          ),
                        ),
                      ),
                      child: const Text(
                        'See ratings & reviews',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF824A2B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _openAddReview,
                      icon: const Icon(Icons.rate_review_outlined, size: 14),
                      label: const Text(
                        'Add Review',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF824A2B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                PlaceReviewsPreview(
                  placeId: widget.place.id,
                  placeName: widget.place.name,
                  initialRating: widget.place.rating,
                  initialReviewCount: widget.place.reviewCount,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    bottomNavigationBar: const TourismBottomNav(currentIndex: 3),
  );

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _openAddReview() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddReviewScreen(
          placeId: widget.place.id,
          placeName: widget.place.name,
        ),
      ),
    );
  }
}

void _showCustomList(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: const Color(0xFFFAF8F5),
  builder: (context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add to Custom List',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          for (final list in [
            'Weekend Trip',
            'Historic Galle',
            'Places to Visit',
          ])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.folder_outlined,
                color: Color(0xFF824A2B),
              ),
              title: Text(list, style: const TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Custom lists will be connected later.'),
                  ),
                );
              },
            ),
        ],
      ),
    ),
  ),
);

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.onTap,
    this.iconColor = const Color(0xFF824A2B),
  });
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, size: 17, color: iconColor),
      ),
    ),
  );
}

class _SavedBadge extends StatelessWidget {
  const _SavedBadge({required this.saved});
  final bool saved;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF3EE),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Icon(
          saved ? Icons.check : Icons.add,
          size: 12,
          color: const Color(0xFF437259),
        ),
        const SizedBox(width: 3),
        Text(
          saved ? 'Saved' : 'Not saved',
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF437259),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
