import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/health_reading.dart';
import '../../providers/health_provider.dart';
import '../../services/sensor_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/fingerprint_art.dart';

class ScanStation extends StatefulWidget {
  const ScanStation({
    super.key,
    this.scanDuration = AppConstants.demoScanDuration,
  });

  static final touchKey = GlobalKey();

  final Duration scanDuration;

  @override
  State<ScanStation> createState() => _ScanStationState();
}

enum _StationPhase { ready, scanning, failed }

class _ScanStationState extends State<ScanStation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  _StationPhase _phase = _StationPhase.ready;
  double _progress = 0;
  HealthReading? _reading;
  String? _error;
  String? _miss;
  bool _busy = false;
  bool _hold = false;
  bool _showNumbers = false;
  bool _showDetails = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _hold = false;
    _generation += 1;
    _pulse.dispose();
    super.dispose();
  }

  bool _onCircle(Offset global) {
    final box =
        ScanStation.touchKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) {
      return false;
    }
    final local = box.globalToLocal(global);
    final radius = box.size.shortestSide / 2;
    return (local - box.size.center(Offset.zero)).distance <= radius;
  }

  void _pointerDown(PointerDownEvent event) {
    if (!_onCircle(event.position)) {
      setState(() => _miss = 'Touch the circle.');
      return;
    }
    if (_miss != null) {
      setState(() => _miss = null);
    }
    if (_phase == _StationPhase.scanning) {
      return;
    }
    _begin();
  }

  Future<void> _begin() async {
    if (_busy) {
      return;
    }
    final generation = ++_generation;
    _busy = true;
    _hold = true;
    setState(() {
      _phase = _StationPhase.scanning;
      _progress = 0;
      _reading = null;
      _error = null;
      _showNumbers = false;
      _showDetails = false;
    });

    final provider = context.read<HealthProvider>();
    try {
      final reading = await provider.runScan(
        SensorCaptureRequest(
          duration: widget.scanDuration,
          shouldContinue: () => _hold && mounted,
          onProgress: (value) {
            if (!mounted || generation != _generation) {
              return;
            }
            setState(() => _progress = value);
          },
        ),
      );
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _phase = _StationPhase.ready;
        _progress = 1;
        _reading = reading;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || generation != _generation) {
          return;
        }
        setState(() => _showNumbers = true);
      });
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() => _showDetails = true);
    } on ScanCancelled {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _phase = _StationPhase.ready;
        _progress = 0;
      });
    } on ScanFailed catch (error) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _phase = _StationPhase.failed;
        _error = error.message;
        _progress = 0;
      });
    } catch (_) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _phase = _StationPhase.failed;
        _error = 'The demo scan could not be completed.';
        _progress = 0;
      });
    } finally {
      _busy = false;
      _hold = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reading = _reading;
    final showReady = _phase != _StationPhase.scanning &&
        (reading == null || _showDetails);
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _pointerDown,
      child: ColoredBox(
      color: AppColors.navy,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 18),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final shortest = constraints.maxWidth <
                                  constraints.maxHeight
                              ? constraints.maxWidth
                              : constraints.maxHeight;
                          final diameter = shortest > 280
                              ? 280.0
                              : (shortest < 96 ? 96.0 : shortest);
                          final scanning = _phase == _StationPhase.scanning;
                          return Center(
                            child: AnimatedBuilder(
                              animation: _pulse,
                              builder: (context, child) {
                                return Container(
                                  key: ScanStation.touchKey,
                                  width: diameter,
                                  height: diameter,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                          alpha: scanning ? 0.28 : 0.12,
                                        ),
                                        blurRadius: scanning ? 32 : 18,
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(22),
                                    child: FingerprintArt(
                                      progress: scanning
                                          ? _progress
                                          : _pulse.value,
                                      scanning: scanning,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedOpacity(
                      opacity: showReady || _phase == _StationPhase.failed
                          ? 1
                          : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        _phase == _StationPhase.failed
                            ? (_error ?? 'Scan failed')
                            : 'Ready to scan',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    if (_miss != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _miss!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFF8A80),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 8,
                      child: _phase == _StationPhase.scanning
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: _progress,
                                minHeight: 8,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.16),
                                color: Colors.white,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 28),
            Expanded(
              flex: 6,
              child: reading == null
                  ? const SizedBox.expand()
                  : _ReadingPanel(
                      reading: reading,
                      showNumbers: _showNumbers,
                      showDetails: _showDetails,
                    ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _ReadingPanel extends StatelessWidget {
  const _ReadingPanel({
    required this.reading,
    required this.showNumbers,
    required this.showDetails,
  });

  final HealthReading reading;
  final bool showNumbers;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showNumbers)
              Row(
                children: [
                  Expanded(
                    child: _Figure(
                      label: 'Heart rate',
                      value: '${reading.heartRateBpm}',
                      unit: 'BPM',
                      color: AppColors.heart,
                    ),
                  ),
                  Expanded(
                    child: _Figure(
                      label: 'SpO2',
                      value: reading.oxygenSaturation.toStringAsFixed(0),
                      unit: '%',
                      color: AppColors.blue,
                    ),
                  ),
                  Expanded(
                    child: _Figure(
                      label: 'Skin',
                      value: reading.skinTemperatureCelsius.toStringAsFixed(1),
                      unit: '°C',
                      color: AppColors.teal,
                    ),
                  ),
                ],
              ),
            if (showDetails) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.line),
              const SizedBox(height: 12),
              Text(
                'Pulse ${reading.pulseRateBpm} BPM',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                reading.statusTitle,
                style: const TextStyle(
                  color: AppColors.text,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formatDateTime(reading.recordedAt),
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              const Text(
                'DEMO DATA',
                style: TextStyle(
                  color: AppColors.demo,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 44,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
