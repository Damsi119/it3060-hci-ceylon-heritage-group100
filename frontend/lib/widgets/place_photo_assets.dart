import '../models/tourism_place.dart';

/// Bundled, place-specific photos for well-known Sri Lankan heritage sites.
String? localPlacePhotoAsset(TourismPlace place) {
  final category = place.category.toLowerCase();
  if (!category.contains('heritage') &&
      !category.contains('histor') &&
      !category.contains('museum') &&
      !category.contains('education')) {
    return null;
  }

  final name = place.name.toLowerCase();
  const photos = <String, String>{
    'galle fort': 'galle_fort.png',
    'sigiriya': 'sigiriya.png',
    'white temple': 'temple_of_the_tooth.png',
    'gal vihara': 'gal_vihara.png',
    'ruwanwelisaya': 'ruwanwelisaya.png',
    'temple of the tooth': 'temple_of_the_tooth.png',
    'tooth relic': 'temple_of_the_tooth.png',
    'sri maha bodhi': 'sri_maha_bodhi.png',
    'mihintale': 'mihintale.png',
    'jethawanaramaya': 'jethawanaramaya.png',
    'thuparamaya': 'thuparamaya.png',
    'isurumuniya': 'isurumuniya.png',
    'jaffna fort': 'jaffna_fort.png',
    'lankathilaka': 'lankathilaka_temple.png',
    'rankoth vehera': 'rankoth_vehera.png',
    'parakrama samudraya': 'parakrama_samudraya.png',
    'samadhi statue': 'samadhi_statue.png',
  };

  for (final entry in photos.entries) {
    if (name.contains(entry.key)) return 'assets/images/${entry.value}';
  }
  return null;
}

List<String> localPlacePhotoGalleryAssets(TourismPlace place) {
  final name = place.name.toLowerCase();
  if (name == 'galle fort') {
    return const [
      'assets/images/galle_fort.png',
      'assets/images/galle_fort_gallery_lighthouse.png',
      'assets/images/galle_fort_gallery_ramparts.png',
      'assets/images/galle_fort_gallery_street.png',
    ];
  }
  if (name.contains('polonnaruwa')) {
    return const [
      'assets/images/polonnaruwa_details_banner.png',
      'assets/images/polonnaruwa_gallery_1.png',
      'assets/images/polonnaruwa_gallery_2.png',
      'assets/images/polonnaruwa_gallery_3.png',
      'assets/images/polonnaruwa_gallery_4.png',
      'assets/images/polonnaruwa_gallery_5.png',
      'assets/images/polonnaruwa_gallery_6.png',
    ];
  }
  final hero = localPlacePhotoAsset(place);
  return hero == null ? const [] : [hero];
}
