import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/api_config.dart';
import '../../models/user_profile.dart';
import '../../services/api_client.dart';
import '../../widgets/notification_badge.dart';
import 'create_post_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ceylon Heritage',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9A4F2D)),
      ),
      home: const CommunityFeedScreen(),
    ),
  );
}

const _primary = Color(0xFF9A4F2D);
const _heading = Color(0xFF3A241B);
const _muted = Color(0xFF6F6A66);
const _background = Color(0xFFFCF8F4);
const _surface = Color(0xFFF1E7DC);

int _number(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _text(dynamic value) => value?.toString().trim() ?? '';

String _errorMessage(Object error) {
  if (error is ApiException) {
    if (error.statusCode == 401) {
      return 'Your session has expired. Please sign in again.';
    }
    if (error.statusCode == 403) {
      return 'You do not have permission for this action.';
    }
    return error.message;
  }

  if (error is TimeoutException) {
    return 'The request timed out. Please try again.';
  }

  return 'Could not connect. Check the backend connection and try again.';
}

String? _photoUrl(String source) {
  final value = source.trim();

  if (value.isEmpty) return null;

  final uri = Uri.tryParse(value);

  if (uri == null) return null;

  final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/+$'), '');

  final resolved = uri.hasScheme ? uri : Uri.parse('$base/').resolveUri(uri);

  if (resolved.scheme != 'http' && resolved.scheme != 'https') {
    return null;
  }

  return resolved.toString();
}

String _timeLabel(String source) {
  final date = DateTime.tryParse(source);

  if (date == null) return '';

  final difference = DateTime.now().difference(date.toLocal());

  if (difference.isNegative || difference.inMinutes < 1) {
    return 'Just now';
  }

  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} min ago';
  }

  if (difference.inHours < 24) {
    return '${difference.inHours} hr ago';
  }

  if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  }

  return '${date.day}/${date.month}/${date.year}';
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) return '?';

  return parts.take(2).map((part) => part.substring(0, 1)).join().toUpperCase();
}

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({
    super.key,
    this.user,
    this.onHome,
    this.onExplore,
    this.onTours,
    this.onProfile,
    this.onNotifications,
    this.onSignIn,
    this.onCreatePost,
    this.onPlaceSelected,
  });

  final UserProfile? user;
  final VoidCallback? onHome;
  final VoidCallback? onExplore;
  final VoidCallback? onTours;
  final VoidCallback? onProfile;
  final VoidCallback? onNotifications;
  final VoidCallback? onSignIn;

  final Future<void> Function()? onCreatePost;
  final ValueChanged<int>? onPlaceSelected;

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  List<Map<String, dynamic>> _posts = [];

  final Set<int> _busyPosts = {};

  int _tab = 0;
  int _requestVersion = 0;

  bool _loading = true;
  bool _creating = false;

  String? _error;

  bool get _signedIn => widget.user != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CommunityFeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.user?.id != widget.user?.id) {
      if (!_signedIn && _tab == 2) {
        _tab = 0;
      }

      _load();
    }
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _requireLogin() {
    if (_signedIn) {
      return true;
    }

    _message('Please sign in to use this feature.');

    widget.onSignIn?.call();

    return false;
  }

  Future<void> _load() async {
    final version = ++_requestVersion;

    setState(() {
      _loading = true;
      _error = null;
    });

    final path = switch (_tab) {
      1 => '/api/posts/recent',
      2 => '/api/posts/my',
      _ => '/api/posts',
    };

    try {
      final response = await ApiClient.instance
          .get(path, authenticated: _signedIn)
          .timeout(const Duration(seconds: 20));

      if (response is! List) {
        throw const FormatException('Invalid posts response.');
      }

      final posts = response.map((item) {
        if (item is! Map) {
          throw const FormatException('Invalid post.');
        }

        final post = Map<String, dynamic>.from(item);

        if (_number(post['id']) <= 0) {
          throw const FormatException('Invalid post ID.');
        }

        return post;
      }).toList();

      if (!mounted || version != _requestVersion) {
        return;
      }

      setState(() {
        _posts = posts;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || version != _requestVersion) {
        return;
      }

      setState(() {
        _loading = false;
        _error = _errorMessage(error);
      });
    }
  }

  void _selectTab(int value) {
    if (value == 2 && !_requireLogin()) {
      return;
    }

    if (value == _tab) {
      return;
    }

    setState(() {
      _tab = value;
      _posts = [];
    });

    _load();
  }

  Future<void> _like(Map<String, dynamic> post) async {
    if (!_requireLogin()) {
      return;
    }

    final id = _number(post['id']);

    if (_busyPosts.contains(id)) {
      return;
    }

    setState(() {
      _busyPosts.add(id);
    });

    try {
      final liked = post['likedByCurrentUser'] == true;

      final response =
          await (liked
                  ? ApiClient.instance.delete('/api/posts/$id/like')
                  : ApiClient.instance.post('/api/posts/$id/like'))
              .timeout(const Duration(seconds: 20));

      if (response is! Map) {
        throw const FormatException('Invalid like response.');
      }

      if (!mounted) return;

      setState(() {
        post['likeCount'] = _number(response['likeCount']);

        post['likedByCurrentUser'] = response['likedByCurrentUser'] == true;
      });
    } catch (error) {
      _message(_errorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _busyPosts.remove(id);
        });
      }
    }
  }

  Future<void> _delete(Map<String, dynamic> post) async {
    if (!_requireLogin()) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text(
          'This will permanently delete your post and its photos.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) {
      return;
    }

    final id = _number(post['id']);

    if (_busyPosts.contains(id)) {
      return;
    }

    setState(() {
      _busyPosts.add(id);
    });

    try {
      await ApiClient.instance
          .delete('/api/posts/$id')
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      setState(() {
        _posts.removeWhere((item) => _number(item['id']) == id);
      });

      _message('Post deleted.');
    } catch (error) {
      _message(_errorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _busyPosts.remove(id);
        });
      }
    }
  }

  Future<void> _edit(Map<String, dynamic> post) async {
    if (!_requireLogin()) {
      return;
    }

    final updated = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EditPostDialog(post: post),
    );

    if (!mounted || updated == null) {
      return;
    }

    final id = _number(updated['id']);

    setState(() {
      final index = _posts.indexWhere((item) => _number(item['id']) == id);

      if (index >= 0) {
        _posts[index] = updated;
      }
    });

    _message('Post updated.');
  }

  Future<void> _comments(Map<String, dynamic> post) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _background,
      builder: (_) => _CommentsSheet(
        postId: _number(post['id']),
        user: widget.user,
        onSignIn: widget.onSignIn,
      ),
    );

    if (mounted) {
      await _load();
    }
  }

  Future<void> _createPost() async {
    if (_creating || !_requireLogin()) {
      return;
    }

    setState(() {
      _creating = true;
    });

    try {
      final callback = widget.onCreatePost;

      if (callback != null) {
        await callback();

        if (mounted) {
          await _load();
        }

        return;
      }

      final published = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => CreatePostScreen(user: widget.user!),
        ),
      );

      if (!mounted) {
        return;
      }

      if (published == true) {
        await _load();

        _message('Your post was published successfully.');
      }
    } catch (error) {
      _message(_errorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _creating = false;
        });
      }
    }
  }

  void _navigate(VoidCallback? callback, String label) {
    if (callback != null) {
      callback();
    } else if (label == 'Home' && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      _message('The $label page has not been connected yet.');
    }
  }

  List<String> _images(Map<String, dynamic> post) {
    final raw = post['imageUrls'];

    if (raw is! List) {
      return [];
    }

    return raw
        .whereType<String>()
        .map(_photoUrl)
        .whereType<String>()
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        textTheme: GoogleFonts.interTextTheme(theme.textTheme),
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: _primary,
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 95),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _header(),
                          const SizedBox(height: 18),
                          Text(
                            'Community',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: _heading,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Share. Discover. Celebrate our heritage.',
                            style: TextStyle(color: _muted, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          _tabs(),
                          const SizedBox(height: 12),
                          _banner(),
                          const SizedBox(height: 12),
                          if (_loading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _primary,
                                ),
                              ),
                            )
                          else if (_error != null)
                            _emptyState(
                              Icons.cloud_off_outlined,
                              _error!,
                              retry: true,
                            )
                          else if (_posts.isEmpty)
                            _emptyState(
                              Icons.forum_outlined,
                              _tab == 2
                                  ? 'You have not published any posts yet.'
                                  : 'No posts to display yet.',
                            )
                          else
                            for (final post in _posts) ...[
                              _postCard(post),
                              const SizedBox(height: 12),
                            ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          onPressed: _creating ? null : _createPost,
          icon: _creating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.add),
          label: const Text('Create Post'),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 3,
          backgroundColor: Colors.white,
          indicatorColor: _surface,
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                _navigate(widget.onHome, 'Home');
                break;

              case 1:
                _navigate(widget.onExplore, 'Explore');
                break;

              case 2:
                if (widget.onTours != null) {
                  _navigate(widget.onTours, 'Tours');
                } else {
                  _navigate(widget.onNotifications, 'Alerts');
                }
                break;

              case 4:
                _navigate(widget.onProfile, 'Profile');
                break;
            }
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.search),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Icon(
                widget.onTours == null
                    ? Icons.notifications_none_outlined
                    : Icons.add_circle_outline,
              ),
              label: widget.onTours == null ? 'Alerts' : 'Tours',
            ),
            const NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              label: 'Community',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const Icon(Icons.spa, color: _primary, size: 34),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CEYLON HERITAGE',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _heading,
                ),
              ),
              const Text(
                'EXPLORE · DISCOVER · PRESERVE',
                style: TextStyle(
                  fontSize: 7,
                  letterSpacing: 1.2,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () {
            if (_requireLogin()) {
              _navigate(widget.onNotifications, 'Notifications');
            }
          },
          icon: const NotificationBadge(
            child: Icon(Icons.notifications_none, color: _heading),
          ),
        ),
      ],
    );
  }

  Widget _tabs() {
    const labels = ['All', 'Recent', 'My Posts'];

    return Row(
      children: [
        for (int index = 0; index < labels.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: index == _tab ? _primary : _surface,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  _selectTab(index);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: index == _tab ? Colors.white : _heading,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _banner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.groups, size: 36, color: _primary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A community for heritage lovers',
                  style: TextStyle(
                    color: _heading,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Share your experiences, photos and stories from Sri Lanka's historical places.",
                  style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String message, {bool retry = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 42, color: _muted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted),
            ),
            if (retry) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _postCard(Map<String, dynamic> post) {
    final id = _number(post['id']);

    final author = _text(post['authorName']);

    final owner = _signedIn && widget.user!.id == _number(post['authorId']);

    final busy = _busyPosts.contains(id);

    final photos = _images(post);

    final rawTags = post['tags'];

    final tags = rawTags is List
        ? rawTags
              .whereType<String>()
              .where((tag) => tag.trim().isNotEmpty)
              .toList()
        : <String>[];

    final liked = post['likedByCurrentUser'] == true;

    final time = _timeLabel(_text(post['createdAt']));

    final placeName = _text(post['placeName']);

    final placeCity = _text(post['placeCity']);

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEAE3DC)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _surface,
                  foregroundColor: _primary,
                  child: Text(_initials(author)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author.isEmpty ? 'Community member' : author,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _heading,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (time.isNotEmpty) ...[
                            Text(
                              '$time · ',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                          const Icon(Icons.public, size: 12, color: _muted),
                          const SizedBox(width: 3),
                          const Text(
                            'Public',
                            style: TextStyle(color: _muted, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (owner)
                  PopupMenuButton<String>(
                    enabled: !busy,
                    tooltip: 'Post options',
                    onSelected: (value) {
                      if (value == 'edit') {
                        _edit(post);
                      } else {
                        _delete(post);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit post')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete post'),
                      ),
                    ],
                  ),
              ],
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(color: _primary),
              ),
            if (photos.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 210,
                      width: double.infinity,
                      child: PageView.builder(
                        itemCount: photos.length,
                        itemBuilder: (_, index) {
                          return GestureDetector(
                            onTap: () {
                              showDialog<void>(
                                context: context,
                                builder: (_) => _PhotoDialog(
                                  photos: photos,
                                  initialIndex: index,
                                ),
                              );
                            },
                            child: _NetworkPhoto(url: photos[index]),
                          );
                        },
                      ),
                    ),
                    if (placeName.isNotEmpty)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        left: 40,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Material(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: widget.onPlaceSelected == null
                                  ? null
                                  : () {
                                      final placeId = _number(post['placeId']);

                                      if (placeId > 0) {
                                        widget.onPlaceSelected!(placeId);
                                      }
                                    },
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  placeCity.isEmpty
                                      ? placeName
                                      : '$placeName\n$placeCity',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (photos.length > 1)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          color: Colors.black54,
                          child: Text(
                            '${photos.length} photos · swipe',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              _text(post['caption']),
              style: const TextStyle(
                color: _heading,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in tags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag.startsWith('#') ? tag : '#$tag',
                        style: const TextStyle(color: _primary, fontSize: 10),
                      ),
                    ),
                ],
              ),
            ],
            Row(
              children: [
                IconButton(
                  tooltip: liked ? 'Unlike' : 'Like',
                  onPressed: busy
                      ? null
                      : () {
                          _like(post);
                        },
                  icon: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? Colors.redAccent : _primary,
                  ),
                ),
                Text(
                  '${_number(post['likeCount'])}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Comments',
                  onPressed: () {
                    _comments(post);
                  },
                  icon: const Icon(Icons.chat_bubble_outline, color: _heading),
                ),
                Text(
                  '${_number(post['commentCount'])}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkPhoto extends StatelessWidget {
  const _NetworkPhoto({required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (_, child, progress) {
        if (progress == null) {
          return child;
        }

        return const ColoredBox(
          color: _surface,
          child: Center(child: CircularProgressIndicator(color: _primary)),
        );
      },
      errorBuilder: (_, error, stackTrace) {
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
      },
    );
  }
}

class _PhotoDialog extends StatefulWidget {
  const _PhotoDialog({required this.photos, required this.initialIndex});

  final List<String> photos;
  final int initialIndex;

  @override
  State<_PhotoDialog> createState() => _PhotoDialogState();
}

class _PhotoDialogState extends State<_PhotoDialog> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();

    _controller = PageController(initialPage: widget.initialIndex);
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
              itemCount: widget.photos.length,
              itemBuilder: (_, index) {
                return InteractiveViewer(
                  maxScale: 4,
                  child: Center(
                    child: _NetworkPhoto(
                      url: widget.photos[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton.filled(
                tooltip: 'Close photo',
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditPostDialog extends StatefulWidget {
  const _EditPostDialog({required this.post});

  final Map<String, dynamic> post;

  @override
  State<_EditPostDialog> createState() => _EditPostDialogState();
}

class _EditPostDialogState extends State<_EditPostDialog> {
  late final TextEditingController _caption;

  late final TextEditingController _tags;

  bool _saving = false;

  String? _error;

  @override
  void initState() {
    super.initState();

    _caption = TextEditingController(text: _text(widget.post['caption']));

    final tags = widget.post['tags'];

    _tags = TextEditingController(
      text: tags is List ? tags.whereType<String>().join(', ') : '',
    );
  }

  @override
  void dispose() {
    _caption.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    final caption = _caption.text.trim();

    final tags = _tags.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();

    if (caption.isEmpty || caption.length > 500) {
      setState(() {
        _error = 'Enter a caption between 1 and 500 characters.';
      });

      return;
    }

    if (tags.length > 10 || tags.any((tag) => tag.length > 50)) {
      setState(() {
        _error = 'Use up to 10 tags, each up to 50 characters.';
      });

      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final id = _number(widget.post['id']);

      final response = await ApiClient.instance
          .put('/api/posts/$id', body: {'caption': caption, 'tags': tags})
          .timeout(const Duration(seconds: 20));

      if (response is! Map) {
        throw const FormatException('Invalid updated post.');
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, Map<String, dynamic>.from(response));
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = _errorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: const Text('Edit post'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _caption,
                enabled: !_saving,
                maxLength: 500,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Caption'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tags,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'Polonnaruwa, Heritage',
                  helperText: 'Separate tags with commas.',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving
                ? null
                : () {
                    Navigator.pop(context);
                  },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({
    required this.postId,
    required this.user,
    this.onSignIn,
  });

  final int postId;
  final UserProfile? user;
  final VoidCallback? onSignIn;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _input = TextEditingController();

  final List<Map<String, dynamic>> _comments = [];

  final Set<int> _deleting = {};

  bool _loading = false;
  bool _sending = false;
  bool _hasMore = true;

  int _nextPage = 0;

  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) {
      return;
    }

    if (reset) {
      _comments.clear();
      _nextPage = 0;
      _hasMore = true;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiClient.instance
          .get(
            '/api/posts/${widget.postId}/comments'
            '?page=$_nextPage&size=20',
            authenticated: false,
          )
          .timeout(const Duration(seconds: 20));

      if (response is! Map || response['content'] is! List) {
        throw const FormatException('Invalid comments response.');
      }

      final items = (response['content'] as List).map((item) {
        if (item is! Map) {
          throw const FormatException('Invalid comment.');
        }

        return Map<String, dynamic>.from(item);
      }).toList();

      if (!mounted) {
        return;
      }

      setState(() {
        final ids = _comments.map((item) => _number(item['id'])).toSet();

        _comments.addAll(
          items.where((item) => !ids.contains(_number(item['id']))),
        );

        _nextPage++;

        _hasMore = response['last'] == false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = _errorMessage(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _send() async {
    if (_sending || _loading) {
      return;
    }

    final content = _input.text.trim();

    if (content.isEmpty) {
      return;
    }

    if (widget.user == null) {
      setState(() {
        _error = 'Please sign in to comment.';
      });

      widget.onSignIn?.call();

      return;
    }

    if (content.length > 1000) {
      setState(() {
        _error = 'Use up to 1000 characters.';
      });

      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await ApiClient.instance
          .post(
            '/api/posts/${widget.postId}/comments',
            body: {'content': content},
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) {
        return;
      }

      _input.clear();

      await _load(reset: true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = _errorMessage(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _deleteComment(Map<String, dynamic> comment) async {
    final id = _number(comment['id']);

    if (_deleting.contains(id)) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete comment?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() {
      _deleting.add(id);
    });

    try {
      await ApiClient.instance
          .delete('/api/posts/${widget.postId}/comments/$id')
          .timeout(const Duration(seconds: 20));

      if (!mounted) {
        return;
      }

      setState(() {
        _comments.removeWhere((item) => _number(item['id']) == id);
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = _errorMessage(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _deleting.remove(id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            ListTile(
              title: const Text(
                'Comments',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: IconButton(
                tooltip: 'Close comments',
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              _load();
                            },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  if (_comments.isEmpty && !_loading && _error == null)
                    const Padding(
                      padding: EdgeInsets.all(30),
                      child: Text(
                        'No comments yet.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (final comment in _comments)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: _surface,
                        foregroundColor: _primary,
                        child: Text(_initials(_text(comment['authorName']))),
                      ),
                      title: Text(
                        _text(comment['authorName']),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_text(comment['content'])),
                          const SizedBox(height: 4),
                          Text(
                            _timeLabel(_text(comment['createdAt'])),
                            style: const TextStyle(fontSize: 10, color: _muted),
                          ),
                        ],
                      ),
                      trailing: widget.user?.id == _number(comment['authorId'])
                          ? IconButton(
                              tooltip: 'Delete comment',
                              onPressed:
                                  _deleting.contains(_number(comment['id']))
                                  ? null
                                  : () {
                                      _deleteComment(comment);
                                    },
                              icon: const Icon(Icons.delete_outline, size: 20),
                            )
                          : null,
                    ),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(color: _primary),
                      ),
                    )
                  else if (_hasMore && _error == null)
                    TextButton(
                      onPressed: () {
                        _load();
                      },
                      child: const Text('Load more comments'),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      enabled: !_sending,
                      maxLength: 1000,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Send comment',
                    onPressed: _sending || _loading ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: _primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
