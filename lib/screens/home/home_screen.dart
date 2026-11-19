import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/touch_signal.dart';
import '../../providers/health_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/bluetooth_service.dart';
import '../../utils/formatters.dart';
import '../../core/navigation/app_routes.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/responsive_body.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthProvider>();
    final profile = context.watch<ProfileProvider>();
    final bluetooth = context.watch<BluetoothService>();
    final name = profile.profile.name.trim();
    final greeting = greetingFor(DateTime.now());
    final title = name.isEmpty ? greeting : '$greeting, $name';
    final latest = health.latest;

    return Scaffold(
      backgroundColor: AppColors.mist,
      body: ResponsiveBody(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Row(
                children: [
                  const AppLogo(size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text(
                          'Smart Health Monitor',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.navy, AppColors.navySoft],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Finger-touch health scan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Open the touch screen, then place a finger on the center circle.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.navy,
                      ),
                      onPressed: () =>
                          Navigator.of(context).pushNamed(AppRoutes.touchLoad),
                      icon: const Icon(Icons.touch_app),
                      label: const Text('Touch to load'),
                    ),
                  ],
                ),
              ),
              if (health.loadError != null) ...[
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(health.loadError!),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: health.initialize,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _CardTitle(
                      icon: Icons.touch_app_outlined,
                      title: 'Touch detection',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      health.touch.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Detection uses the screen, not fingerprint identification.',
                      style: TextStyle(color: AppColors.muted, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _CardTitle(
                      icon: Icons.schedule_outlined,
                      title: 'Last scan',
                    ),
                    const SizedBox(height: 10),
                    if (health.loading)
                      const LinearProgressIndicator(minHeight: 3)
                    else if (latest == null)
                      const Text(
                        'No scan yet',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else ...[
                      Text(
                        formatDateTime(latest.recordedAt),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Heart rate ${latest.heartRateBpm} BPM · SpO2 ${latest.oxygenSaturation.toStringAsFixed(1)}%',
                      ),
                      if (!latest.isDemo) ...[
                        const SizedBox(height: 6),
                        Text(
                          latest.sourceLabel,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CardTitle(
                      icon: bluetooth.isReadyForReadings
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      title: 'External sensor',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      bluetooth.detail,
                      style: const TextStyle(height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: bluetooth.phase == BluetoothLinkPhase.checking
                          ? null
                          : () => bluetooth.checkForHardware(),
                      child: Text(
                        bluetooth.phase == BluetoothLinkPhase.checking
                            ? 'Checking…'
                            : 'Check for sensor',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CardTitle(
                      icon: Icons.health_and_safety_outlined,
                      title: 'Monitoring overview',
                    ),
                    SizedBox(height: 12),
                    _OverviewRow(
                      icon: Icons.favorite_outline,
                      label: 'Heart rate and pulse',
                      detail: 'Shown in beats per minute from the demo scan.',
                    ),
                    SizedBox(height: 10),
                    _OverviewRow(
                      icon: Icons.water_drop_outlined,
                      label: 'SpO2',
                      detail: 'Oxygen saturation prepared for a future MAX30102 link.',
                    ),
                    SizedBox(height: 10),
                    _OverviewRow(
                      icon: Icons.thermostat_outlined,
                      label: 'Skin temperature',
                      detail: 'A surface reading, separate from core body temperature.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.blue, size: 20),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.navy),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(detail, style: const TextStyle(color: AppColors.muted, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}
