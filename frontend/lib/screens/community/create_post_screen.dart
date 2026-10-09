import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/constants/api_config.dart';
import '../../models/user_profile.dart';
import '../../services/api_client.dart';
import '../../services/token_store.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    super.key,
    required this.user,
    this.initialPlaceId,
    this.onHome,
    this.onExplore,
    this.onTours,
    this.onCommunity,
    this.onProfile,
  });

  final UserProfile user;
  final int? initialPlaceId;

  final VoidCallback? onHome;
  final VoidCallback? onExplore;
  final VoidCallback? onTours;
  final VoidCallback? onCommunity;
  final VoidCallback? onProfile;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  static const Color _primary = Color(0xFF9A4F2D);
  static const Color _heading = Color(0xFF3A241B);
  static const Color _muted = Color(0xFF6F6A66);
  static const Color _background = Color(0xFFFCF8F4);
  static const Color _surface = Color(0xFFF1E7DC);
  static const Color _border = Color(0xFFE7DDD5);

  static const int _maxPhotos = 5;
  static const int _maxBytes = 5 * 1024 * 1024;

  final TextEditingController _caption = TextEditingController();
  final List<_SelectedPhoto> _photos = <_SelectedPhoto>[];
  final Set<String> _tags = <String>{};

  List<Map<String, dynamic>> _places = <Map<String, dynamic>>[];
  Map<String, dynamic>? _selectedPlace;

  bool _loadingPlaces = true;
  bool _picking = false;
  bool _publishing = false;
  bool _published = false;
  bool _navigating = false;

  String? _placeError;
  String? _publishError;

  bool get _busy => _publishing || _picking;

  bool get _editable => !_busy && !_published;

  String get _baseUrl => ApiConfig.baseUrl.replaceFirst(RegExp(r'/+$'), '');

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  int _id(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _text(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadPlaces() async {
    if (!mounted) return;

    setState(() {
      _loadingPlaces = true;
      _placeError = null;
    });

    try {
      final dynamic response = await ApiClient.instance
          .get('/api/places', authenticated: false)
          .timeout(const Duration(seconds: 20));

      if (response is! List) {
        throw const FormatException('Invalid places response.');
      }

      final List<Map<String, dynamic>> places = [];

      for (final dynamic item in response) {
        if (item is! Map) continue;

        final place = Map<String, dynamic>.from(item);

        if (_id(place['id']) > 0) {
          places.add(place);
        }
      }

      places.sort((a, b) => _text(a['name']).compareTo(_text(b['name'])));

      if (!mounted) return;

      setState(() {
        _places = places;
        _loadingPlaces = false;

        if (_selectedPlace == null && widget.initialPlaceId != null) {
          for (final place in places) {
            if (_id(place['id']) == widget.initialPlaceId) {
              _selectedPlace = place;
              break;
            }
          }
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingPlaces = false;
        _placeError = 'Could not load places. Please try again.';
      });
    }
  }

  Future<void> _selectPlace() async {
    if (!_editable || _loadingPlaces) return;

    if (_places.isEmpty) {
      _message('No historical places are available yet.');
      return;
    }

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _background,
      builder: (_) => _PlacePicker(places: _places),
    );

    if (!mounted || selected == null || !_editable) return;

    setState(() {
      _selectedPlace = selected;
      _publishError = null;
    });
  }

  Future<void> _pickPhotos() async {
    if (!_editable) return;

    if (_photos.length >= _maxPhotos) {
      _message('You can add a maximum of 5 photos.');
      return;
    }

    setState(() {
      _picking = true;
      _publishError = null;
    });

    try {
      final List<PlatformFile> files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['jpg', 'jpeg', 'png'],
      );

      if (!mounted || files.isEmpty) return;

      final List<_SelectedPhoto> additions = [];
      final List<String> messages = [];

      for (final file in files) {
        if (_photos.length + additions.length >= _maxPhotos) {
          messages.add('Only 5 photos can be added.');
          break;
        }

        try {
          // Check length before loading a potentially large file into memory.
          final int length = await file.length();

          if (length > _maxBytes) {
            messages.add('${file.name}: exceeds the 5 MB limit.');
            continue;
          }

          final Uint8List bytes = await file.readAsBytes();

          if (!mounted) return;

          if (bytes.isEmpty) {
            messages.add('${file.name}: could not read the photo.');
            continue;
          }

          if (bytes.length > _maxBytes) {
            messages.add('${file.name}: exceeds the 5 MB limit.');
            continue;
          }

          final bool isPng =
              bytes.length >= 8 &&
              bytes[0] == 0x89 &&
              bytes[1] == 0x50 &&
              bytes[2] == 0x4E &&
              bytes[3] == 0x47 &&
              bytes[4] == 0x0D &&
              bytes[5] == 0x0A &&
              bytes[6] == 0x1A &&
              bytes[7] == 0x0A;

          final bool isJpeg =
              bytes.length >= 3 &&
              bytes[0] == 0xFF &&
              bytes[1] == 0xD8 &&
              bytes[2] == 0xFF;

          if (!isPng && !isJpeg) {
            messages.add('${file.name}: select a JPG or PNG image.');
            continue;
          }

          additions.add(
            _SelectedPhoto(
              bytes: bytes,
              subtype: isPng ? 'png' : 'jpeg',
              extension: isPng ? 'png' : 'jpg',
            ),
          );
        } catch (_) {
          messages.add('${file.name}: could not read the photo.');
        }
      }

      if (!mounted) return;

      if (additions.isNotEmpty) {
        setState(() {
          _photos.addAll(additions);
        });
      }

      if (messages.isNotEmpty) {
        _message(messages.join('\n'));
      }
    } catch (_) {
      _message('Could not select photos. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _picking = false;
        });
      }
    }
  }

  Future<http.Response> _upload(
    http.Client client,
    String token,
    Map<String, dynamic> post,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/posts'),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    // Spring Boot expects a JSON request part named "post".
    request.files.add(
      http.MultipartFile.fromString(
        'post',
        jsonEncode(post),
        contentType: MediaType('application', 'json'),
      ),
    );

    // Spring Boot expects all image parts to use the name "photos".
    for (int index = 0; index < _photos.length; index++) {
      final photo = _photos[index];

      request.files.add(
        http.MultipartFile.fromBytes(
          'photos',
          photo.bytes,
          filename: 'photo_${index + 1}.${photo.extension}',
          contentType: MediaType('image', photo.subtype),
        ),
      );
    }

    // MultipartRequest supplies Content-Type and its boundary automatically.
    final streamed = await client.send(request);
    return http.Response.fromStream(streamed);
  }

  Future<String?> _refreshAccessToken(http.Client client) async {
    final String? refreshToken = await TokenStore.getRefreshToken();

    if (refreshToken == null || refreshToken.trim().isEmpty) {
      return null;
    }

    final response = await client
        .post(
          Uri.parse('$_baseUrl/api/auth/refresh'),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'refreshToken': refreshToken}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

    if (decoded is! Map) return null;

    final String access = _text(decoded['accessToken']);
    final String refresh = _text(decoded['refreshToken']);

    if (access.isEmpty || refresh.isEmpty) return null;

    await TokenStore.saveTokens(access, refresh);
    return access;
  }

  String? _responseMessage(http.Response response) {
    try {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is Map) {
        for (final key in <String>['message', 'detail', 'error']) {
          final dynamic value = decoded[key];

          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  bool _shouldRefreshAccess(http.Response response) {
    if (response.statusCode == 401) return true;
    if (response.statusCode != 403) return false;

    final String message = _responseMessage(response)?.toLowerCase() ?? '';

    return message.isEmpty ||
        message == 'access denied' ||
        message.contains('authentication');
  }

  String _responseError(http.Response response) {
    final String? message = _responseMessage(response);

    if (response.statusCode == 401) {
      return 'Please sign in again before publishing.';
    }

    if (response.statusCode == 403) {
      if (message != null && message.toLowerCase() != 'access denied') {
        return message;
      }

      return 'Your account is not permitted to publish this post.';
    }

    if (response.statusCode == 413) {
      return 'The upload is too large for the server.';
    }

    if (message != null) {
      return message;
    }

    if (response.statusCode == 400) {
      return 'Please check the post details and try again.';
    }

    return 'Publishing failed (HTTP ${response.statusCode}).';
  }

  Future<void> _publish() async {
    if (!_editable) return;

    final place = _selectedPlace;
    final String caption = _caption.text.trim();

    if (place == null) {
      _message('Please select a historical place.');
      return;
    }

    final int placeId = _id(place['id']);

    if (placeId <= 0) {
      _message('The selected historical place is invalid.');
      return;
    }

    if (_photos.isEmpty) {
      _message('Please add at least one photo.');
      return;
    }

    if (_photos.length > _maxPhotos) {
      _message('You can add a maximum of 5 photos.');
      return;
    }

    if (caption.isEmpty || caption.length > 500) {
      _message('Enter a caption between 1 and 500 characters.');
      return;
    }

    if (_tags.length > 10) {
      _message('You can add a maximum of 10 tags.');
      return;
    }

    if (_tags.any((tag) => tag.trim().isEmpty || tag.length > 50)) {
      _message('Each tag must contain text and be 50 characters or less.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _publishing = true;
      _publishError = null;
    });

    final client = http.Client();

    try {
      final String? token = await TokenStore.getAccessToken();

      if (token == null || token.trim().isEmpty) {
        throw const ApiException('Please sign in before publishing.');
      }

      final Map<String, dynamic> payload = {
        'placeId': placeId,
        'caption': caption,
        'tags': _tags.toList(),
      };

      http.Response response = await _upload(
        client,
        token,
        payload,
      ).timeout(const Duration(seconds: 60));

      if (_shouldRefreshAccess(response)) {
        final String? refreshed = await _refreshAccessToken(client);

        if (refreshed != null) {
          response = await _upload(
            client,
            refreshed,
            payload,
          ).timeout(const Duration(seconds: 60));
        }
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(_responseError(response), response.statusCode);
      }

      if (!mounted) return;

      setState(() {
        _published = true;
        _publishing = false;
      });

      // Allow PopScope to rebuild before returning to the feed.
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        _message('Your post was published successfully.');
      }
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _publishError =
            'The upload timed out. Check My Posts before trying again '
            'because the server may already have received your post.';
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _publishError = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _publishError =
            'Could not confirm publication. Check your connection '
            'and My Posts before trying again.';
      });
    } finally {
      client.close();

      if (mounted) {
        setState(() {
          _publishing = false;
        });
      }
    }
  }

  void _back() {
    if (_busy || _navigating) return;

    if (Navigator.of(context).canPop()) {
      _navigating = true;
      Navigator.of(context).pop(_published);
      return;
    }

    _navigate(widget.onCommunity, 'Community');
  }

  void _navigate(VoidCallback? callback, String label) {
    if (_busy || _navigating) return;

    if (callback != null) {
      _navigating = true;

      try {
        callback();
      } finally {
        if (mounted) {
          _navigating = false;
        }
      }

      return;
    }

    if (label == 'Community' && Navigator.of(context).canPop()) {
      _navigating = true;
      Navigator.of(context).pop(_published);
      return;
    }

    _message('The $label page has not been connected yet.');
  }

  String? _placeImageUrl(Map<String, dynamic>? place) {
    if (place == null) return null;

    final List<dynamic> candidates = [
      place['imageUrl'],
      place['thumbnailUrl'],
      place['coverImageUrl'],
    ];

    final dynamic images = place['imageUrls'];

    if (images is List && images.isNotEmpty) {
      candidates.add(images.first);
    }

    for (final raw in candidates) {
      final String value = _text(raw);
      if (value.isEmpty) continue;

      final Uri? uri = Uri.tryParse(value);
      if (uri == null) continue;

      if (uri.hasScheme) {
        if (uri.scheme == 'http' || uri.scheme == 'https') {
          return uri.toString();
        }
        continue;
      }

      return Uri.parse('$_baseUrl/').resolveUri(uri).toString();
    }

    return null;
  }

  Widget _placeThumbnail(Map<String, dynamic>? place) {
    final String? imageUrl = _placeImageUrl(place);

    Widget fallback() {
      return const ColoredBox(
        color: _surface,
        child: Center(child: Icon(Icons.account_balance, color: _primary)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 70,
        height: 58,
        child: imageUrl == null
            ? fallback()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback(),
              ),
      ),
    );
  }

  Widget _sectionTitle(String text, {String? optional}) {
    return Wrap(
      spacing: 6,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          text,
          style: GoogleFonts.playfairDisplay(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            color: _heading,
          ),
        ),
        if (optional != null)
          Text(
            optional,
            style: GoogleFonts.playfairDisplay(fontSize: 16, color: _muted),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return PopScope(
      canPop: !_busy,
      child: Theme(
        data: theme.copyWith(
          textTheme: GoogleFonts.interTextTheme(theme.textTheme),
          colorScheme: theme.colorScheme.copyWith(
            primary: _primary,
            surface: _background,
          ),
        ),
        child: Scaffold(
          backgroundColor: _background,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _topHeader(),
                      const SizedBox(height: 22),
                      Text(
                        'Create Post',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 30,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: _heading,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Share your experience with the community',
                        style: TextStyle(color: _muted, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Select Historical Place'),
                      const SizedBox(height: 9),
                      _placeCard(),
                      const SizedBox(height: 16),
                      _sectionTitle('Add Photos'),
                      const SizedBox(height: 10),
                      _photoGrid(),
                      const SizedBox(height: 18),
                      _sectionTitle('Write a Caption'),
                      const SizedBox(height: 9),
                      _captionField(),
                      const SizedBox(height: 14),
                      _sectionTitle('Add Tags', optional: '(Optional)'),
                      const SizedBox(height: 10),
                      _tagChips(),
                      if (_publishError != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDED),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _publishError ?? '',
                            style: const TextStyle(
                              color: Color(0xFFB42318),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 38),
                      _shareButton(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topHeader() {
    return Row(
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 1,
          child: IconButton(
            tooltip: 'Back',
            onPressed: _busy ? null : _back,
            icon: const Icon(Icons.chevron_left, color: _primary, size: 27),
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.spa, color: _primary, size: 34),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CEYLON HERITAGE',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _heading,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'EXPLORE · DISCOVER · PRESERVE',
                style: TextStyle(
                  color: _primary,
                  letterSpacing: 0.8,
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeCard() {
    if (_loadingPlaces) {
      return Container(
        height: 72,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
        ),
      );
    }

    if (_placeError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _placeError ?? '',
                style: const TextStyle(fontSize: 13, color: _muted),
              ),
            ),
            TextButton(
              onPressed: _editable ? _loadPlaces : null,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final place = _selectedPlace;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _editable ? _selectPlace : null,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              _placeThumbnail(place),
              const SizedBox(width: 9),
              Expanded(
                child: place == null
                    ? const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select a historical place',
                            style: TextStyle(
                              color: _heading,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap to choose a place',
                            style: TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _text(place['name']),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.playfairDisplay(
                              color: _heading,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: _primary,
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _text(place['city']).isEmpty
                                      ? 'Sri Lanka'
                                      : '${_text(place['city'])}, Sri Lanka',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              const Icon(Icons.chevron_right, color: _primary, size: 25),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (int index = 0; index < _photos.length; index++)
              SizedBox(
                width: itemWidth,
                height: 155,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.memory(
                        _photos[index].bytes,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const ColoredBox(
                            color: _surface,
                            child: Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: _muted,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          tooltip: 'Remove photo',
                          onPressed: _editable
                              ? () {
                                  setState(() {
                                    _photos.removeAt(index);
                                    _publishError = null;
                                  });
                                }
                              : null,
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_photos.length < _maxPhotos)
              SizedBox(
                width: itemWidth,
                height: 155,
                child: Material(
                  color: const Color(0xFFFFFBF8),
                  borderRadius: BorderRadius.circular(7),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(7),
                    onTap: _editable ? _pickPhotos : null,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: const Color(0xFFE2CEC0)),
                      ),
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_picking)
                                const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    color: _primary,
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: _primary,
                                  size: 40,
                                ),
                              const SizedBox(height: 9),
                              Text(
                                _picking ? 'Selecting...' : 'Tap to add photos',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'JPG, PNG · Max 5 MB each',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: _muted, fontSize: 11),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${_photos.length}/$_maxPhotos photos',
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _captionField() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: _border),
    );

    return TextField(
      controller: _caption,
      enabled: _editable,
      maxLength: 500,
      minLines: 4,
      maxLines: 6,
      style: const TextStyle(color: _heading, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Share your experience, thoughts or memories...',
        hintStyle: const TextStyle(color: Color(0xFF8290A2), fontSize: 12),
        filled: true,
        fillColor: Colors.white,
        counterStyle: const TextStyle(color: _muted, fontSize: 12),
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: _primary),
        ),
      ),
    );
  }

  Widget _tagChips() {
    const List<String> availableTags = [
      'History',
      'Culture',
      'SriLanka',
      'TravelDiaries',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tag in availableTags)
          FilterChip(
            showCheckmark: false,
            label: Text('#$tag'),
            selected: _tags.contains(tag),
            backgroundColor: const Color(0xFFF5E8E0),
            selectedColor: const Color(0xFFE4C5B2),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            labelStyle: const TextStyle(
              color: _primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            onSelected: _editable
                ? (selected) {
                    setState(() {
                      if (selected) {
                        _tags.add(tag);
                      } else {
                        _tags.remove(tag);
                      }
                      _publishError = null;
                    });
                  }
                : null,
          ),
      ],
    );
  }

  Widget _shareButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB99784),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _editable ? _publish : null,
        child: _publishing
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text('Publishing...'),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _published ? 'Published' : 'Share',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!_published) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ],
              ),
      ),
    );
  }
}

