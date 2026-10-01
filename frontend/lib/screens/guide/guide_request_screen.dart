import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/api_client.dart';
import '../../services/guide_service.dart';
import '../../widgets/auth_shell.dart';
import '../../widgets/heritage_badge.dart';
import '../../widgets/heritage_button.dart';
import '../../widgets/heritage_card.dart';
import '../../widgets/heritage_message.dart';
import '../../widgets/heritage_section_title.dart';
import '../../widgets/heritage_text_field.dart';

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
  bool _submitted = false;

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await GuideService.instance.submitRequest(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        primaryServiceArea: _area.text.trim(),
        languages: _languages.text.trim(),
        experience: _experience.text.trim(),
      );
      if (!mounted) return;
      setState(() => _submitted = true);
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return AuthShell(
        showBack: true,
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.greenSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                color: AppColors.green,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const HeritageSectionTitle(
              title: 'Guide request submitted',
              subtitle:
                  'Your application is now pending admin review. We will contact you using the details you provided.',
            ),
            const SizedBox(height: 18),
            const HeritageCard(
              color: AppColors.surfaceWarm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What happens next?',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Admin reviews your guide information.\n2. You may be contacted by phone or email.\n3. Approved requests receive a guide account and temporary password by email.\n4. On first login, you choose your own permanent password.',
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.55,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            HeritageSecondaryButton(
              label: 'Back to login',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }

    String? required(String? value) =>
        value == null || value.trim().isEmpty ? 'Required' : null;

    return AuthShell(
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeritageBadge(
              label: 'Local Guide Registry',
              icon: Icons.explore_outlined,
            ),
            const SizedBox(height: 10),
            const HeritageSectionTitle(
              title: 'Request as a Guide',
              subtitle:
                  'Tell us about your local knowledge. Guide accounts are created only after admin review.',
            ),
            const SizedBox(height: 14),
            const HeritageCard(
              color: AppColors.greenSoft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_outlined, color: AppColors.green),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No password is needed at this stage. If approved, the system creates your GUIDE account and sends temporary credentials to your email.',
                      style: TextStyle(fontSize: 10.3, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            HeritageTextField(
              controller: _name,
              label: 'Full name',
              hint: 'Eranga Silva',
              icon: Icons.person_outline,
              validator: required,
            ),
            const SizedBox(height: 12),
            HeritageTextField(
              controller: _email,
              label: 'Email',
              hint: 'guide@example.com',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (required(value) != null) return 'Required';
                return value!.contains('@') ? null : 'Enter a valid email';
              },
            ),
            const SizedBox(height: 12),
            HeritageTextField(
              controller: _phone,
              label: 'Phone number',
              hint: '07XXXXXXXX',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: required,
            ),
            const SizedBox(height: 12),
            HeritageTextField(
              controller: _area,
              label: 'Primary service area',
              hint: 'Galle Fort / Kandy / Sigiriya',
              icon: Icons.place_outlined,
              validator: required,
            ),
            const SizedBox(height: 12),
            HeritageTextField(
              controller: _languages,
              label: 'Languages',
              hint: 'Sinhala, English, Tamil',
              icon: Icons.translate_rounded,
              validator: required,
            ),
            const SizedBox(height: 12),
            HeritageTextField(
              controller: _experience,
              label: 'Guide experience',
              hint: 'Describe your local knowledge and guiding experience...',
              icon: Icons.history_edu_outlined,
              maxLines: 5,
              validator: required,
            ),
            const SizedBox(height: 18),
            HeritagePrimaryButton(
              label: 'Submit guide request',
              onPressed: _submit,
              loading: _loading,
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Requests are reviewed manually to keep the guide registry trusted.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9.8, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
