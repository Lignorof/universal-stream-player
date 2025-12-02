import 'package:flutter/material.dart';
import 'main.dart' show UniversalStreamPlayerApp;

/// Compatibility wrapper used by tests that expect `MyApp`.
/// Keeps a const constructor so test/widget_test.dart that calls `const MyApp()` works.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuse the existing UniversalStreamPlayerApp to avoid duplicating setup.
    return const UniversalStreamPlayerApp();
  }
}
