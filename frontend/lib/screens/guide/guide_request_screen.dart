import 'package:flutter/material.dart';

import '../../models/guide_application.dart';
import '../../services/api_client.dart';
import '../../services/guide_service.dart';
import '../../widgets/heritage_logo.dart';
import '../../widgets/heritage_message.dart';
import '../../widgets/no_overscroll_scroll_behavior.dart';

class GuideRequestScreen extends StatefulWidget {
  const GuideRequestScreen({super.key});

  @override
  State<GuideRequestScreen> createState() => _GuideRequestScreenState();
}

class _GuideRequestScreenState extends State<GuideRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _area = TextEditingController();
  final _languages = TextEditingController();
  final _experience = TextEditingController();

  bool _loading = false;
  bool _checkingStatus = false;
  GuideApplication? _statusApplication;
  GuideApplication? _submittedApplication;

  static const Color _background = Color(0xFFF3E8DF);
  static const Color _primary = Color(0xFFA45130);
  static const Color _primaryDark = Color(0xFF793D25);
  static const Color _text = Color(0xFF302A26);
  static const Color _muted = Color(0xFF7D6F66);
  static const Color _border = Color(0xFFE2CFC1);
  static const Color _surface = Color(0xFFFFF7EF);
  static const Color _inputSurface = Color(0xFFFFFCF8);
  static const Color _soft = Color(0xFFF2D9C7);

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _phone,
      _area,
      _languages,
      _experience,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? 'This field is required'
        : null;
  }

  // ================= EXISTING BACKEND LOGIC =================

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final application = await GuideService.instance.submitRequest(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        primaryServiceArea: _area.text.trim(),
        languages: _languages.text.trim(),
        experience: _experience.text.trim(),
      );

      if (!mounted) return;

      setState(() => _submittedApplication = application);
    } on ApiException catch (e) {
      if (mounted) {
        showHeritageMessage(context, e.message, error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _checkStatus() async {
    final email = _email.text.trim();
    final phone = _phone.text.trim();

    if (email.isEmpty || phone.isEmpty) {
      showHeritageMessage(
        context,
        'Enter the email and phone number used in your request',
        error: true,
      );
      return;
    }

    if (!email.contains('@')) {
      showHeritageMessage(context, 'Enter a valid email', error: true);
      return;
    }

    setState(() {
      _checkingStatus = true;
      _statusApplication = null;
    });

    try {
      final application = await GuideService.instance.checkStatus(
        email: email,
        phone: phone,
      );

      if (!mounted) return;

      setState(() => _statusApplication = application);
    } on ApiException catch (e) {
      if (mounted) {
        showHeritageMessage(context, e.message, error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _checkingStatus = false);
      }
    }
  }

  // ================= COMMON INPUT FIELD =================

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextInputAction textInputAction = TextInputAction.next,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _text,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _text,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFFAAA098),
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: _inputSurface,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 13,
              vertical: maxLines > 1 ? 15 : 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ================= RESPONSIVE TWO COLUMNS =================

  Widget _twoColumns({required Widget left, required Widget right}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 305) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, const SizedBox(height: 16), right],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  // ================= SECTION CARD =================

  Widget _section({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 39,
                width: 39,
                decoration: BoxDecoration(
                  color: _soft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 20, color: _primaryDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 10.5, color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 17),
          ...children,
        ],
      ),
    );
  }

  // ================= IMAGE BANNER =================

  Widget _banner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 2.65,
          child: Image.asset(
            'assets/images/guide_request_banner.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: _soft,
                child: const Center(
                  child: Icon(
                    Icons.landscape_outlined,
                    size: 48,
                    color: _primaryDark,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ================= PAGE HEADER =================

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.only(top: 9, bottom: 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: _soft,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Text(
              'GUIDE APPLICATION',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: _primaryDark,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Become a local guide',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: _text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Share your knowledge of Sri Lanka with visitors. '
            'Complete the form below to apply for a guide account.',
            style: TextStyle(fontSize: 12, height: 1.6, color: _muted),
          ),
        ],
      ),
    );
  }

  // ================= APPLICATION NOTICE =================

  Widget _notice() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 17),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: _primaryDark, size: 20),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Application review',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _text,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Guide accounts are approved by our team. '
                  'You do not need to create a password now. '
                  'If approved, your login details will be sent by email.',
                  style: TextStyle(fontSize: 10.5, height: 1.5, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= PERSONAL INFORMATION =================

  Widget _personalSection() {
    return _section(
      title: 'Personal information',
      subtitle: 'Enter your contact details.',
      icon: Icons.person_outline_rounded,
      children: [
        _twoColumns(
          left: _field(
            label: 'Full name',
            hint: 'Your full name',
            controller: _name,
            validator: _required,
            keyboardType: TextInputType.name,
          ),
          right: _field(
            label: 'Phone number',
            hint: '07XXXXXXXX',
            controller: _phone,
            validator: _required,
            keyboardType: TextInputType.phone,
          ),
        ),
        const SizedBox(height: 16),
        _field(
          label: 'Email address',
          hint: 'name@example.com',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (_required(value) != null) {
              return 'This field is required';
            }
            return value!.contains('@') ? null : 'Enter a valid email';
          },
        ),
      ],
    );
  }

  // ================= GUIDE DETAILS =================

  Widget _guideSection() {
    return _section(
      title: 'Guiding details',
      subtitle: 'Tell us where and how you can guide visitors.',
      icon: Icons.map_outlined,
      children: [
        _twoColumns(
          left: _field(
            label: 'Primary service area',
            hint: 'e.g. Galle Fort',
            controller: _area,
            validator: _required,
          ),
          right: _field(
            label: 'Languages',
            hint: 'e.g. Sinhala, English',
            controller: _languages,
            validator: _required,
          ),
        ),
        const SizedBox(height: 16),
        _field(
          label: 'Guiding experience',
          hint:
              'Tell us about your experience, local knowledge '
              'and the types of tours you can offer.',
          controller: _experience,
          validator: _required,
          maxLines: 5,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
        ),
      ],
    );
  }

  // ================= STATUS CHECK =================

  Widget _checkStatusButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: _checkingStatus || _loading ? null : _checkStatus,
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryDark,
            backgroundColor: _surface,
            side: const BorderSide(color: _primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: _checkingStatus
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: _primaryDark,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.search_rounded, size: 18),
          label: Text(
            _checkingStatus ? 'Checking Status' : 'Check Application Status',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  // ================= SUBMIT BUTTON =================

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primary.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Submit Application',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 9),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
      ),
    );
  }

  // ================= APPLICATION FORM =================

  Widget _applicationForm() {
    return Form(
      key: _formKey,
      child: ScrollConfiguration(
        behavior: const NoOverscrollScrollBehavior(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            _header(),
            _banner(),
            _notice(),
            _personalSection(),
            _checkStatusButton(),
            if (_statusApplication != null) ...[
              _statusCard(_statusApplication!),
              const SizedBox(height: 15),
            ],
            _guideSection(),
            const SizedBox(height: 3),
            _submitButton(),
            const SizedBox(height: 16),
            const Text(
              'Your application will be reviewed before '
              'a guide account is created.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, height: 1.5, color: _muted),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return const Color(0xFF446651);
      case 'REJECTED':
        return const Color(0xFFB3261E);
      default:
        return _primaryDark;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Icons.verified_rounded;
      case 'REJECTED':
        return Icons.cancel_outlined;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  Widget _statusCard(GuideApplication application) {
    final status = application.status.toUpperCase();
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(_statusIcon(status), color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current status',
                  style: TextStyle(
                    fontSize: 11,
                    color: _muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 16,
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= SUCCESS STEP =================

  Widget _successStep({
    required String number,
    required String title,
    required String description,
    required bool last,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 19),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _soft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= SUCCESS SCREEN =================

  Widget _successScreen() {
    final application = _submittedApplication;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 28),
      children: [
        Center(
          child: Container(
            width: 86,
            height: 86,
            decoration: const BoxDecoration(
              color: _soft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 42,
              color: _primaryDark,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Application submitted',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _text,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'Thank you for applying to become a Ceylon Heritage '
          'guide. Your request has been sent for review.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, height: 1.6, color: _muted),
        ),
        const SizedBox(height: 25),
        if (application != null) ...[
          _statusCard(application),
          const SizedBox(height: 18),
        ],

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _surface,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What happens next?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
              const SizedBox(height: 20),

              _successStep(
                number: '01',
                title: 'Application review',
                description: 'Our team reviews the information you submitted.',
                last: false,
              ),
              _successStep(
                number: '02',
                title: 'Email or phone contact',
                description: 'We may contact you if more details are needed.',
                last: false,
              ),
              _successStep(
                number: '03',
                title: 'Account approval',
                description:
                    'If approved, your guide account and temporary '
                    'password will be sent by email.',
                last: false,
              ),
              _successStep(
                number: '04',
                title: 'First login',
                description:
                    'Sign in with your temporary password, '
                    'then set your own password.',
                last: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _soft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.mail_outline_rounded,
                color: _primaryDark,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _email.text.trim(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _text,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 23),

        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Back to Login',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  // ================= MAIN BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: _text),
        ),
        title: const HeritageLogo(compact: true),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _submittedApplication != null
                ? _successScreen()
                : _applicationForm(),
          ),
        ),
      ),
    );
  }
}
