import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/api_config.dart';
import '../../services/api_client.dart';

class HistoricalPlaceDetailsScreen extends StatefulWidget {
  const HistoricalPlaceDetailsScreen({
    super.key,
    required this.placeId,
    this.initialPlace,
    this.onAddToTour,
    this.isAddedToTour = false,
  });

  final int placeId;
  final Map<String, dynamic>? initialPlace;
  final VoidCallback? onAddToTour;
  final bool isAddedToTour;

  @override
  State<HistoricalPlaceDetailsScreen> createState() =>
      _HistoricalPlaceDetailsScreenState();
}

class _HistoricalPlaceDetailsScreenState
    extends State<HistoricalPlaceDetailsScreen> {
  static const _background = Color(0xFFFCF8F4);
  static const _primary = Color(0xFF9A4F2D);
  static const _heading = Color(0xFF3A241B);
  static const _muted = Color(0xFF6F6A66);
  static const _surface = Color(0xFFF1E7DC);

  final PageController _pageController = PageController();

  Map<String, dynamic>? _place;
  bool _loading = true;
  bool _failed = false;
  bool _added = false;
  int _currentImage = 0;
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();
    _place = widget.initialPlace == null
        ? null
        : Map<String, dynamic>.from(widget.initialPlace!);
    _added = widget.isAddedToTour;
    _loadPlace();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPlace() async {
    if (!mounted) return;
    final version = ++_requestVersion;

    setState(() {
      _loading = true;
      _failed = false;
    });

    try {
      final response = await ApiClient.instance
          .get(
        '/api/places/${widget.placeId}',
        authenticated: false,
      )
          .timeout(const Duration(seconds: 20));

      if (response is! Map) {
        throw const FormatException('Invalid place response.');
      }

      if (!mounted || version != _requestVersion) return;

      setState(() {
        _place = Map<String, dynamic>.from(response);
        _currentImage = 0;
        _loading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || version != _requestVersion) return;

        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    } catch (_) {
      if (!mounted || version != _requestVersion) return;

      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  String _text(String key) =>
      _place?[key]?.toString().trim() ?? '';

  double? get _rating {
    final value = _place?['rating'];

    return value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
  }

  int get _reviewCount {
    final value = _place?['reviewCount'];

    return value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String get _category {
    const labels = {
      'ANCIENT_CITY': 'Ancient City',
      'TEMPLE': 'Temple',
      'FORT': 'Fort',
      'MUSEUM': 'Museum',
      'ARCHAEOLOGICAL_SITE': 'Archaeological Site',
    };

    final value = _text('category');

    return labels[value.toUpperCase()] ??
        value.replaceAll('_', ' ');
  }

  String get _duration {
    final duration = _text('visitDuration');
    if (duration.isNotEmpty) return duration;

    final value = _place?['visitDurationMinutes'];

    final minutes = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '');

    if (minutes == null || minutes <= 0) return '';
    if (minutes < 60) return '$minutes min';

    final hours = minutes ~/ 60;
    final remainder = minutes % 60;

    return remainder == 0
        ? '$hours hr'
        : '$hours hr $remainder min';
  }

  String? get _localHero {
    final name = _text('name').toLowerCase();

    const assets = {
      'gal vihara': 'gal_vihara.png',
      'rankoth': 'rankoth_vehera.png',
      'lankathilaka': 'lankathilaka_temple.png',
      'lankatilaka': 'lankathilaka_temple.png',
      'parakrama': 'parakrama_samudraya.png',
      'ruwan': 'ruwanwelisaya.png',
      'galle': 'galle_fort.png',
      'sigiriya': 'sigiriya.png',
      'tooth': 'temple_of_the_tooth.png',
      'jaffna': 'jaffna_fort.png',
      'mihintale': 'mihintale.png',
    };

    if (name.contains('polonnaruwa')) {
      return 'assets/images/polonnaruwa_details_banner.png';
    }

    for (final entry in assets.entries) {
      if (name.contains(entry.key)) {
        return 'assets/images/${entry.value}';
      }
    }

    return null;
  }

  String? _resolveImageUrl(String source) {
    final value = source.trim();
    if (value.isEmpty) return null;

    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    final baseUrl = ApiConfig.baseUrl.replaceFirst(
      RegExp(r'/+$'),
      '',
    );

    final resolved = uri.hasScheme
        ? uri
        : Uri.parse('$baseUrl/').resolveUri(uri);

    if (resolved.scheme != 'http' &&
        resolved.scheme != 'https') {
      return null;
    }

    return resolved.toString();
  }

  List<String> get _images {
    final name = _text('name').toLowerCase();

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

    final images = <String>[];
    final localHero = _localHero;

    if (localHero != null) {
      images.add(localHero);
    } else {
      final hero = _resolveImageUrl(_text('imageUrl'));
      if (hero != null) images.add(hero);
    }

    final gallery = _place?['galleryImages'];

    if (gallery is List) {
      for (final item in gallery) {
        if (item is! String) continue;

        final url = _resolveImageUrl(item);

        if (url != null && !images.contains(url)) {
          images.add(url);
        }
      }
    }

    return images;
  }

  Widget _imagePlaceholder() {
    return const ColoredBox(
      color: _surface,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: _muted,
          size: 36,
        ),
      ),
    );
  }

  Widget _image(String source, {BoxFit fit = BoxFit.cover}) {
    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            _imagePlaceholder(),
      );
    }

    return Image.network(
      source,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;

        return const ColoredBox(
          color: _surface,
          child: Center(
            child: CircularProgressIndicator(
              color: _primary,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) =>
          _imagePlaceholder(),
    );
  }

  void _changeImage(int index) {
    if (!_pageController.hasClients) return;
    if (index < 0 || index >= _images.length) return;

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _addToTour() {
    final callback = widget.onAddToTour;

    if (callback == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Open this page from Explore to select this place for a tour.',
          ),
        ),
      );
      return;
    }

    callback();

    if (!mounted ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }

    setState(() => _added = !_added);
  }

  Future<void> _openGallery(
      List<String> images,
      int index,
      ) async {
    if (images.isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _PlaceGalleryDialog(
        images: images,
        initialIndex: index,
        imageBuilder: (source) =>
            _image(source, fit: BoxFit.contain),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: _background,
        textTheme: GoogleFonts.interTextTheme(theme.textTheme),
      ),
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _background,
          foregroundColor: _heading,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Historical Place Details',
            style: TextStyle(fontSize: 18),
          ),
        ),
        body: _buildBody(),

        // Scaffold reserves space for this button below the body.
        bottomNavigationBar: _place == null
            ? null
            : ColoredBox(
          color: _background,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16, 10, 16, 12,
              ),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _addToTour,
                icon: Icon(
                  _added ? Icons.remove : Icons.add,
                ),
                label: Text(
                  _added
                      ? 'Remove from Tour'
                      : 'Add to Tour',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _place == null) {
      return const Center(
        child: CircularProgressIndicator(color: _primary),
      );
    }

    if (_place == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 44,
                color: _muted,
              ),
              const SizedBox(height: 16),
              const Text(
                'Could not load this place.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                ),
                onPressed: _loadPlace,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final images = _images;
    final rating = _rating;

    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadPlace,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_loading)
                  const LinearProgressIndicator(
                    color: _primary,
                    backgroundColor: _surface,
                  ),
                if (_failed)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Could not refresh. Showing previously loaded details.',
                            style: TextStyle(color: _muted),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadPlace,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                _hero(images),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16, 16, 16, 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _text('name').isEmpty
                            ? 'Historical Place'
                            : _text('name'),
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                          color: _heading,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_text('city').isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: _primary,
                              size: 18,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '${_text('city')}, Sri Lanka',
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (rating != null &&
                          rating > 0 &&
                          _reviewCount > 0) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          crossAxisAlignment:
                          WrapCrossAlignment.center,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFFFFAD00),
                              size: 19,
                            ),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '($_reviewCount reviews)',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_category.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Chip(
                          label: Text(
                            _category,
                            style: const TextStyle(
                              color: _primary,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: _surface,
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                      const SizedBox(height: 16),
                      _information(),
                      const SizedBox(height: 24),
                      _sectionTitle('About'),
                      const SizedBox(height: 10),
                      Text(
                        _text('description').isEmpty
                            ? 'A description has not been provided yet.'
                            : _text('description'),
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: _muted,
                        ),
                      ),
                      if (images.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _sectionTitle('Gallery'),
                        const SizedBox(height: 12),
                        _gallery(images),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero(List<String> images) {
    if (images.isEmpty) {
      return SizedBox(
        height: 260,
        width: double.infinity,
        child: _imagePlaceholder(),
      );
    }

    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() => _currentImage = index);
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openGallery(images, index),
                child: _image(images[index]),
              );
            },
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_currentImage + 1} / ${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (images.length > 1)
            Positioned(
              right: 8,
              bottom: 8,
              child: Row(
                children: [
                  _arrow(
                    icon: Icons.chevron_left,
                    tooltip: 'Previous image',
                    onPressed: () => _changeImage(
                      (_currentImage - 1 + images.length) %
                          images.length,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _arrow(
                    icon: Icons.chevron_right,
                    tooltip: 'Next image',
                    onPressed: () => _changeImage(
                      (_currentImage + 1) % images.length,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _arrow({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton.filled(
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black45,
        foregroundColor: Colors.white,
      ),
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: _heading,
      ),
    );
  }

  Widget _information() {
    // Values come from the place response.
    // Missing values are omitted rather than replaced with defaults.
    final items = <Widget>[
      if (_duration.isNotEmpty)
        _infoCard(
          Icons.schedule_outlined,
          _duration,
          'Visit duration',
        ),
      if (_text('bestTimeToVisit').isNotEmpty)
        _infoCard(
          Icons.wb_sunny_outlined,
          _text('bestTimeToVisit'),
          'Best time to visit',
        ),
      if (_text('entryFee').isNotEmpty)
        _infoCard(
          Icons.confirmation_number_outlined,
          _text('entryFee'),
          'Entry fee',
        ),
      if (_text('accessibility').isNotEmpty)
        _infoCard(
          Icons.accessible_outlined,
          _text('accessibility'),
          'Accessibility',
        ),
      if (_text('openingHours').isNotEmpty)
        _infoCard(
          Icons.access_time_outlined,
          _text('openingHours'),
          'Opening hours',
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 3 : 2;
        final width =
            (constraints.maxWidth - (columns - 1) * 10) / columns;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in items)
              SizedBox(width: width, child: item),
          ],
        );
      },
    );
  }

  Widget _infoCard(
      IconData icon,
      String value,
      String label,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primary, size: 23),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: _heading,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gallery(List<String> images) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (context, index) =>
        const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _changeImage(index),
            onLongPress: () => _openGallery(images, index),
            child: Container(
              width: 85,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _currentImage == index
                      ? _primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: _image(images[index]),
            ),
          );
        },
      ),
    );
  }
}

class _PlaceGalleryDialog extends StatefulWidget {
  const _PlaceGalleryDialog({
    required this.images,
    required this.initialIndex,
    required this.imageBuilder,
  });

  final List<String> images;
  final int initialIndex;
  final Widget Function(String source) imageBuilder;

  @override
  State<_PlaceGalleryDialog> createState() =>
      _PlaceGalleryDialogState();
}

class _PlaceGalleryDialogState extends State<_PlaceGalleryDialog> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() => _index = index);
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: widget.imageBuilder(
                      widget.images[index],
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                tooltip: 'Close gallery',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${_index + 1} / ${widget.images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}