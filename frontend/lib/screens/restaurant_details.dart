import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/tourism_place.dart';
import '../models/place_review.dart';
import '../services/place_photo_service.dart';
import '../widgets/place_image.dart';
import '../services/tourism_service.dart';
import '../widgets/tourism_bottom_nav.dart';
import 'add_review.dart';
import 'ratings_and_reviews.dart';
import 'reviews.dart';

/// Place details loaded from the tourism API.
class RestaurantDetailsScreen extends StatefulWidget {
  const RestaurantDetailsScreen({super.key, required this.place});
  final TourismPlace place;
  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  late TourismPlace _place = widget.place;
  bool _saved = false;
  PlaceRatingSummary? _ratingSummary;
  List<PlaceReview> _recentReviews = const [];
  String _tab = 'Overview';
  final _tabs = const ['Overview', 'Reviews', 'Photos'];

  int get _photoRow {
    final category = _place.category.toUpperCase();
    if (category.contains('RESTAURANT') || category.contains('FOOD')) return 1;
    if (category.contains('SHOP')) return 2;
    if (category.contains('HOTEL') || category.contains('STAY')) return 3;
    return 0;
  }

  String get _overviewText {
    if (_isGalleFort) return 'UNESCO World Heritage Site in Galle.';

    final description = _place.description.trim();
    final normalized = description.toLowerCase();
    final isGeneric = description.isEmpty ||
        normalized == _place.category.toLowerCase() ||
        normalized == 'openstreetmap place in sri lanka' ||
        normalized == 'restaurant' ||
        normalized == 'hotel' ||
        normalized == 'shop';
    if (!isGeneric) return description;

    final type = switch (_photoRow) {
      1 => 'restaurant',
      2 => 'shop',
      3 => 'place to stay',
      _ when _place.category.toUpperCase().contains('MUSEUM') => 'museum',
      _ => 'heritage site',
    };
    return '$_displayName is a $type in ${_place.city}. Explore the place, check its location, and use Get Directions to plan your visit.';
  }

  bool get _isGalleFort {
    final name = _place.name.trim().toLowerCase();
    return _place.slug.toLowerCase() == 'galle-fort' ||
        name == 'galle fort' ||
        name == 'old town of galle and its fortifications';
  }

  String get _displayName => _isGalleFort ? 'Galle Fort' : _place.name;
  double get _averageRating => _ratingSummary?.averageRating ?? _place.rating;
  int get _ratingCount => _ratingSummary?.reviewCount ?? _place.reviewCount;

