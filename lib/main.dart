import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/sign_in_screen.dart';

void main() {
  runApp(const WellQueueApp());
}

class WellQueueApp extends StatelessWidget {
  const WellQueueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WellQueue',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SignInScreen(),
    );
  }
}
