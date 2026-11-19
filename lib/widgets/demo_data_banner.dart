import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class DemoDataBanner extends StatelessWidget {
  const DemoDataBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.demoBg,
          borderRadius: BorderRadius.all(Radius.circular(8)),
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.demoBorder),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(
            'DEMO DATA',
            style: TextStyle(
              color: AppColors.demo,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}