  Widget _overviewPanel() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'About $_displayName',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 6),
      Text(
        _overviewText,
        style: const TextStyle(
          fontSize: 10,
          height: 1.55,
          color: Color(0xFF53605A),
        ),
      ),
    ],
  );

  Widget _photosGallery() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Photos of $_displayName',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          for (var index = 0; index < 3; index++) ...[
            if (index > 0) const SizedBox(width: 7),
            Expanded(
              child: AspectRatio(
                aspectRatio: 0.88,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: _PlacePhoto(
                    place: _place,
                    column: index,
                    gallery: true,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 5),
      _photoCredits(),
    ],
  );

  Widget _photoCredits() => FutureBuilder<List<PlacePhoto>>(
    future: PlacePhotoService.instance.getPhotos(_place),
    builder: (context, snapshot) {
      final photos = snapshot.data;
      final credits = photos
          ?.map((photo) => photo.attribution)
          .whereType<String>()
          .where((credit) => credit.isNotEmpty)
          .toSet()
          .toList();
      if (credits == null || credits.isEmpty) {
        return const Text(
          'No verified place photos are available yet.',
          style: TextStyle(fontSize: 9, color: Color(0xFF68716D)),
        );
      }
      final sourceUrl = photos!.first.sourceUrl;
      return InkWell(
        onTap: sourceUrl == null
            ? null
            : () async {
                await launchUrl(
                  Uri.parse(sourceUrl),
                  mode: LaunchMode.externalApplication,
                );
              },
        child: Text(
          'Photo credits: ${credits.join('; ')}${sourceUrl == null ? '' : ' - Source details'}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 9, color: Color(0xFF68716D)),
        ),
      );
    },
  );

  Future<void> _toggleFavorite() async {
    try {
      if (_saved) {
        await TourismService.instance.removeFavorite(_place.id);
      } else {
        await TourismService.instance.addFavorite(_place.id, place: _place);
      }
      if (mounted) {
        setState(() => _saved = !_saved);
        _message(_saved ? 'Added to Saved.' : 'Removed from Saved.');
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in to save places: $error')),
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _saved = TourismService.instance.isFavorite(widget.place.id);
    _loadRatingsAndReviews();
  }

  Future<void> _loadRatingsAndReviews() async {
    PlaceRatingSummary? summary;
    List<PlaceReview> reviews = const [];
    try {
      summary = await TourismService.instance.getRatingSummary(_place.id);
    } catch (_) {}
    try {
      reviews = await TourismService.instance.getReviews(_place.id);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _ratingSummary = summary;
      _recentReviews = reviews.take(3).toList();
    });
  }

  bool _isMyReview(PlaceReview review) =>
      review.authorName.toLowerCase() == 'you' ||
      review.authorLabel.toLowerCase() == 'your review';

  void _viewReview(PlaceReview review) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(review.authorName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('★' * review.rating, style: const TextStyle(color: Color(0xFFE99030))),
            const SizedBox(height: 10),
            Text(review.comment),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _editReview(PlaceReview review) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddReviewScreen(
          placeId: _place.id,
          placeName: _displayName,
          review: review,
        ),
      ),
    );
    if (mounted) _loadRatingsAndReviews();
  }

  Future<void> _deleteReview(PlaceReview review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your review?'),
        content: const Text('This review will be removed from this place.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await TourismService.instance.deleteReview(_place.id, review);
      if (!mounted) return;
      setState(() => _recentReviews = _recentReviews.where((item) => item.id != review.id).toList());
      _loadRatingsAndReviews();
      _message('Your review was deleted.');
    } catch (error) {
      if (mounted) _message('Could not delete review: $error');
    }
  }

  Future<void> _onReviewTap(PlaceReview review) async {
    if (!_isMyReview(review)) {
      _viewReview(review);
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFFFAF8F5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(
              title: Text('Your review', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('Choose an action'),
            ),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('View'),
              onTap: () => Navigator.pop(context, 'view'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFB3261E)),
              title: const Text('Delete', style: TextStyle(color: Color(0xFFB3261E))),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'view':
        _viewReview(review);
        break;
      case 'edit':
        _editReview(review);
        break;
      case 'delete':
        _deleteReview(review);
        break;
    }
  }

  Widget _ratingsAndReviewsPreview() {
    final summary = _ratingSummary;
    final average = _averageRating;
    final count = _ratingCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: Color(0xFFE99030), size: 19),
            const SizedBox(width: 4),
            Text(average > 0 ? average.toStringAsFixed(1) : 'Be the first to rate',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            Text(count > 0 ? '$count ${count == 1 ? 'review' : 'reviews'}' : 'Share your experience',
                style: const TextStyle(fontSize: 10, color: Color(0xFF68716D))),
            const Spacer(),
            if (summary != null)
              Text('★★★★★', style: TextStyle(fontSize: 11, color: Color(0xFFE99030))),
          ],
        ),
        if (_recentReviews.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('No written reviews yet.', style: TextStyle(fontSize: 10, color: Color(0xFF68716D))),
          )
        else ...[
          const SizedBox(height: 8),
          for (final review in _recentReviews) ...[
            GestureDetector(
              onTap: () => _onReviewTap(review),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE9E2DB))),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(review.authorName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
                    Text('${'★' * review.rating}', style: const TextStyle(fontSize: 10, color: Color(0xFFE99030))),
                  ]),
                  if (review.comment.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(review.comment, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, height: 1.4, color: Color(0xFF53605A))),
                  ],
                ],
              ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _openDirections() async {
    final latitude = _place.latitude;
    final longitude = _place.longitude;
    final destination = latitude != null && longitude != null
        ? '${latitude.toString()},${longitude.toString()}'
        : '${_place.address}, ${_place.city}, ${_place.province}';
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
      'travelmode': 'walking',
    });

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        _message('Could not open maps. Please try again.');
      }
    } catch (_) {
      if (mounted) _message('Could not open maps. Please try again.');
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
          backgroundColor: const Color(0xFF6D5848),
          surfaceTintColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: _PlacePhoto(
                    place: _place,
                    column: 0,
                    fit: BoxFit.cover,
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x22342A22), Color(0xBB342A22)],
                    ),
                  ),
                ),
                const Positioned(
                  right: 25,
                  top: 64,
                  child: Icon(
                    Icons.wb_twilight,
                    size: 52,
                    color: Color(0xFFFFE2A5),
                  ),
                ),
                Positioned(
                  left: 17,
                  right: 17,
                  bottom: 15,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_place.city}, ${_place.province}',
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
                  child: _HeroButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.maybePop(context),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 34,
                  child: Row(
                    children: [
                      _HeroButton(
                        icon: Icons.ios_share,
                        onTap: () => _message('Share is not connected yet.'),
                      ),
                      const SizedBox(width: 7),
                      _HeroButton(
                        icon: _saved ? Icons.favorite : Icons.favorite_border,
                        color: const Color(0xFFE96A4E),
                        onTap: _toggleFavorite,
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
            padding: const EdgeInsets.fromLTRB(17, 12, 17, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, size: 17, color: Color(0xFFE99030)),
                    if (_averageRating > 0 && _ratingCount > 0) ...[
                      Text(
                        ' ${_averageRating.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE99030),
                        ),
                      ),
                      Text(
                        ' ($_ratingCount reviews)',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF68716D),
                        ),
                      ),
                    ] else
                      const Text(
                        ' Be the first to rate',
                        style: TextStyle(fontSize: 10, color: Color(0xFF68716D)),
                      ),
                    const Spacer(),
                    const Icon(
                      Icons.location_on,
                      size: 15,
                      color: Color(0xFF824A2B),
                    ),
                    Text(
                      '${_place.distanceMeters} m away',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF68716D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: _tabs.map((label) {
                    final active = label == _tab;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 9,
                                color: active
                                    ? Colors.white
                                    : const Color(0xFF47514D),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          selected: active,
                          showCheckmark: false,
                          onSelected: (_) async {
                            setState(() => _tab = label);
                            if (label == 'Reviews')
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReviewsScreen(
                                    placeId: _place.id,
                                    placeName: _displayName,
                                  ),
                                ),
                              );
                          },
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF824A2B),
                          side: BorderSide(
                            color: active
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
                const SizedBox(height: 11),
                if (_tab == 'Photos')
                  _photosGallery()
                else
                  _overviewPanel(),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFE9E2DB)),
                Row(
                  children: [
                    Expanded(
                      child: _DetailInfo(
                        icon: Icons.access_time,
                        label: 'OPEN HOURS',
                        value: _place.openingHours ?? 'Hours not available',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DetailInfo(
                        icon: Icons.payments_outlined,
                        label: 'PRICE RANGE',
                        value: _place.priceRange ?? 'Not available',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _message('Calling is not connected yet.'),
                        icon: const Icon(Icons.call_outlined, size: 15),
                        label: const Text(
                          'Call Place',
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _openDirections,
                        icon: const Icon(Icons.directions, size: 15),
                        label: const Text(
                          'Get Directions',
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
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RatingsAndReviewsScreen(placeId: _place.id),
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
                const SizedBox(height: 8),
                const Text('Ratings & Reviews', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 7),
                _ratingsAndReviewsPreview(),
              ],
            ),
          ),
        ),
      ],
    ),
    bottomNavigationBar: const TourismBottomNav(currentIndex: 0),
  );

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _openAddReview() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddReviewScreen(
          placeId: _place.id,
          placeName: _displayName,
        ),
      ),
    );
    if (mounted) _loadRatingsAndReviews();
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.icon,
    required this.onTap,
    this.color = const Color(0xFF824A2B),
  });
  final IconData icon;
  final Color color;
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
        child: Icon(icon, size: 17, color: color),
      ),
    ),
  );
}

class _ReviewAction extends StatelessWidget {
  const _ReviewAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 13),
    label: Text(label, style: const TextStyle(fontSize: 9)),
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF824A2B),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      minimumSize: const Size(0, 28),
    ),
  );
}

class _PlacePhoto extends StatelessWidget {
  const _PlacePhoto({
    required this.place,
    required this.column,
    required this.fit,
    this.gallery = false,
  });

  final TourismPlace place;
  final int column;
  final BoxFit fit;
  final bool gallery;

  @override
  Widget build(BuildContext context) => PlaceImage(
    place: place,
    fit: fit,
    galleryIndex: gallery ? column : 0,
    showAttribution: true,
  );
}

class _DetailInfo extends StatelessWidget {
  const _DetailInfo({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 17, color: const Color(0xFF824A2B)),
      const SizedBox(width: 7),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 8, color: Color(0xFF87918B)),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ],
  );
}
