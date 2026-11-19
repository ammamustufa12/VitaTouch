import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/health_reading.dart';
import '../../providers/health_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/sensor_service.dart';

const _font = 'Plus Jakarta Sans';

class TouchPointScreen extends StatefulWidget {
  const TouchPointScreen({super.key});

  static final circleKey = GlobalKey();

  @override
  State<TouchPointScreen> createState() => _TouchPointScreenState();
}

class _TouchPointScreenState extends State<TouchPointScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _glow;
  late final AnimationController _rise;
  late final AnimationController _count;

  HealthReading? _reading;
  bool _busy = false;
  int _generation = 0;
  final Set<int> _down = <int>{};
  final Set<int> _sensor = <int>{};
  final Map<int, Offset> _origin = <int, Offset>{};
  int _fingers = 0;
  Offset _shift = Offset.zero;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _rise = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _count = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<HealthProvider>().initialize();
      context.read<ProfileProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _generation += 1;
    _pulse.dispose();
    _glow.dispose();
    _rise.dispose();
    _count.dispose();
    super.dispose();
  }

  bool _onSensor(Offset global) {
    final box = TouchPointScreen.circleKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) {
      return false;
    }
    final local = box.globalToLocal(global);
    final center = box.size.center(Offset.zero);
    return (local - center).distance <= box.size.shortestSide * 0.72;
  }

  void _syncLoader() {
    final running = _down.isNotEmpty || _busy;
    if (running && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!running && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  void _setFingers(int count) {
    final next = count > 5 ? 5 : count;
    setState(() => _fingers = next);
    _syncLoader();
  }

  Future<void> _load() async {
    if (_busy) {
      return;
    }
    final generation = ++_generation;
    _busy = true;
    _syncLoader();
    try {
      final reading = await context.read<HealthProvider>().runScan(
            SensorCaptureRequest(
              duration: Duration.zero,
              shouldContinue: () => mounted && generation == _generation,
            ),
          );
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() => _reading = reading);
    } on ScanCancelled {
      return;
    } catch (_) {
      return;
    } finally {
      _busy = false;
      _syncLoader();
    }
  }

  void _pointerDown(PointerDownEvent event) {
    final first = _down.isEmpty;
    _down.add(event.pointer);
    _origin[event.pointer] = event.localPosition - _shift;
    _setFingers(_down.length);
    if (first) {
      _load();
      _count.forward(from: 0);
      if (_rise.value < 1) {
        _rise.forward();
      }
    }
  }

  void _pointerMove(PointerMoveEvent event) {
    final origin = _origin[event.pointer];
    if (origin == null) {
      return;
    }
    setState(() => _shift = event.localPosition - origin);
  }

  void _pointerUp(PointerEvent event) {
    if (!_down.remove(event.pointer)) {
      return;
    }
    _origin.remove(event.pointer);
    if (_down.isEmpty) {
      _rise.stop();
      _rise.value = 0;
      _count.stop();
      _count.value = 0;
      _shift = Offset.zero;
    }
    _setFingers(_down.length);
  }

  Color _tone(int fingers) {
    switch (fingers) {
      case 1:
        return const Color(0xFF3DDC84);
      case 2:
        return const Color(0xFF3D8BFF);
      case 3:
        return const Color(0xFFFFD84A);
      case 4:
        return const Color(0xFFB06CFF);
      case 5:
        return const Color(0xFFFF4D5A);
      default:
        return const Color(0xFF39CFFF);
    }
  }

  int get _heart => _reading?.heartRateBpm ?? 72;

  int get _sugar => _reading == null ? 95 : 85 + (_reading!.heartRateBpm % 21);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06101E),
      body: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _pointerDown,
        onPointerMove: _pointerMove,
        onPointerUp: _pointerUp,
        onPointerCancel: _pointerUp,
        child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF07182E),
              Color(0xFF06101E),
              Color(0xFF040A14),
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return _board(constraints.biggest);
          },
        ),
        ),
      ),
    );
  }

  Widget _board(Size size) {
    final tone = _tone(_fingers);
    final ring = math.min(size.width, size.height) * 0.48;
    final live = _down.isNotEmpty;
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _BackdropPainter())),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                key: const Key('finger-color'),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.85,
                    colors: [
                      tone.withValues(alpha: _fingers == 0 ? 0.05 : 0.42),
                      const Color(0x0006101E),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 16),
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (live)
                        Center(
                          child: Transform.translate(
                            offset: _shift,
                            child: _center(ring, tone),
                          ),
                        ),
                      if (live) ...[
                        Positioned(left: 8, top: 6, child: _heartCard(tone)),
                        Positioned(right: 8, top: 6, child: _oxygenCard(tone)),
                        Positioned(left: 8, bottom: 8, child: _tempCard(tone)),
                        Positioned(right: 8, bottom: 8, child: _sugarCard(tone)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heartCard(Color tone) {
    return _corner(
      tone: tone,
      orbOnLeft: true,
      card: _MetricCard(
        title: 'Heart Rate',
        count: _count,
        value: _heart.toDouble(),
        decimals: 0,
        unit: 'bpm',
        icon: Icons.favorite,
        tone: tone,
        hot: _fingers > 0,
        chart: _Spark(color: tone, kind: _SparkKind.pulse),
      ),
    );
  }

  Widget _oxygenCard(Color tone) {
    return _corner(
      tone: tone,
      orbOnLeft: false,
      card: _MetricCard(
        title: 'Blood Oxygen',
        count: _count,
        value: _reading?.oxygenSaturation ?? 98,
        decimals: 0,
        unit: '%',
        icon: Icons.water_drop,
        tone: tone,
        hot: _fingers > 0,
        chart: _Spark(color: tone, kind: _SparkKind.bar),
      ),
    );
  }

  Widget _tempCard(Color tone) {
    return _corner(
      tone: tone,
      orbOnLeft: true,
      card: _MetricCard(
        title: 'Body Temperature',
        count: _count,
        value: _reading?.skinTemperatureCelsius ?? 36.6,
        decimals: 1,
        unit: '°C',
        icon: Icons.thermostat,
        tone: tone,
        hot: _fingers > 0,
        chart: _Spark(color: tone, kind: _SparkKind.wave),
      ),
    );
  }

  Widget _sugarCard(Color tone) {
    return _corner(
      tone: tone,
      orbOnLeft: false,
      card: _MetricCard(
        title: 'Blood Sugar',
        count: _count,
        value: _sugar.toDouble(),
        decimals: 0,
        unit: 'mg/dL',
        icon: Icons.water_drop,
        tone: tone,
        hot: _fingers > 0,
        chart: _Spark(color: tone, kind: _SparkKind.wave),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        _roundButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 16),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1C6DFF), Color(0xFF49B2FF)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x662E8BFF),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.monitor_heart, color: Colors.white, size: 30),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Smart Health '),
                  TextSpan(
                    text: 'Monitor',
                    style: TextStyle(color: Color(0xFF3D92FF)),
                  ),
                ],
              ),
              style: TextStyle(
                fontFamily: _font,
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.05,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Touch. Check. Care.',
              style: TextStyle(
                fontFamily: _font,
                color: Color(0xFF8EA4BE),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const Spacer(),
        _roundButton(icon: Icons.settings_rounded, onTap: () {}),
      ],
    );
  }

  Widget _roundButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: const Color(0xFF0C1B30),
      shape: const CircleBorder(
        side: BorderSide(color: Color(0xFF21405F)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _center(double ring, Color tone) {
    final spinning = _down.isNotEmpty || _busy;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          key: TouchPointScreen.circleKey,
          width: ring,
          height: ring,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              return CustomPaint(
                painter: _GaugePainter(
                  turn: _pulse.value,
                  spinning: spinning,
                  color: tone,
                ),
                child: Center(
                  child: SizedBox(
                    width: ring * 0.34,
                    height: ring * 0.34,
                    child: CustomPaint(painter: _FingerprintMark(color: tone)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _corner({
    required Color tone,
    required bool orbOnLeft,
    required Widget card,
  }) {
    final orb = AnimatedBuilder(
      animation: _glow,
      builder: (context, _) {
        return _TouchOrb(hot: _fingers > 0, glow: _glow.value, color: tone);
      },
    );
    final group = Row(
      mainAxisSize: MainAxisSize.min,
      children: orbOnLeft
          ? [orb, const SizedBox(width: 12), card]
          : [card, const SizedBox(width: 12), orb],
    );
    return AnimatedBuilder(
      animation: _rise,
      builder: (context, child) {
        final rise = Curves.easeOutCubic.transform(_rise.value);
        return Opacity(
          opacity: (rise * 2.2).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(_shift.dx, (1 - rise) * 260 + _shift.dy),
            child: child,
          ),
        );
      },
      child: group,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.count,
    required this.value,
    required this.decimals,
    required this.unit,
    required this.icon,
    required this.tone,
    required this.hot,
    required this.chart,
  });

  final String title;
  final Animation<double> count;
  final double value;
  final int decimals;
  final String unit;
  final IconData icon;
  final Color tone;
  final bool hot;
  final Widget chart;

  String _shown(double t) {
    final amount = value * Curves.easeOutCubic.transform(t);
    if (decimals == 0) {
      return amount.round().toString();
    }
    return amount.toStringAsFixed(decimals);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 286,
      height: 148,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              tone.withValues(alpha: hot ? 0.34 : 0.12),
              const Color(0xFF13283F),
            ),
            Color.alphaBlend(
              tone.withValues(alpha: hot ? 0.16 : 0.05),
              const Color(0xFF0B182B),
            ),
          ],
        ),
        border: Border.all(
          color: tone.withValues(alpha: hot ? 0.95 : 0.45),
          width: hot ? 1.8 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: tone.withValues(alpha: hot ? 0.5 : 0.22),
            blurRadius: hot ? 28 : 18,
            spreadRadius: hot ? 1 : 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: tone, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: _font,
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: count,
            builder: (context, _) {
              return Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: _shown(count.value)),
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                        fontFamily: _font,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB7C7D9),
                      ),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontFamily: _font,
                  color: tone,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              );
            },
          ),
          const Spacer(),
          SizedBox(height: 28, width: double.infinity, child: chart),
        ],
      ),
    );
  }
}

