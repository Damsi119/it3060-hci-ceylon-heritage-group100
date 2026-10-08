import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/api_config.dart';
import '../../models/tour_plan.dart';
import '../../services/api_client.dart';
import '../../services/tour_plan_service.dart';
import '../../widgets/heritage_logo.dart';
import '../../widgets/no_overscroll_scroll_behavior.dart';

const _plannerBg = Color(0xFFF8F3ED);
const _plannerSurface = Color(0xFFFFFFFF);
const _plannerSurfaceSoft = Color(0xFFF1E7DC);
const _plannerInk = Color(0xFF3A241B);
const _plannerMuted = Color(0xFF6F6A66);
const _plannerPrimary = Color(0xFF9A4F2D);
const _plannerPrimaryDark = Color(0xFF6B321D);
const _plannerAccent = Color(0xFFC96F4A);
const _plannerBlue = Color(0xFF667B99);
const _plannerBorder = Color(0xFFEADFD5);

class TourPlanGeneratorScreen extends StatefulWidget {
  const TourPlanGeneratorScreen({super.key, required this.onHome});

  final VoidCallback onHome;

  @override
  State<TourPlanGeneratorScreen> createState() =>
      _TourPlanGeneratorScreenState();
}

class _TourPlanGeneratorScreenState extends State<TourPlanGeneratorScreen> {
  final _promptController = TextEditingController();

  TourPlan? _plan;
  bool _generating = false;
  String? _error;

