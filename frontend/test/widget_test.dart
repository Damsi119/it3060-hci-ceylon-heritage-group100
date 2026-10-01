import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/screens/auth/login_screen.dart';

void main() {
  testWidgets('shows the login screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
    );
    await tester.pump();

    expect(find.text('Login'), findsOneWidget);
  });
}
