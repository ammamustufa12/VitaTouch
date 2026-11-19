import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_colors.dart';

class TouchToLoadScreen extends StatelessWidget {
  const TouchToLoadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(title: const Text('Touch to load')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Material(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.touchPoint),
              child: const SizedBox(
                width: 280,
                height: 180,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app, color: Colors.white, size: 42),
                    SizedBox(height: 12),
                    Text(
                      'Touch to load',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
