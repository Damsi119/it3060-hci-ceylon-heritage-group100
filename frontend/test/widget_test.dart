import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/screens/auth/login_screen.dart';
import 'package:frontend/widgets/otp_code_input.dart';

void _setSurfaceSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets('shows the login screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
    );
    await tester.pump();

    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('login screen fits a narrow phone viewport', (tester) async {
    _setSurfaceSize(tester, const Size(320, 640));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('OTP code input shrinks for very narrow screens', (tester) async {
    _setSurfaceSize(tester, const Size(240, 300));
    final controller = TextEditingController(text: '123');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OtpCodeInput(controller: controller),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
