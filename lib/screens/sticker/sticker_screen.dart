import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/detected_thing.dart';
import '../../providers/shell_controller.dart';
import '../../services/nfc_bridge_client.dart';
import '../../services/thing_announcer.dart';

class StickerScreen extends StatefulWidget {
  const StickerScreen({super.key, this.client, this.announcer});

  final NfcBridgeClient? client;
  final ThingAnnouncer? announcer;

  @override
  State<StickerScreen> createState() => _StickerScreenState();
}

class _StickerScreenState extends State<StickerScreen>
    with SingleTickerProviderStateMixin {
  late final NfcBridgeClient _client = widget.client ?? NfcBridgeClient();
  late final ThingAnnouncer _announcer = widget.announcer ?? ThingAnnouncer();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  Timer? _timer;
  int _generation = 0;
  bool _busy = false;
  bool _speaking = false;
  int _misses = 0;
  String? _spokenUid;
  NfcSnapshot? _snapshot;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(context.read<ShellController>().index == ShellController.stickerTab);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _generation += 1;
    _pulse.dispose();
    _announcer.stop();
    if (widget.client == null) {
      _client.close();
    }
    super.dispose();
  }

  void _sync(bool active) {
    if (!active) {
      _timer?.cancel();
      _timer = null;
      _generation += 1;
      _pulse.stop();
      _spokenUid = null;
      _announcer.stop();
      if (_speaking && mounted) {
        setState(() => _speaking = false);
      } else {
        _speaking = false;
      }
      return;
    }
    if (_timer != null) {
      return;
    }
    _pulse.repeat();
    _poll();
    _timer = Timer.periodic(const Duration(milliseconds: 700), (_) => _poll());
  }

  Future<void> _poll() async {
    if (_busy) {
      return;
    }
    _busy = true;
    final generation = _generation;
    final snapshot = await _client.read();
    _busy = false;
    if (!mounted || generation != _generation) {
      return;
    }
    final uid = snapshot.present ? snapshot.uid : null;
    if (uid == null) {
      _misses += 1;
      if (_misses < 3) {
        return;
      }
      setState(() => _snapshot = snapshot);
      if (_spokenUid != null) {
        _spokenUid = null;
        _announcer.stop();
        if (mounted) {
          setState(() => _speaking = false);
        }
      }
      return;
    }
    _misses = 0;
    setState(() => _snapshot = snapshot);
    if (uid == _spokenUid) {
      return;
    }
    _spokenUid = uid;
    unawaited(_speak(uid));
  }

  Future<void> _speak(String uid) async {
    if (!mounted) {
      return;
    }
    setState(() => _speaking = true);
    await _announcer.announce(announcementFor(uid));
    if (!mounted || _spokenUid != uid) {
      return;
    }
    setState(() => _speaking = false);
  }

  @override
  Widget build(BuildContext context) {
    final active =
        context.watch<ShellController>().index == ShellController.stickerTab;
    if (active && _timer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _sync(true);
        }
      });
    } else if (!active && _timer != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _sync(false);
        }
      });
    }

    final snapshot = _snapshot;
    final found = snapshot != null && snapshot.present && snapshot.uid != null;
    final thing = found ? thingForUid(snapshot.uid) : null;
    final name = found ? (thing?.name ?? 'Unknown thing') : 'Ready';
    final kind = found
        ? (thing?.kind ?? 'Sticker only')
        : 'Place the thing on the reader';
    final details = found
        ? <ThingDetail>[
            ...?thing?.details,
            ThingDetail('Chip', snapshot.uid ?? ''),
          ]
        : const <ThingDetail>[];
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final scanner = _Scanner(
      pulse: _pulse,
      found: found,
      name: name,
      kind: kind,
    );
    final panel = _DetailPanel(
      found: found,
      speaking: _speaking,
      speech: found ? announcementFor(snapshot.uid) : null,
      details: details,
      message: _idleMessage(snapshot),
    );
    return ColoredBox(
      color: AppColors.navy,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            children: [
              _Header(found: found, speaking: _speaking),
              const SizedBox(height: 8),
              Expanded(
                child: wide
                    ? Row(
                        children: [
                          Expanded(flex: 5, child: Center(child: scanner)),
                          const SizedBox(width: 20),
                          Expanded(flex: 6, child: panel),
                        ],
                      )
                    : Column(
                        children: [
                          scanner,
                          const SizedBox(height: 14),
                          Expanded(child: panel),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _idleMessage(NfcSnapshot? snapshot) {
    if (snapshot == null) {
      return 'Checking the reader.';
    }
    if (!snapshot.ok) {
      return snapshot.error ?? 'The NFC bridge on this computer is not running.';
    }
    return 'Hold one thing flat on the reader. The buzzer sounds, then the voice reads the full detail.';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.found, required this.speaking});

  final bool found;
  final bool speaking;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: found ? AppColors.teal : AppColors.blue,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'THING DETECTOR',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
        if (speaking)
          const _StatusPill(label: 'VOICE', color: AppColors.teal)
        else if (found)
          const _StatusPill(label: 'FOUND', color: AppColors.teal)
        else
          const _StatusPill(label: 'SCAN', color: AppColors.blue),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _Scanner extends StatelessWidget {
  const _Scanner({
    required this.pulse,
    required this.found,
    required this.name,
    required this.kind,
  });

  final Animation<double> pulse;
  final bool found;
  final String name;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final color = found ? AppColors.teal : AppColors.blue;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 188,
          height: 188,
          child: AnimatedBuilder(
            animation: pulse,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  for (var ring = 0; ring < 3; ring++) _ring(ring, color),
                  child!,
                ],
              );
            },
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Icon(
                found ? Icons.check_rounded : Icons.sensors_rounded,
                size: 40,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          kind,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _ring(int index, Color color) {
    final turn = (pulse.value + index / 3) % 1;
    final size = 88 + turn * 96;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: (1 - turn) * 0.75),
          width: 2,
        ),
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({
    required this.found,
    required this.speaking,
    required this.speech,
    required this.details,
    required this.message,
  });

  final bool found;
  final bool speaking;
  final String? speech;
  final List<ThingDetail> details;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: found
          ? ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              children: [
                for (final detail in details) _DetailRow(detail: detail),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      speaking ? Icons.volume_up_rounded : Icons.campaign_rounded,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        speaking ? 'Speaking. $speech' : speech!,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Waiting',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: const TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.detail});

  final ThingDetail detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icon, color: AppColors.navy, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  detail.value,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData get _icon {
    switch (detail.label) {
      case 'Character':
        return Icons.person_rounded;
      case 'Item':
        return Icons.toys_rounded;
      case 'Sticker on':
        return Icons.nfc_rounded;
      default:
        return Icons.memory_rounded;
    }
  }
}
