import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/navigation/member4_navigation_screen.dart';

/// Standalone entry point for reviewing Member 4's route flow.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(debugShowCheckedModeBanner: false,
    title: 'HeritageGuide', theme: AppTheme.light,
    home: const Member4NavigationScreen(storageScope: 'demo')));
}