class _SelectedPhoto {
  const _SelectedPhoto({
    required this.bytes,
    required this.subtype,
    required this.extension,
  });

  final Uint8List bytes;
  final String subtype;
  final String extension;
}

class _PlacePicker extends StatefulWidget {
  const _PlacePicker({required this.places});

  final List<Map<String, dynamic>> places;

  @override
  State<_PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<_PlacePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final String query = _query.trim().toLowerCase();

    final results = widget.places.where((place) {
      final String name = place['name']?.toString().toLowerCase() ?? '';
      final String city = place['city']?.toString().toLowerCase() ?? '';

      return name.contains(query) || city.contains(query);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;

        final double keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

        final double height = (availableHeight - keyboardHeight)
            .clamp(0.0, availableHeight)
            .toDouble();

        return Padding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: SizedBox(
            height: height * 0.85,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5CCC5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                ListTile(
                  title: Text(
                    'Select Historical Place',
                    style: GoogleFonts.playfairDisplay(
                      color: _CreatePostScreenState._heading,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _query = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search places or cities...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: _CreatePostScreenState._border,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: results.isEmpty
                      ? const Center(child: Text('No places found.'))
                      : ListView.separated(
                          itemCount: results.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final place = results[index];

                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor:
                                    _CreatePostScreenState._surface,
                                child: Icon(
                                  Icons.account_balance,
                                  color: _CreatePostScreenState._primary,
                                ),
                              ),
                              title: Text(place['name']?.toString() ?? ''),
                              subtitle: Text(place['city']?.toString() ?? ''),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: _CreatePostScreenState._primary,
                              ),
                              onTap: () {
                                Navigator.pop<Map<String, dynamic>>(
                                  context,
                                  place,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
