import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_profile.dart';
import '../../services/api_client.dart';
import '../../services/user_service.dart';
import '../../widgets/heritage_app_bar.dart';
import '../../widgets/heritage_button.dart';
import '../../widgets/heritage_card.dart';
import '../../widgets/heritage_message.dart';
import '../../widgets/heritage_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final UserProfile user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: widget.user.firstName ?? '');
    _lastName = TextEditingController(text: widget.user.lastName ?? '');
    _phone = TextEditingController(text: widget.user.phone ?? '');
    _address = TextEditingController(text: widget.user.address ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final updated = await UserService.instance.updateProfile(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
      );
      if (!mounted) return;
      showHeritageMessage(context, 'Profile updated successfully');
      Navigator.pop(context, updated);
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeritageAppBar(showBack: true),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            HeritageCard(
              color: AppColors.surfaceSoft,
              child: Row(
                children: [
                  const Icon(
                    Icons.mail_outline_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.user.email,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            HeritageCard(
              child: Column(
                children: [
                  HeritageTextField(
                    controller: _firstName,
                    label: 'First name',
                    icon: Icons.person_outline,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  HeritageTextField(
                    controller: _lastName,
                    label: 'Last name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  HeritageTextField(
                    controller: _phone,
                    label: 'Phone',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  HeritageTextField(
                    controller: _address,
                    label: 'Address',
                    icon: Icons.place_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            HeritagePrimaryButton(
              label: 'Save changes',
              icon: Icons.check_rounded,
              onPressed: _save,
              loading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}
