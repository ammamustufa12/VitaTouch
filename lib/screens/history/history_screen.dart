import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/health_reading.dart';
import '../../providers/health_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/open_health_scan.dart';
import '../../widgets/app_card.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/trend_chart.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthProvider>();
    final chronological = health.readings.reversed.toList();
    final start = chronological.length > 1
        ? formatClock(chronological.first.recordedAt)
        : null;
    final end = chronological.length > 1
        ? formatClock(chronological.last.recordedAt)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Sync',
            onPressed: () => _sync(context),
            icon: const Icon(Icons.cloud_upload_outlined),
          ),
          IconButton(
            tooltip: 'Clear demo history',
            onPressed: health.readings.isEmpty ? null : () => _clear(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            if (health.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (health.loadError != null)
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
              )
            else ...[
              TrendChart(
                title: 'Heart rate history',
                unit: 'BPM · demo data',
                color: AppColors.heart,
                values: [
                  for (final reading in chronological)
                    reading.heartRateBpm.toDouble(),
                ],
                startLabel: start,
                endLabel: end,
              ),
              const SizedBox(height: 12),
              TrendChart(
                title: 'Oxygen level history',
                unit: 'SpO2 % · demo data',
                color: AppColors.blue,
                values: [
                  for (final reading in chronological) reading.oxygenSaturation,
                ],
                startLabel: start,
                endLabel: end,
              ),
              const SizedBox(height: 12),
              TrendChart(
                title: 'Temperature history',
                unit: 'Skin °C · demo data',
                color: AppColors.teal,
                values: [
                  for (final reading in chronological)
                    reading.skinTemperatureCelsius,
                ],
                startLabel: start,
                endLabel: end,
              ),
              const SizedBox(height: 16),
              Text('Previous scans', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (health.readings.isEmpty)
                const AppCard(
                  child: Text(
                    'No scans yet. A completed finger scan will appear here with its date and time.',
                    style: TextStyle(color: AppColors.muted, height: 1.35),
                  ),
                )
              else
                for (final reading in health.readings) ...[
                  _ScanTile(
                    reading: reading,
                    onTap: () => _showReading(context, reading),
                  ),
                  const SizedBox(height: 10),
                ],
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () => openHealthScan(context),
                icon: const Icon(Icons.fingerprint),
                label: const Text('Start Health Scan'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sync(BuildContext context) async {
    final result = await context.read<HealthProvider>().sync();
    if (!context.mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Server sync'),
          content: Text(result.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear demo history?'),
          content: const Text(
            'This removes simulated scans stored on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await context.read<HealthProvider>().clearHistory();
  }

  void _showReading(BuildContext context, HealthReading reading) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                formatDateTime(reading.recordedAt),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Text('Heart rate: ${reading.heartRateBpm} BPM'),
              Text('Pulse rate: ${reading.pulseRateBpm} BPM'),
              Text('SpO2: ${reading.oxygenSaturation.toStringAsFixed(1)}%'),
              Text(
                'Skin temperature: ${reading.skinTemperatureCelsius.toStringAsFixed(1)} °C',
              ),
              if (!reading.isDemo) ...[
                const SizedBox(height: 8),
                Text(
                  reading.sourceLabel,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(reading.statusDetail, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }
}

class _ScanTile extends StatelessWidget {
  const _ScanTile({required this.reading, required this.onTap});

  final HealthReading reading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.favorite_rounded, color: AppColors.heart),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDateTime(reading.recordedAt),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${reading.heartRateBpm} BPM · ${reading.oxygenSaturation.toStringAsFixed(1)}% · ${reading.skinTemperatureCelsius.toStringAsFixed(1)} °C',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            reading.isDemo ? 'DEMO' : 'SENSOR',
            style: const TextStyle(
              color: AppColors.demo,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
