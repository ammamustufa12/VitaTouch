import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/health_reading.dart';
import '../../providers/health_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/open_health_scan.dart';
import '../../widgets/app_card.dart';
import '../../widgets/demo_data_banner.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/trend_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthProvider>();
    final latest = health.latest;
    final chronological = health.readings.reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Monitor')),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            if (health.usingDemoData) ...[
              const DemoDataBanner(),
              const SizedBox(height: 14),
            ],
            if (health.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (latest == null)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.monitor_heart_outlined, color: AppColors.blue),
                    const SizedBox(height: 12),
                    Text(
                      'No demo reading yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Start a health scan and hold your finger on the screen for 5 seconds.',
                      style: TextStyle(color: AppColors.muted, height: 1.35),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () => openHealthScan(context),
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Start Health Scan'),
                    ),
                  ],
                ),
              )
            else ...[
              _StatusCard(reading: latest),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 360 ? 2 : 1;
                  final aspect = constraints.maxWidth >= 520 ? 1.35 : 0.98;
                  final caption = latest.isDemo
                      ? AppConstants.demoLabel
                      : latest.sourceLabel;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: aspect,
                    children: [
                      MetricCard(
                        icon: Icons.favorite_rounded,
                        color: AppColors.heart,
                        label: 'Heart rate',
                        value: '${latest.heartRateBpm}',
                        unit: 'BPM',
                        caption: caption,
                      ),
                      MetricCard(
                        icon: Icons.bubble_chart_outlined,
                        color: AppColors.blue,
                        label: 'SpO2',
                        value: latest.oxygenSaturation.toStringAsFixed(1),
                        unit: 'Oxygen %',
                        caption: caption,
                      ),
                      MetricCard(
                        icon: Icons.thermostat_rounded,
                        color: AppColors.teal,
                        label: 'Skin temperature',
                        value: latest.skinTemperatureCelsius.toStringAsFixed(1),
                        unit: '°C',
                        caption: caption,
                      ),
                      MetricCard(
                        icon: Icons.timeline,
                        color: AppColors.navySoft,
                        label: 'Pulse rate',
                        value: '${latest.pulseRateBpm}',
                        unit: 'BPM',
                        caption: caption,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              TrendChart(
                title: 'Heart rate',
                unit: 'Beats per minute · demo history',
                color: AppColors.heart,
                values: [
                  for (final reading in chronological)
                    reading.heartRateBpm.toDouble(),
                ],
                startLabel: chronological.length > 1
                    ? formatClock(chronological.first.recordedAt)
                    : null,
                endLabel: chronological.length > 1
                    ? formatClock(chronological.last.recordedAt)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                'Recorded ${formatDateTime(latest.recordedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                latest.statusDetail,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.reading});

  final HealthReading reading;

  @override
  Widget build(BuildContext context) {
    final typical = reading.displayBand == MonitoringBand.typical;
    final color = typical ? AppColors.teal : AppColors.amber;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Health monitoring status',
                  style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  reading.statusTitle,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
