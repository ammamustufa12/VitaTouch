import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/navigation/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'screens/scanning/scanning_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/touch/touch_point_screen.dart';
import 'screens/touch/touch_to_load_screen.dart';

class SmartHealthApp extends StatelessWidget {
  const SmartHealthApp({super.key, this.home});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: home ?? const SplashScreen(),
      routes: {
        AppRoutes.scan: (context) => const ScanningScreen(),
        AppRoutes.touchLoad: (context) => const TouchToLoadScreen(),
        AppRoutes.touchPoint: (context) => const TouchPointScreen(),
      },
    );
  }
}
