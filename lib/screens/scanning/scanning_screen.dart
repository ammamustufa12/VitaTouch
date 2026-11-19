import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/health_reading.dart';
import '../../providers/health_provider.dart';
import '../../services/sensor_service.dart';
import '../../widgets/demo_data_banner.dart';
import '../../widgets/fingerprint_art.dart';
import '../../widgets/responsive_body.dart';

class ScanningScreen extends StatefulWidget {
  const ScanningScreen({
    super.key,
    this.scanDuration = AppConstants.demoScanDuration,
  });

  static final touchKey = GlobalKey();

  final Duration scanDuration;

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

enum _ScanPhase { ready, scanning, complete, interrupted, failed }

class _ScanningScreenState extends State<ScanningScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  _ScanPhase _phase = _ScanPhase.ready;
  double _progress = 0;
  HealthReading? _reading;
  String? _error;
  String? _miss;
  final Set<int> _inside = <int>{};
  int _pointers = 0;
  int _peakFingers = 0;
  bool _hold = false;
  bool _busy = false;
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
    _pulse.dispose();
    super.dispose();
  }

  bool _onCircle(Offset global) {
    final box = ScanningScreen.touchKey.currentContext?.findRenderObject()
        as RenderBox?;
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
    final started = _inside.isEmpty;
    setState(() {
      _miss = null;
      _inside.add(event.pointer);
      _pointers = _inside.length;
      if (_pointers > _peakFingers) {
        _peakFingers = _pointers;
      }
    });
    if (!started ||
        _phase == _ScanPhase.scanning ||
        _phase == _ScanPhase.complete) {
      return;
    }
    _begin();
  }

  void _pointerUp(PointerEvent event) {
    if (!_inside.remove(event.pointer)) {
      return;
    }
    setState(() => _pointers = _inside.length);
    if (_pointers == 0) {
      _hold = false;
    }
  }

  int get _detailLevel {
    final live = _pointers > 5 ? 5 : _pointers;
    if (live > 0) {
      return live;
    }
    final peak = _peakFingers > 5 ? 5 : _peakFingers;
    return peak;
  }

  Future<void> _begin() async {
    if (_busy || _phase == _ScanPhase.complete) {
      return;
    }
    final generation = ++_generation;
    _busy = true;
    _hold = true;
    setState(() {
      _phase = _ScanPhase.scanning;
      _progress = 0;
      _reading = null;
      _error = null;
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
        _phase = _ScanPhase.complete;
        _progress = 1;
        _reading = reading;
      });
    } on ScanCancelled {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _phase = _ScanPhase.interrupted;
        _progress = 0;
      });
    } on ScanFailed catch (error) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _phase = _ScanPhase.failed;
        _error = error.message;
        _progress = 0;
      });
    } catch (_) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _phase = _ScanPhase.failed;
        _error = 'The demo scan could not be completed.';
        _progress = 0;
      });
    } finally {
      _busy = false;
    }
  }

  String get _instruction {
    switch (_phase) {
      case _ScanPhase.ready:
        return 'Place your finger on the screen.';
      case _ScanPhase.scanning:
        return 'Hold still. Simulated scan in progress.';
      case _ScanPhase.interrupted:
        return 'Finger lifted. Place your finger on the screen to try again.';
      case _ScanPhase.failed:
        return _error ?? 'The demo scan could not be completed.';
      case _ScanPhase.complete:
        return 'Demo scan complete.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final reading = _reading;
    return PopScope(
      canPop: _phase != _ScanPhase.scanning,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _hold = false;
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Health Scan')),
        body: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _pointerDown,
          onPointerUp: _pointerUp,
          onPointerCancel: _pointerUp,
          child: ResponsiveBody(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: DemoDataBanner(),
              ),
              Expanded(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          _instruction,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                            height: 1.35,
                          ),
                        ),
                        if (_miss != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _miss!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.heart,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                        if (_pointers > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            _pointers == 1
                                ? '1 finger detected'
                                : '$_pointers fingers detected',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.teal,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Text(
                          'This does not identify a person. It only detects contact.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final shortest = constraints.maxWidth <
                                      constraints.maxHeight
                                  ? constraints.maxWidth
                                  : constraints.maxHeight;
                              final diameter = shortest > 280 ? 280.0 : shortest;
                              if (diameter < 72) {
                                return const SizedBox.shrink();
                              }
                              return Center(
                                child: AnimatedBuilder(
                                  animation: _pulse,
                                  builder: (context, child) {
                                    return Container(
                                      key: ScanningScreen.touchKey,
                                      width: diameter,
                                      height: diameter,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        border: Border.all(
                                          color: _phase == _ScanPhase.scanning
                                              ? AppColors.blue
                                              : AppColors.line,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.blue.withValues(
                                              alpha: 0.12,
                                            ),
                                            blurRadius: 24,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(18),
                                        child: FingerprintArt(
                                          progress: _phase == _ScanPhase.scanning
                                              ? _progress
                                              : _pulse.value,
                                          scanning:
                                              _phase == _ScanPhase.scanning,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        if (_phase == _ScanPhase.scanning) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: _progress,
                              minHeight: 8,
                              backgroundColor: AppColors.line,
                              color: AppColors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Simulated scan ${(_progress * 100).round()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              if (reading != null && _phase == _ScanPhase.complete)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: _ResultPanel(
                    reading: reading,
                    level: _detailLevel,
                  ),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.reading, required this.level});

  final HealthReading reading;
  final int level;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      if (level >= 1) 'Heart rate ${reading.heartRateBpm} BPM',
      if (level >= 2) 'SpO2 ${reading.oxygenSaturation.toStringAsFixed(1)}%',
      if (level >= 3)
        'Skin ${reading.skinTemperatureCelsius.toStringAsFixed(1)} °C',
      if (level >= 4) 'Pulse ${reading.pulseRateBpm} BPM',
      if (level >= 5) reading.statusTitle,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DEMO DATA',
                style: TextStyle(
                  color: AppColors.demo,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    line,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              if (level < 5)
                const Text(
                  'Add another finger for more detail.',
                  style: TextStyle(color: AppColors.muted),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(reading),
          child: const Text('View dashboard'),
        ),
      ],
    );
  }
}