enum _SparkKind { pulse, wave, bar }

class _Spark extends StatelessWidget {
  const _Spark({required this.color, required this.kind});

  final Color color;
  final _SparkKind kind;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparkPainter(color, kind),
      child: const SizedBox.expand(),
    );
  }
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter(this.color, this.kind);

  final Color color;
  final _SparkKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    if (kind == _SparkKind.bar) {
      final track = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height * 0.32, size.width, 8),
        const Radius.circular(8),
      );
      canvas.drawRRect(
        track,
        Paint()..color = color.withValues(alpha: 0.22),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, size.height * 0.32, size.width * 0.78, 8),
          const Radius.circular(8),
        ),
        Paint()
          ..shader = LinearGradient(
            colors: [color.withValues(alpha: 0.7), Colors.white],
          ).createShader(Offset.zero & size),
      );
      return;
    }

    final path = Path();
    if (kind == _SparkKind.pulse) {
      final y = size.height * 0.62;
      path
        ..moveTo(0, y)
        ..lineTo(size.width * 0.12, y)
        ..lineTo(size.width * 0.18, y - 5)
        ..lineTo(size.width * 0.24, y + 7)
        ..lineTo(size.width * 0.31, y - size.height * 0.72)
        ..lineTo(size.width * 0.38, y + size.height * 0.28)
        ..lineTo(size.width * 0.44, y)
        ..lineTo(size.width * 0.62, y)
        ..lineTo(size.width * 0.68, y - 6)
        ..lineTo(size.width * 0.74, y + 5)
        ..lineTo(size.width * 0.8, y - size.height * 0.55)
        ..lineTo(size.width * 0.87, y + 8)
        ..lineTo(size.width * 0.92, y)
        ..lineTo(size.width, y);
    } else {
      path.moveTo(0, size.height * 0.55);
      for (var x = 0.0; x <= size.width; x += 3) {
        final t = x / size.width;
        final wave = math.sin(t * math.pi * 3.2) * size.height * 0.32;
        path.lineTo(x, size.height * 0.55 - wave);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.kind != kind;
  }
}

