import 'package:flutter/material.dart';

import '../../models/auth_response.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/google_auth_service.dart';
import '../../services/notification_center.dart';
import '../../widgets/heritage_logo.dart';
import '../../widgets/heritage_message.dart';
import '../../widgets/no_overscroll_scroll_behavior.dart';

import '../guide/guide_request_screen.dart';
import '../home/home_router.dart';
import 'change_password_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _identifier = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _googleLoading = false;
  bool _showPassword = false;

  // Ceylon Heritage Theme
  static const Color _background = Color(0xFFF3E8DF);
  static const Color _primary = Color(0xFFA54E2B);
  static const Color _primaryDark = Color(0xFF793719);
  static const Color _cream = Color(0xFFFFF4E9);
  static const Color _border = Color(0xFFEAE4DC);
  static const Color _text = Color(0xFF302720);
  static const Color _muted = Color(0xFF857A71);

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  // ================= LOGIN LOGIC =================

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final response = await AuthService.instance.login(
        _identifier.text.trim(),
        _password.text,
      );

      if (!mounted) return;

      _openAfterLogin(response, currentPassword: _password.text);
    } on ApiException catch (e) {
      if (mounted) {
        showHeritageMessage(context, e.message, error: true);
      }
    } catch (e) {
      if (mounted) {
        showHeritageMessage(context, _friendlyError(e), error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ================= GOOGLE LOGIN =================

  Future<void> _googleLogin() async {
    setState(() => _googleLoading = true);

    try {
      final idToken = await GoogleAuthService.instance.getIdToken();

      final response = await AuthService.instance.googleLogin(idToken);

      if (!mounted) return;

      _openAfterLogin(response);
    } on ApiException catch (e) {
      if (mounted) {
        showHeritageMessage(context, e.message, error: true);
      }
    } catch (e) {
      if (mounted) {
        showHeritageMessage(context, _friendlyError(e), error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _googleLoading = false);
      }
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();

    return text.startsWith('Exception: ')
        ? text.substring('Exception: '.length)
        : text;
  }

  // ================= LOGIN NAVIGATION =================

  void _openAfterLogin(AuthResponse response, {String? currentPassword}) {
    NotificationCenter.instance.start();

    if (response.user.passwordChangeRequired) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChangePasswordScreen(
            user: response.user,
            forced: true,
            initialCurrentPassword: currentPassword,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeRouter(user: response.user)),
    );
  }

  // ================= INPUT DECORATION =================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFAAA29A),
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(icon, color: _primaryDark, size: 19),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  // ================= SMALL LABEL =================

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _text,
        ),
      ),
    );
  }

  // ================= TOP HEADER =================

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 20),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFECD9C9)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.explore_outlined, size: 13, color: _primaryDark),
                SizedBox(width: 5),
                Text(
                  'HERITAGE EXPLORER',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: _primaryDark,
                  ),
                ),
              ],
            ),
          ),

          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: _primary, size: 6),
              SizedBox(width: 6),
              Text(
                'Secure Access',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= BRAND CARD =================

  Widget _buildBrandCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, _cream],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.spa, color: _primaryDark, size: 25),
          ),

          const SizedBox(width: 13),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ceylon Heritage',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _primaryDark,
                    letterSpacing: -0.3,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Explore the stories of Sri Lanka',
                  style: TextStyle(fontSize: 10.5, color: _muted),
                ),
              ],
            ),
          ),

          const Icon(Icons.auto_stories_outlined, size: 22, color: _primary),
        ],
      ),
    );
  }

  // ================= HERITAGE IMAGE CARD =================

  Widget _buildHeritageImage(double width) {
    final imageHeight = (width * 0.43).clamp(145.0, 190.0).toDouble();

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: double.infinity,
              height: imageHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/heritage_login_banner.webp',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFFE7D0), Color(0xFFE9C19B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.spa, size: 85, color: _primaryDark),
                        ),
                      );
                    },
                  ),

                  // Soft image overlay
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x33000000),
                          Colors.transparent,
                          Color(0x66000000),
                        ],
                      ),
                    ),
                  ),

                  // Image label
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF3E6).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: _primaryDark,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'GALLE FORT • SRI LANKA',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: _primaryDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Image caption
                  const Positioned(
                    left: 14,
                    right: 14,
                    bottom: 13,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DISCOVER OUR HERITAGE',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Every place has a story to tell.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 7, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.menu_book_outlined, color: _primaryDark, size: 15),

                SizedBox(width: 7),

                Expanded(
                  child: Text(
                    'CEYLON HERITAGE JOURNAL',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: _primaryDark,
                    ),
                  ),
                ),

                Flexible(
                  child: Text(
                    'Explore • Discover • Experience',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 9, color: _muted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= LOGIN TITLE =================

  Widget _buildLoginTitle() {
    return const Padding(
      padding: EdgeInsets.only(top: 23, bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _text,
              letterSpacing: -0.8,
            ),
          ),

          SizedBox(height: 7),

          Text(
            'Sign in to continue your heritage journey.\n'
                'Explore places, manage tours and stay connected.',
            style: TextStyle(fontSize: 12, height: 1.6, color: _muted),
          ),
        ],
      ),
    );
  }

  // ================= LOGIN FORM =================

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Email, username or phone'),

        TextFormField(
          controller: _identifier,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _text,
          ),
          decoration: _inputDecoration(
            hint: 'name@example.com',
            icon: Icons.mail_outline_rounded,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter your email, username or phone';
            }
            return null;
          },
        ),

        const SizedBox(height: 17),

        Row(
          children: [
            Expanded(child: _fieldLabel('Password')),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: _primary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Forgot password?',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),

        TextFormField(
          controller: _password,
          obscureText: !_showPassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _text,
          ),
          decoration: _inputDecoration(
            hint: 'Enter your password',
            icon: Icons.lock_outline_rounded,
            suffix: IconButton(
              onPressed: () {
                setState(() {
                  _showPassword = !_showPassword;
                });
              },
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _muted,
                size: 19,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Enter your password';
            }
            return null;
          },
          onFieldSubmitted: (_) {
            if (!_loading && !_googleLoading) {
              _login();
            }
          },
        ),

        const SizedBox(height: 22),

        // Main login button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (_loading || _googleLoading) ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: _primary.withValues(alpha: 0.2),
              disabledBackgroundColor: _primary.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _loading
                ? const SizedBox(
              height: 21,
              width: 21,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),

                SizedBox(width: 9),

                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= DIVIDER =================

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 21),
      child: Row(
        children: [
          Expanded(child: Divider(color: _border)),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  color: _primaryDark,
                  size: 13,
                ),

                SizedBox(width: 5),

                Text(
                  'OR CONTINUE WITH',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),

          Expanded(child: Divider(color: _border)),
        ],
      ),
    );
  }

  // ================= GOOGLE BUTTON =================

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: (_googleLoading || _loading) ? null : _googleLogin,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _text,
          side: const BorderSide(color: _border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _googleLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _primary,
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'G',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),

            SizedBox(width: 12),

            Flexible(
              child: Text(
                'Continue with Google',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CREATE ACCOUNT =================

  Widget _buildCreateAccount() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEDFD1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignupScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: _primary,
                    size: 19,
                  ),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New to Ceylon Heritage?',
                        style: TextStyle(
                          fontSize: 12,
                          color: _text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      SizedBox(height: 3),

                      Text(
                        'Create your tourist account',
                        style: TextStyle(fontSize: 10.5, color: _muted),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEEDFD1)),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: _primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= GUIDE REQUEST =================

  Widget _buildGuideRequest() {
    return Container(
      margin: const EdgeInsets.only(top: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GuideRequestScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    color: _primaryDark,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Become a Heritage Guide',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _text,
                        ),
                      ),

                      SizedBox(height: 4),

                      Text(
                        'Request a guide account for admin review.',
                        style: TextStyle(fontSize: 10.5, color: _muted),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _primary,
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= FOOTER =================

  Widget _buildFooter() {
    return const Padding(
      padding: EdgeInsets.only(top: 27, bottom: 12),
      child: Column(
        children: [
          Divider(color: _border),

          SizedBox(height: 13),

          Text(
            'CEYLON HERITAGE',
            style: TextStyle(
              color: _primaryDark,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
            ),
          ),

          SizedBox(height: 5),

          Text(
            'Discover Sri Lanka. Preserve its stories.',
            style: TextStyle(color: _muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ================= MAIN UI =================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: _background,
      resizeToAvoidBottomInset: true,

      // Top Navigation Bar
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,

        leading: Navigator.of(context).canPop()
            ? IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _text),
          onPressed: () => Navigator.pop(context),
        )
            : null,

        title: const HeritageLogo(compact: true),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),

            child: Form(
              key: _formKey,

              child: ScrollConfiguration(
                behavior: const NoOverscrollScrollBehavior(),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header tag
                      _buildTopHeader(),

                      // Branding card
                      _buildBrandCard(),

                      // Cover image
                      _buildHeritageImage(
                        screenWidth > 460 ? 420 : screenWidth - 40,
                      ),

                      // Welcome title
                      _buildLoginTitle(),

                      // Login form
                      _buildLoginForm(),

                      // Divider
                      _buildDivider(),

                      // Google Login
                      _buildGoogleButton(),

                      // Sign Up
                      _buildCreateAccount(),

                      // Guide Registration Request
                      _buildGuideRequest(),

                      // Footer
                      _buildFooter(),
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
