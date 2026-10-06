import 'package:flutter/material.dart';

import '../models/tourism_place.dart';
import '../services/tourism_service.dart';
import '../widgets/tourism_bottom_nav.dart';
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
  String _tab = 'Overview';
  final _tabs = const ['Overview', 'Reviews', 'Photos'];

  Future<void> _toggleFavorite() async {
    try {
      if (_saved) {
        await TourismService.instance.removeFavorite(_place.id);
      } else {
        await TourismService.instance.addFavorite(_place.id);
      }
      if (mounted) setState(() => _saved = !_saved);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in to save places: $error')),
        );
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
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF87958D),
                        Color(0xFFD3A273),
                        Color(0xFF493F37),
                      ],
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
                        _place.name,
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
                    Text(
                      ' ${_place.rating.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE99030),
                      ),
                    ),
                    Text(
                      ' (${_place.reviewCount} reviews)',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF68716D),
                      ),
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
                                    placeName: _place.name,
                                  ),
                                ),
                              );
                            if (label == 'Photos')
                              _message('Place photos are not connected yet.');
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
                Text(
                  _place.description,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.55,
                    color: Color(0xFF53605A),
                  ),
                ),
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
                        onPressed: () =>
                            _message('Directions need a maps integration.'),
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
                Center(
                  child: TextButton(
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
                ),
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