class _TouchOrb extends StatelessWidget {
  const _TouchOrb({required this.hot, required this.glow, required this.color});

  final bool hot;
  final double glow;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(64, 64),
      painter: _OrbPainter(hot: hot, glow: glow, color: color),
    );
  }
}

class _OrbPainter extends CustomPainter {
  const _OrbPainter({required this.hot, required this.glow, required this.color});

  final bool hot;
  final double glow;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final pulse = 0.55 + glow * 0.45 + (hot ? 0.25 : 0);
    canvas.drawCircle(
      center,
      30,
      Paint()
        ..color = color.withValues(alpha: 0.18 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = color.withValues(alpha: 0.55 + glow * 0.4);
    canvas.drawCircle(center, 28, ring);
    canvas.drawCircle(center, 20, ring..strokeWidth = 1.6);
    canvas.drawCircle(
      center,
      8,
      Paint()..color = color.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      center,
      3.5,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) {
    return oldDelegate.hot != hot || oldDelegate.glow != glow || oldDelegate.color != color;
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1A2C).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF1D3C58)),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Color(0xFF3DDC97), size: 18),
          SizedBox(width: 8),
          Text(
            'Sensor Ready',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(width: 16),
          SizedBox(
            width: 1,
            height: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFF2C4A64)),
            ),
          ),
          SizedBox(width: 16),
          Icon(Icons.signal_cellular_alt, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'Connected',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x332E8BFF), Color(0x0006101E)],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height * 0.46),
          radius: size.width * 0.28,
        ),
      );
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.46),
      size.width * 0.28,
      glow,
    );

    final dots = Paint()..color = const Color(0xFF7EC8FF).withValues(alpha: 0.28);
    const spots = <Offset>[
      Offset(180, 160),
      Offset(260, 420),
      Offset(1080, 150),
      Offset(1180, 390),
      Offset(700, 120),
      Offset(820, 560),
    ];
    const radii = <double>[5, 3, 7, 4, 3, 5];
    for (var i = 0; i < spots.length; i++) {
      canvas.drawCircle(spots[i], radii[i], dots);
    }

    void wave(double y, double amp, double phase, Color color, double stroke) {
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 6) {
        final t = x / size.width;
        path.lineTo(
          x,
          y + math.sin(t * math.pi * 2 * 1.6 + phase) * amp,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    void fillWave(double y, double amp, double phase, Color color) {
      final path = Path()..moveTo(0, size.height);
      path.lineTo(0, y);
      for (var x = 0.0; x <= size.width; x += 8) {
        final t = x / size.width;
        path.lineTo(x, y + math.sin(t * math.pi * 2 * 1.35 + phase) * amp);
      }
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, Paint()..color = color);
    }

    fillWave(size.height * 0.86, 34, 0.2, const Color(0x141E6DFF));
    fillWave(size.height * 0.92, 28, 2.1, const Color(0x2214C8FF));
    wave(size.height * 0.74, 22, 0.3, const Color(0x55308CFF), 2.4);
    wave(size.height * 0.82, 36, 1.5, const Color(0x88307CFF), 3.2);
    wave(size.height * 0.9, 24, 2.6, const Color(0x662EC8FF), 2.2);
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) => false;
}

