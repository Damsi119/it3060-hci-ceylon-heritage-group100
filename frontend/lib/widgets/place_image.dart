import 'package:flutter/material.dart';

import '../models/tourism_place.dart';
import '../services/place_photo_service.dart';
import 'place_photo_assets.dart';

/// A consistent place image for cards, headers, and photo galleries.
class PlaceImage extends StatelessWidget {
  const PlaceImage({
    super.key,
    required this.place,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.galleryIndex = 0,
    this.showAttribution = false,
  });

  final TourismPlace place;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int galleryIndex;
  final bool showAttribution;

  @override
  Widget build(BuildContext context) {
    final gallery = localPlacePhotoGalleryAssets(place);
    if (gallery.isNotEmpty) {
      final index = galleryIndex < gallery.length ? galleryIndex : 0;
      return _frame(
        Image.asset(
          gallery[index],
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }

    return FutureBuilder<PlacePhoto?>(
      future: PlacePhotoService.instance.getCoverPhoto(place),
      builder: (context, snapshot) {
        final photo = snapshot.data;
        if (photo == null) return _fallback();
        return _frame(
          Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                photo.imageUrl,
                width: width,
                height: height,
                fit: fit,
                errorBuilder: (_, __, ___) => _fallback(),
              ),
              if (showAttribution &&
                  photo.attribution != null &&
                  photo.attribution!.isNotEmpty)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    color: Colors.black54,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 2,
                    ),
                    child: Text(
                      photo.attribution!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 7),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _frame(Widget child) => ClipRRect(
    borderRadius: BorderRadius.circular(11),
    child: SizedBox(width: width, height: height, child: child),
  );

  Widget _fallback() {
    final category = place.category.toUpperCase();
    final icon = category.contains('RESTAURANT') || category.contains('FOOD')
        ? Icons.restaurant
        : category.contains('HOTEL') || category.contains('STAY')
        ? Icons.hotel
        : category.contains('SHOP')
        ? Icons.storefront
        : category.contains('MUSEUM')
        ? Icons.museum_outlined
        : Icons.account_balance_outlined;
    return _frame(
      ColoredBox(
        color: const Color(0xFFE8E1D7),
        child: Center(
          child: Icon(icon, color: const Color(0xFF824A2B), size: 28),
        ),
      ),
    );
  }
}