  final _money = NumberFormat('#,##0');

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _back() async {
    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop();
    } else {
      widget.onHome();
    }
  }

  String _errorText(Object error) {
    if (error is TimeoutException) {
      return 'The planner took too long. Please try again.';
    }

    if (error is ApiException) {
      return error.message;
    }

    if (error is FormatException) {
      return 'The backend returned an unexpected plan.';
    }

    return 'Could not generate a plan. Check the backend connection.';
  }

  Future<void> _generate() async {
    FocusScope.of(context).unfocus();

    final prompt = _promptController.text.trim();

    if (prompt.isEmpty) {
      _message('Add your budget, preference and starting city.');
      return;
    }

    setState(() {
      _generating = true;
      _error = null;
    });

    try {
      final plan = await TourPlanService.instance
          .generate(prompt)
          .timeout(const Duration(seconds: 25));

      if (!mounted) return;

      setState(() {
        _plan = plan;
        _generating = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _generating = false;
        _error = _errorText(error);
      });
    }
  }

  Future<void> _openMaps(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      _message('This map link is not valid.');
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened) {
      _message('Could not open Google Maps.');
    }
  }

  void _useExample(String text) {
    setState(() {
      _promptController.text = text;
      _promptController.selection = TextSelection.collapsed(
        offset: text.length,
      );
    });
  }

  String _rupees(int amount) {
    return 'Rs. ${_money.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: _plannerBg,
        textTheme: GoogleFonts.interTextTheme(
          theme.textTheme,
        ).apply(bodyColor: _plannerInk, displayColor: _plannerInk),
      ),
      child: Scaffold(
        backgroundColor: _plannerBg,
        body: SafeArea(
          child: Column(
            children: [
              _topBar(),
              if (_generating)
                const LinearProgressIndicator(
                  minHeight: 3,
                  color: _plannerPrimary,
                  backgroundColor: _plannerSurfaceSoft,
                ),
              Expanded(
                child: ScrollConfiguration(
                  behavior: const NoOverscrollScrollBehavior(),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 860),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _plannerPanel(),
                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              _errorPanel(_error!),
                            ],
                            if (_plan != null) ...[
                              const SizedBox(height: 16),
                              _resultHero(_plan!),
                              const SizedBox(height: 14),
                              _expenseCard(_plan!),
                              const SizedBox(height: 14),
                              _itineraryCard(_plan!),
                              const SizedBox(height: 14),
                              _placesCard(_plan!),
                              const SizedBox(height: 14),
                              _notesCard(_plan!),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back to Home',
            onPressed: _back,
            icon: const Icon(Icons.arrow_back_rounded),
            color: _plannerInk,
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeritageLogo(compact: true),
                SizedBox(height: 3),
                Text(
                  'Smart Tour Planner',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: _plannerSurface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _plannerBorder),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 15, color: _plannerAccent),
                SizedBox(width: 5),
                Text(
                  'Planner',
                  style: TextStyle(
                    fontSize: 11,
                    color: _plannerMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _plannerPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _plannerPrimaryDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.travel_explore_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan your Sri Lanka trip',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        color: _plannerInk,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Budget, mood, starting city, places and route in one plan.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: _plannerMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _promptController,
            minLines: 4,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText:
                  'I have Rs. 10,000. I want a cold place. '
                  'I am starting from Galle.',
              filled: true,
              fillColor: const Color(0xFFFFFBF7),
              border: _inputBorder(),
              enabledBorder: _inputBorder(),
              focusedBorder: _inputBorder(color: _plannerPrimary),
              contentPadding: const EdgeInsets.all(14),
            ),
            style: const TextStyle(fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _exampleChip(
                'Cold',
                'I have Rs. 10,000. I want to visit a cold weather place. '
                    "I'm starting from Galle.",
              ),
              _exampleChip(
                'Beach',
                'I have Rs. 15,000. I want a beach trip. '
                    "I'm starting from Colombo.",
              ),
              _exampleChip(
                'Ancient',
                'I have Rs. 20,000. I want to see ancient historical places. '
                    "I'm starting from Kandy.",
              ),
              _exampleChip(
                'Nature',
                'I have Rs. 25,000. I want nature and scenic places. '
                    "I'm starting from Matara.",
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _generating ? null : _generate,
              style: FilledButton.styleFrom(
                backgroundColor: _plannerPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _plannerPrimary.withValues(
                  alpha: 0.45,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded, size: 20),
              label: Text(
                _generating ? 'Generating plan...' : 'Generate Tour Plan',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _exampleChip(String label, String prompt) {
    return ActionChip(
      onPressed: _generating ? null : () => _useExample(prompt),
      avatar: const Icon(Icons.bolt_rounded, size: 16),
      label: Text(label),
      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      backgroundColor: _plannerSurfaceSoft,
      side: const BorderSide(color: _plannerBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }

  Widget _resultHero(TourPlan plan) {
    final heroImage = _heroImageUrl(plan);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x173A241B),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(
              child: heroImage == null
                  ? const ColoredBox(color: _plannerInk)
                  : _heroBackgroundImage(heroImage),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x803A241B),
                      Color(0x263A241B),
                      Color(0xB33A241B),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0x803A241B),
                      Color(0x263A241B),
                      Color(0x003A241B),
                    ],
                    stops: [0.0, 0.48, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recommended Tour',
                              style: TextStyle(
                                color: Color(0xFFEADFD5),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              plan.destination,
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 30,
                                height: 1.02,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        tooltip: 'Open destination in Google Maps',
                        style: IconButton.styleFrom(
                          backgroundColor: _plannerAccent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: plan.mapsUrl.isEmpty
                            ? null
                            : () => _openMaps(plan.mapsUrl),
                        icon: const Icon(Icons.map_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _metricChip(
                        Icons.account_balance_wallet_rounded,
                        'Budget',
                        _rupees(plan.totalBudget),
                      ),
                      _metricChip(
                        Icons.calendar_month_rounded,
                        'Duration',
                        '${plan.durationDays} day${plan.durationDays == 1 ? '' : 's'}',
                      ),
                      _metricChip(
                        Icons.thermostat_rounded,
                        'Preference',
                        plan.preference,
                      ),
                      _metricChip(
                        Icons.near_me_rounded,
                        'From',
                        plan.startingLocation,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _heroImageUrl(TourPlan plan) {
    for (final place in plan.places) {
      final localImage = _localPlaceImage(place.name);
      if (localImage != null) return localImage;

      final imageUrl = place.imageUrl.trim();
      if (imageUrl.isNotEmpty) return imageUrl;
    }

    return null;
  }

  String? _localPlaceImage(String name) {
    final normalized = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    const assets = {
      'gallefort': 'galle_fort.png',
      'jaffnafort': 'jaffna_fort.png',
      'sigiriya': 'sigiriya.png',
      'templeofthetooth': 'temple_of_the_tooth.png',
      'sacredtoothrelictemple': 'temple_of_the_tooth.png',
      'polonnaruwaancientcity': 'polonnaruwa.png',
      'polonnaruwa': 'polonnaruwa.png',
      'ruwanwelisaya': 'ruwanwelisaya.png',
      'galvihara': 'gal_vihara.png',
      'rankothvehera': 'rankoth_vehera.png',
      'lankathilakatemple': 'lankathilaka_temple.png',
      'parakramasamudraya': 'parakrama_samudraya.png',
      'sri mahabodhi': 'sri_maha_bodhi.png',
      'srimahabodhi': 'sri_maha_bodhi.png',
      'jethawanaramaya': 'jethawanaramaya.png',
      'thuparamaya': 'thuparamaya.png',
      'isurumuniya': 'isurumuniya.png',
      'mihintale': 'mihintale.png',
      'samadhistatue': 'samadhi_statue.png',
    };

    for (final entry in assets.entries) {
      if (normalized.contains(entry.key)) {
        return 'assets/images/${entry.value}';
      }
    }

    return null;
  }

  Widget _heroBackgroundImage(String source) {
    Widget fallback() {
      return const ColoredBox(color: _plannerInk);
    }

    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => fallback(),
      );
    }

    final uri = Uri.tryParse(source);
    if (uri == null) return fallback();

    final baseUrl = ApiConfig.baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final resolved = uri.hasScheme
        ? uri
        : Uri.parse('$baseUrl/').resolveUri(uri);

    if (resolved.scheme != 'http' && resolved.scheme != 'https') {
      return fallback();
    }

    return Image.network(
      resolved.toString(),
      fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) => fallback(),
    );
  }

  Widget _metricChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _plannerInk.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x523A241B),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFEBDDCB)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFFEADFD5),
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _expenseCard(TourPlan plan) {
    return _sectionCard(
      icon: Icons.payments_rounded,
      iconColor: _plannerPrimary,
      title: 'Estimated Budget',
      child: Column(
        children: [
          for (final expense in plan.expenses)
            _expenseRow(expense.name, _rupees(expense.estimatedCost)),
          const Divider(height: 22, color: _plannerBorder),
          _expenseRow('Total', _rupees(plan.totalEstimatedCost), strong: true),
        ],
      ),
    );
  }

  Widget _expenseRow(String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: strong ? 13 : 12,
                color: strong ? _plannerInk : _plannerMuted,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: strong ? 13 : 12,
              color: strong ? _plannerPrimaryDark : _plannerInk,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _itineraryCard(TourPlan plan) {
    return _sectionCard(
      icon: Icons.route_rounded,
      iconColor: _plannerAccent,
      title: 'Day Plan',
      child: Column(
        children: [
          for (int index = 0; index < plan.itinerary.length; index++)
            _dayTile(
              plan.itinerary[index],
              last: index == plan.itinerary.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _dayTile(TourPlanDay day, {required bool last}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _plannerPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${day.day}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: _plannerBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day ${day.day}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _plannerInk,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final activity in day.activities)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Icon(
                              Icons.circle,
                              size: 5,
                              color: _plannerAccent,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              activity,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.38,
                                color: _plannerMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placesCard(TourPlan plan) {
    if (plan.places.isEmpty) {
      return _sectionCard(
        icon: Icons.account_balance_rounded,
        iconColor: _plannerBlue,
        title: 'Suggested Places',
        child: const Text(
          'No active historical places are available for this plan yet.',
          style: TextStyle(fontSize: 12, color: _plannerMuted, height: 1.35),
        ),
      );
    }

    return _sectionCard(
      icon: Icons.account_balance_rounded,
      iconColor: _plannerBlue,
      title: 'Suggested Places',
      child: SizedBox(
        height: 214,
        child: ListView.separated(
          physics: const ClampingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: plan.places.length,
          separatorBuilder: (_, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            return SizedBox(width: 174, child: _placeCard(plan.places[index]));
          },
        ),
      ),
    );
  }

  Widget _placeCard(TourPlanPlace place) {
    return Material(
      color: const Color(0xFFFFFBF7),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: place.mapsUrl.isEmpty ? null : () => _openMaps(place.mapsUrl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 96,
              width: double.infinity,
              child: _placeImage(place),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 35,
                    child: Text(
                      place.name.isEmpty ? 'Historical place' : place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: _plannerAccent,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          place.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _plannerMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _tagLabel(place),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: _plannerBlue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.map_rounded,
                        size: 17,
                        color: _plannerPrimary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeImage(TourPlanPlace place) {
    Widget fallback() {
      final localImage = _localPlaceImage(place.name);

      if (localImage != null) {
        return Image.asset(
          localImage,
          fit: BoxFit.cover,
          errorBuilder: (_, error, stackTrace) => const ColoredBox(
            color: _plannerSurfaceSoft,
            child: Center(
              child: Icon(
                Icons.landscape_rounded,
                color: _plannerMuted,
                size: 30,
              ),
            ),
          ),
        );
      }

      return const ColoredBox(
        color: _plannerSurfaceSoft,
        child: Center(
          child: Icon(Icons.landscape_rounded, color: _plannerMuted, size: 30),
        ),
      );
    }

    if (place.imageUrl.isEmpty) return fallback();

    if (place.imageUrl.startsWith('assets/')) {
      return Image.asset(
        place.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => fallback(),
      );
    }

    final uri = Uri.tryParse(place.imageUrl);
    if (uri == null) return fallback();

    final baseUrl = ApiConfig.baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final resolved = uri.hasScheme
        ? uri
        : Uri.parse('$baseUrl/').resolveUri(uri);

    if (resolved.scheme != 'http' && resolved.scheme != 'https') {
      return fallback();
    }

    return Image.network(
      resolved.toString(),
      fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) => fallback(),
    );
  }

  String _tagLabel(TourPlanPlace place) {
    if (place.climateType.isNotEmpty) {
      return place.climateType.replaceAll('_', ' ');
    }

    if (place.travelTags.isNotEmpty) {
      return place.travelTags.first.replaceAll('_', ' ');
    }

    if (place.category.isNotEmpty) {
      return place.category.replaceAll('_', ' ');
    }

    return 'HERITAGE';
  }

  Widget _notesCard(TourPlan plan) {
    return _sectionCard(
      icon: Icons.info_outline_rounded,
      iconColor: _plannerMuted,
      title: 'Planning Notes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusLine(
            Icons.verified_rounded,
            'Match confidence: ${plan.confidenceLabel}',
            _plannerPrimary,
          ),
          if (plan.detectedKeywords.isNotEmpty)
            _statusLine(
              Icons.sell_rounded,
              'Detected: ${plan.detectedKeywords.join(', ')}',
              _plannerBlue,
            ),
          for (final note in plan.notes)
            _statusLine(Icons.circle, note, _plannerMuted, smallIcon: true),
        ],
      ),
    );
  }

  Widget _statusLine(
    IconData icon,
    String text,
    Color color, {
    bool smallIcon = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: smallIcon ? 6 : 1),
            child: Icon(icon, size: smallIcon ? 5 : 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                height: 1.35,
                color: _plannerMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorPanel(String text) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3C6C0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB3261E),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF7B241F),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _plannerInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _plannerSurface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _plannerBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F3A241B),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    );
  }

  OutlineInputBorder _inputBorder({Color color = _plannerBorder}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color),
    );
  }
}