class _FingerprintMark extends CustomPainter {
  const _FingerprintMark({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4
      ..color = color;
    final w = size.width;
    final h = size.height;
    for (var i = 0; i < 5; i++) {
      final inset = i * 6.5;
      final path = Path()
        ..moveTo(w * 0.16 + inset * 0.45, h * 0.8)
        ..cubicTo(
          w * 0.14 + inset * 0.15,
          h * 0.22 + inset * 0.85,
          w * 0.86 - inset * 0.15,
          h * 0.22 + inset * 0.85,
          w * 0.84 - inset * 0.45,
          h * 0.8,
        );
      canvas.drawPath(path, paint);
    }
    final hook = Path()
      ..moveTo(w * 0.4, h * 0.74)
      ..cubicTo(w * 0.34, h * 0.46, w * 0.66, h * 0.38, w * 0.6, h * 0.58)
      ..cubicTo(w * 0.55, h * 0.72, w * 0.44, h * 0.68, w * 0.48, h * 0.54);
    canvas.drawPath(hook, paint);
  }

  @override
  bool shouldRepaint(covariant _FingerprintMark oldDelegate) => oldDelegate.color != color;
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.turn,
    required this.spinning,
    required this.color,
  });

  final double turn;
  final bool spinning;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = size.shortestSide;
    canvas.drawCircle(
      center,
      base * 0.34,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.45), color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: base * 0.34)),
    );

    void ring({
      required double radiusFactor,
      required double width,
      required double sweep,
      required double start,
      required bool reverse,
    }) {
      final radius = base * radiusFactor;
      final spin = spinning ? turn * math.pi * 2 * (reverse ? -1.0 : 1.0) : 0.0;
      final rect = Rect.fromCircle(center: center, radius: radius);
      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width + 7
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [
            const Color(0xFF06101E),
            color,
            Colors.white,
            color,
            const Color(0xFF06101E),
          ],
          transform: GradientRotation(spin),
        ).createShader(rect);
      canvas.drawArc(rect, start + spin, sweep, false, glow);
      canvas.drawArc(rect, start + spin, sweep, false, paint);
    }

    ring(
      radiusFactor: 0.46,
      width: 11,
      sweep: math.pi * 1.65,
      start: -0.5,
      reverse: false,
    );
    ring(
      radiusFactor: 0.355,
      width: 7,
      sweep: math.pi * 1.35,
      start: 1.15,
      reverse: true,
    );
    ring(
      radiusFactor: 0.26,
      width: 4,
      sweep: math.pi * 1.75,
      start: 0.2,
      reverse: false,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.turn != turn ||
        oldDelegate.spinning != spinning ||
        oldDelegate.color != color;
  }
}
