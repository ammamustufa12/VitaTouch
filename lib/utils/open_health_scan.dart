import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/navigation/app_routes.dart';
import '../models/health_reading.dart';
import '../providers/shell_controller.dart';

Future<void> openHealthScan(BuildContext context) async {
  final result = await Navigator.of(context).pushNamed(AppRoutes.scan);
  if (!context.mounted || result is! HealthReading) {
    return;
  }
  context.read<ShellController>().openTab(1);
}
