import 'package:flutter/material.dart';

import '../models/tourism_place.dart';
import '../services/tourism_service.dart';
import '../widgets/tourism_bottom_nav.dart';
import '../widgets/place_image.dart';
import 'saved_place_details.dart';

/// Saved places are private to the signed-in account and loaded from the API.
class MyFavouritesScreen extends StatefulWidget {
  const MyFavouritesScreen({super.key});
  @override
  State<MyFavouritesScreen> createState() => _MyFavouritesScreenState();
}

class _MyFavouritesScreenState extends State<MyFavouritesScreen> {
  final _search = TextEditingController();
  List<TourismPlace> _places = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final places = await TourismService.instance.getFavorites();
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
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = _places
        .where((place) => place.name.toLowerCase().contains(query))
        .toList();
    return Scaffold(
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
              'My Favourites',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              'Saved places in Galle',
              style: TextStyle(fontSize: 10, color: Color(0xFF68716D)),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 4, 17, 11),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search among saved places...',
                hintStyle: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF89938D),
                ),
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: const Icon(
                  Icons.tune,
                  size: 17,
                  color: Color(0xFF824A2B),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFFE9E2DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFFE9E2DB)),
                ),
              ),
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
                            'Sign in to load favourites. $_error',
                            textAlign: TextAlign.center,
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
                : visible.isEmpty
                ? const Center(child: Text('No saved places found.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(17, 0, 17, 20),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final place = visible[index];
                      return _FavouriteCard(
                        place: place,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SavedPlaceDetailsScreen(
                              place: place,
                              initiallySaved: true,
                            ),
                          ),
                        ),
                        onRemove: () async {
                          try {
                            await TourismService.instance.removeFavorite(
                              place.id,
                            );
                            if (mounted)
                              setState(
                                () => _places.removeWhere(
                                  (item) => item.id == place.id,
                                ),
                              );
                          } catch (error) {
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not remove favourite: $error',
                                  ),
                                ),
                              );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const TourismBottomNav(currentIndex: 3),
    );
  }
}

class _FavouriteCard extends StatelessWidget {
  const _FavouriteCard({
    required this.place,
    required this.onRemove,
    required this.onTap,
  });
  final TourismPlace place;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE9E2DB)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Row(
        children: [
          PlaceImage(
            place: place,
            width: 54,
            height: 54,
            showAttribution: true,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8EEE8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        place.category,
                        style: const TextStyle(
                          fontSize: 8,
                          color: Color(0xFF824A2B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      place.distanceLabel,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF68716D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.star, size: 12, color: Color(0xFFE99030)),
                    Text(
                      ' ${place.rating.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(
              Icons.favorite,
              size: 18,
              color: Color(0xFFE88A35),
            ),
          ),
        ],
      ),
    ),
  );
}
