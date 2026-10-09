import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/heritage_logo.dart';
import '../../widgets/heritage_message.dart';
import '../../widgets/no_overscroll_scroll_behavior.dart';

import 'email_verification_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _agreed = false;
  bool _loading = false;

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // ================= COLORS =================

  static const Color _background = Color(0xFFF3E8DF);
  static const Color _primary = Color(0xFFA45130);
  static const Color _primaryDark = Color(0xFF793D25);
  static const Color _text = Color(0xFF302A26);
  static const Color _muted = Color(0xFF7D6F66);
  static const Color _border = Color(0xFFE2CFC1);
  static const Color _surface = Color(0xFFFFF7EF);
  static const Color _soft = Color(0xFFF2D9C7);

  @override
  void dispose() {
    for (final controller in [
      _fullName,
      _username,
      _email,
      _phone,
      _address,
      _password,
      _confirm,
    ]) {
      controller.dispose();
    }

    super.dispose();
  }

  // ================= VALIDATION =================

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Required' : null;
  }

  // ================= REGISTER LOGIC =================

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreed) {
      showHeritageMessage(
        context,
        'Please accept the heritage terms',
        error: true,
      );
      return;
    }

    final parts = _fullName.text.trim().split(RegExp(r'\s+'));

    final firstName = parts.isEmpty ? '' : parts.first;

    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    setState(() => _loading = true);

    try {
      final result = await AuthService.instance.register(
        username: _username.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text,
        confirmPassword: _confirm.text,
        firstName: firstName,
        lastName: lastName,
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => result.verificationRequired
              ? EmailVerificationScreen(
                  email: _email.text.trim(),
                  initialMessage: result.message,
                )
              : const LoginScreen(),
        ),
      );
      if (!result.verificationRequired && mounted) {
        showHeritageMessage(context, result.message);
      }
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

  // ================= INPUT FIELD =================

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
    VoidCallback? onVisibilityToggle,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _text,
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          validator: validator,
          style: const TextStyle(
            fontSize: 13,
            color: _text,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintMaxLines: 1,
            hintStyle: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFFADA39B),
            ),

            suffixIcon: onVisibilityToggle == null
                ? null
                : IconButton(
                    onPressed: onVisibilityToggle,
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: _muted,
                    ),
                  ),
            prefixIcon: icon == null
                ? null
                : Icon(icon, color: _primaryDark, size: 18),

            filled: true,
            fillColor: const Color(0xFFFFFCF8),
            isDense: true,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _border),
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

  Widget _buildTwoColumns({required Widget left, required Widget right}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Phone-width forms stay readable with a single column.
        if (constraints.maxWidth < 430) {
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

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 14,
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _soft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: _primaryDark, size: 18),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _text,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ...children,
        ],
      ),
    );
  }

  // ================= PAGE HEADER =================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 18),
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
              'TOURIST REGISTRATION',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: _primaryDark,
              ),
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Create an account',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
              color: _text,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Sign up to explore historical places, plan trips '
            'and manage your bookings.',
            style: TextStyle(fontSize: 12, color: _muted, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ================= NEW HERITAGE BANNER =================

  Widget _buildSignupBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 2.8,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/signup_heritage_banner.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: _soft,
                    child: const Center(
                      child: Icon(
                        Icons.account_balance_rounded,
                        size: 42,
                        color: _primaryDark,
                      ),
                    ),
                  );
                },
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x11000000),
                      Color(0x22000000),
                      Color(0xAA24120B),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 13,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _surface.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'START YOUR JOURNEY',
                        style: TextStyle(
                          color: _primaryDark,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Explore Sri Lankan heritage with one account',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= PERSONAL INFORMATION =================

  Widget _buildPersonalDetails() {
    return _buildSection(
      title: 'Personal Information',
      icon: Icons.person_outline_rounded,
      children: [
        _buildTwoColumns(
          left: _buildField(
            label: 'Full name',
            hint: 'Your full name',
            controller: _fullName,
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.name,
            validator: _required,
          ),
          right: _buildField(
            label: 'Username',
            hint: 'Username',
            controller: _username,
            icon: Icons.alternate_email_rounded,
            validator: _required,
          ),
        ),
      ],
    );
  }

  // ================= CONTACT DETAILS =================

  Widget _buildContactDetails() {
    return _buildSection(
      title: 'Contact Details',
      icon: Icons.contact_mail_outlined,
      children: [
        _buildTwoColumns(
          left: _buildField(
            label: 'Email',
            hint: 'Email address',
            controller: _email,
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (_required(value) != null) {
                return 'Required';
              }

              if (!value!.contains('@')) {
                return 'Enter a valid email';
              }

              return null;
            },
          ),

          right: _buildField(
            label: 'Phone number',
            hint: '07XXXXXXXX',
            controller: _phone,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: _required,
          ),
        ),

        const SizedBox(height: 16),

        _buildField(
          label: 'Address (optional)',
          hint: 'Enter your address',
          controller: _address,
          icon: Icons.location_on_outlined,
        ),
      ],
    );
  }

  // ================= ACCOUNT SECURITY =================

  Widget _buildSecurity() {
    return _buildSection(
      title: 'Account Security',
      icon: Icons.lock_outline_rounded,
      children: [
        _buildTwoColumns(
          left: _buildField(
            label: 'Password',
            hint: 'Password',
            controller: _password,
            icon: Icons.lock_outline_rounded,
            obscureText: !_showPassword,
            onVisibilityToggle: () {
              setState(() {
                _showPassword = !_showPassword;
              });
            },
            validator: (value) {
              if (value == null || value.length < 8) {
                return 'Use at least 8 characters';
              }
              return null;
            },
          ),

          right: _buildField(
            label: 'Confirm password',
            hint: 'Confirm password',
            controller: _confirm,
            icon: Icons.verified_user_outlined,
            obscureText: !_showConfirmPassword,
            textInputAction: TextInputAction.done,
            onVisibilityToggle: () {
              setState(() {
                _showConfirmPassword = !_showConfirmPassword;
              });
            },
            validator: (value) {
              return value != _password.text ? 'Passwords do not match' : null;
            },
          ),
        ),

        const SizedBox(height: 14),

        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 15, color: _muted),

            SizedBox(width: 7),

            Expanded(
              child: Text(
                'Use at least 8 characters for your password.',
                style: TextStyle(fontSize: 10.5, color: _muted, height: 1.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= EMAIL VERIFICATION =================

  Widget _buildVerificationInfo() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 17),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0DFD1)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mark_email_read_outlined, size: 20, color: _primaryDark),

          SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email verification',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _text,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'We will send a verification code to your email '
                  'after you create your account.',
                  style: TextStyle(fontSize: 11, color: _muted, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TERMS =================

  Widget _buildTerms() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: _agreed,
            activeColor: _primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            onChanged: (value) {
              setState(() {
                _agreed = value ?? false;
              });
            },
          ),

          const Expanded(
            child: Text(
              'I agree to the Ceylon Heritage terms of use.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.5,
                color: _text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CREATE ACCOUNT BUTTON =================

  Widget _buildSubmitButton() {
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
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: _surface,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create Account',
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

  // ================= SIGN IN LINK =================

  Widget _buildLoginLink() {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Flexible(
            child: Text(
              'Already have an account?',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
          ),

          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: _primary),
            child: const Text(
              'Sign in',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ================= MAIN UI =================

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
          onPressed: () {
            Navigator.maybePop(context);
          },
          icon: const Icon(Icons.arrow_back_rounded, color: _text),
        ),
        title: const HeritageLogo(compact: true),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: ScrollConfiguration(
                behavior: const NoOverscrollScrollBehavior(),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page title
                      _buildHeader(),

                      // Galle Fort image
                      _buildSignupBanner(),

                      // Registration fields
                      _buildPersonalDetails(),
                      _buildContactDetails(),
                      _buildSecurity(),

                      // Email verification
                      _buildVerificationInfo(),

                      // Terms and submit
                      _buildTerms(),
                      _buildSubmitButton(),

                      // Sign in
                      _buildLoginLink(),
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
}
