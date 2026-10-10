import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/place_review.dart';
import '../services/tourism_service.dart';
import '../widgets/tourism_bottom_nav.dart';

/// Review form with local-only state; connect submission and image picking later.
class AddReviewScreen extends StatefulWidget {
  const AddReviewScreen({
    super.key,
    required this.placeId,
    this.placeName = 'Galle Fort',
    this.review,
  });

  final int placeId;
  final String placeName;
  final PlaceReview? review;

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  int _rating = 0;
  final List<Uint8List> _photos = <Uint8List>[];
  bool _pickingPhotos = false;
  final _review = TextEditingController();

  Future<void> _pickPhotos() async {
    if (_pickingPhotos || _photos.length >= 5) return;
    setState(() => _pickingPhotos = true);
    try {
      final List<PlatformFile> picked = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      if (!mounted || picked.isEmpty) return;
      final files = <Uint8List>[];
      for (final file in picked) {
        if (await file.length() > 5 * 1024 * 1024) continue;
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty && _photos.length + files.length < 5) {
          files.add(bytes);
        }
      }
      setState(() => _photos.addAll(files));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not select photos.')));
    } finally {
      if (mounted) setState(() => _pickingPhotos = false);
    }
  }
  @override
  void initState() {
    super.initState();
    _rating = widget.review?.rating ?? 0;
    _review.text = widget.review?.comment ?? '';
  }

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
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
          Text(
            widget.review == null ? 'Write a Review' : 'Edit Your Review',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          Text(
            '${widget.placeName}, Sri Lanka',
            style: const TextStyle(fontSize: 10, color: Color(0xFF68716D)),
          ),
        ],
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(17, 7, 17, 22),
      children: [
        Row(
          children: const [
            _TabLabel('Overview'),
            _TabLabel('Reviews', selected: true),
            _TabLabel('Photos'),
          ],
        ),
        const SizedBox(height: 17),
        const Text(
          'Your Rating',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            for (var star = 1; star <= 5; star++)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 31),
                onPressed: () => setState(() => _rating = star),
                icon: Icon(
                  star <= _rating ? Icons.star : Icons.star_border,
                  size: 27,
                  color: const Color(0xFFEB963A),
                ),
              ),
            const SizedBox(width: 5),
            const Text(
              'Tap stars',
              style: TextStyle(fontSize: 9, color: Color(0xFF89938D)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Review Details',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: _review,
          maxLines: 5,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText:
                'Share your experience in detail... What did you love? Any tips for other Sri Lankan travelers?',
            hintStyle: const TextStyle(
              fontSize: 10,
              height: 1.45,
              color: Color(0xFF98A19C),
            ),
            counterText: '',
            contentPadding: const EdgeInsets.all(12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Color(0xFFE9E2DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Color(0xFFE9E2DB)),
            ),
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          'Add Photos (Optional)',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            InkWell(
              onTap: _pickPhotos,
              child: Container(
                width: 58,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE9E2DB)),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Color(0xFF824A2B)),
                    Text(
                      'Upload',
                      style: TextStyle(fontSize: 8, color: Color(0xFF824A2B)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 58,
              height: 62,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFB7C8C4),
                    Color(0xFFD5A77E),
                    Color(0xFF60776F),
                  ],
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.landscape_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: () async {
            if (_rating == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select a star rating first.'),
                ),
              );
              return;
            }
            if (_review.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please write a few words about your visit.'),
                ),
              );
              return;
            }
            try {
              if (widget.review == null) {
                await TourismService.instance.submitReview(
                  placeId: widget.placeId,
                  rating: _rating,
                  comment: _review.text.trim(),
                );
              } else {
                await TourismService.instance.updateReview(
                  placeId: widget.placeId,
                  review: widget.review!,
                  rating: _rating,
                  comment: _review.text.trim(),
                );
              }
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(widget.review == null
                      ? 'Review added. You can see it in Reviews.'
                      : 'Your review has been updated.'),
                ),
              );
              Navigator.maybePop(context, true);
            } catch (error) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not submit review: $error')),
              );
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF824A2B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            widget.review == null ? 'Submit Review' : 'Save Changes',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
    bottomNavigationBar: const TourismBottomNav(currentIndex: 0),
  );
}

class _TabLabel extends StatelessWidget {
  const _TabLabel(this.label, {this.selected = false});
  final String label;
  final bool selected;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 5),
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF824A2B) : Colors.white,
        border: Border.all(
          color: selected ? const Color(0xFF824A2B) : const Color(0xFFE9E2DB),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 9,
          color: selected ? Colors.white : const Color(0xFF68716D),
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
