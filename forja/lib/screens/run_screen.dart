import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'legal_screen.dart';

enum _Phase { idle, countdown, running, paused }

/// Cronômetro de corrida com GPS (ou modo esteira, sem GPS).
class RunScreen extends StatefulWidget {
  const RunScreen({super.key});

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> {
  _Phase _phase = _Phase.idle;
  bool _treadmill = false;
  double _speedKmh = 9;
  double? _goalKm; // meta de distância (null = livre)
  bool _goalHit = false;

  final _sw = Stopwatch();
  Timer? _ticker;
  StreamSubscription<Position>? _sub;
  DateTime _started = DateTime.now();
  int _countdown = 3;

  Position? _last;
  double? _accuracy;
  double _dist = 0;
  final List<int> _splits = [];
  int _lastSplitAt = 0;
  final List<List<double>> _route = [];
  final List<(int, double)> _samples = []; // (segundo, distância)
  int _lastTickMs = 0;

  @override
  void dispose() {
    _ticker?.cancel();
    _sub?.cancel();
    WakelockPlus.disable().catchError((_) {});
    super.dispose();
  }

  int get _elapsed => _sw.elapsed.inSeconds;

  double? get _avgPace => _dist < 30 ? null : _elapsed / (_dist / 1000);

  /// Ritmo dos últimos ~30 segundos.
  double? get _currentPace {
    if (_samples.length < 2) return null;
    final now = _samples.last;
    final ref = _samples.firstWhere((s) => now.$1 - s.$1 <= 30,
        orElse: () => _samples.first);
    final dd = now.$2 - ref.$2;
    final dt = now.$1 - ref.$1;
    if (dd < 10 || dt <= 0) return null;
    return dt / (dd / 1000);
  }

  LocationSettings _settings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3,
        intervalDuration: const Duration(seconds: 1),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Corrida em andamento',
          notificationText: 'O Forja está registrando sua corrida',
          enableWakeLock: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.fitness,
        distanceFilter: 3,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
        accuracy: LocationAccuracy.best, distanceFilter: 3);
  }

  void _snack(String msg, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), action: action));
  }

  Future<bool> _ensureGps() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _snack('Ative a localização do celular para usar o GPS.',
            action: SnackBarAction(
                label: 'Ativar', onPressed: Geolocator.openLocationSettings));
        return false;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        // Explica antes de pedir (boa prática e exigência do Google Play).
        if (!mounted) return false;
        final go = await showLocationRationale(context);
        if (!go) {
          if (mounted) setState(() => _treadmill = true);
          return false;
        }
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        _snack('Permissão de localização bloqueada.',
            action: SnackBarAction(
                label: 'Ajustes', onPressed: Geolocator.openAppSettings));
        return false;
      }
      if (perm == LocationPermission.denied) {
        _snack('Sem localização. Use o modo Esteira se preferir.');
        return false;
      }
      return true;
    } catch (e) {
      _snack('GPS indisponível neste aparelho. Use o modo Esteira.');
      return false;
    }
  }

  Future<void> _start() async {
    if (!_treadmill && !await _ensureGps()) return;
    _reset();
    setState(() {
      _phase = _Phase.countdown;
      _countdown = 3;
    });
    HapticFeedback.mediumImpact();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _beginRunning() {
    _started = DateTime.now();
    _sw.start();
    _lastTickMs = 0;
    _phase = _Phase.running;
    HapticFeedback.heavyImpact();
    WakelockPlus.enable().catchError((_) {});
    if (!_treadmill) {
      _sub = Geolocator.getPositionStream(locationSettings: _settings())
          .listen(_onPosition, onError: (_) {
        if (mounted) _snack('Sinal de GPS perdido.');
      });
    }
  }

  void _tick() {
    if (!mounted) return;
    if (_phase == _Phase.countdown) {
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          _beginRunning();
        } else {
          HapticFeedback.selectionClick();
        }
      });
      return;
    }
    if (_phase == _Phase.running) {
      if (_treadmill) {
        final ms = _sw.elapsedMilliseconds;
        final dt = (ms - _lastTickMs) / 1000;
        _lastTickMs = ms;
        _dist += _speedKmh / 3.6 * dt;
      }
      _samples.add((_elapsed, _dist));
      if (_samples.length > 120) _samples.removeAt(0);
      _checkSplits();
    }
    setState(() {});
  }

  void _onPosition(Position p) {
    _accuracy = p.accuracy;
    if (_phase != _Phase.running) return;
    if (p.accuracy > 30) return; // sinal fraco, ignora
    final last = _last;
    if (last != null) {
      final d = Geolocator.distanceBetween(
          last.latitude, last.longitude, p.latitude, p.longitude);
      final dt = p.timestamp.difference(last.timestamp).inMilliseconds / 1000;
      final speed = d / math.max(dt, 1);
      if (speed > 12) return; // salto de GPS (mais de 43 km/h)
      if (d < 2) return;
      _dist += d;
    }
    _last = p;
    if (_route.isEmpty ||
        Geolocator.distanceBetween(_route.last[0], _route.last[1],
                p.latitude, p.longitude) >
            15) {
      _route.add([p.latitude, p.longitude]);
    }
  }

  void _checkSplits() {
    final goal = _goalKm;
    if (goal != null && !_goalHit && _dist >= goal * 1000) {
      _goalHit = true;
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
      _snack('🎉 Meta de ${fmtNum(goal)} km concluída em ${fmtDuration(_elapsed)}!');
    }
    while (_dist >= (_splits.length + 1) * 1000) {
      final split = _elapsed - _lastSplitAt;
      _splits.add(split);
      _lastSplitAt = _elapsed;
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
      _snack('🏁 ${_splits.length} km · ritmo ${fmtPace(split.toDouble())} /km');
    }
  }

  void _pause() {
    _sw.stop();
    setState(() => _phase = _Phase.paused);
    HapticFeedback.mediumImpact();
  }

  void _resume() {
    _last = null; // não conta o deslocamento durante a pausa
    _lastTickMs = _sw.elapsedMilliseconds;
    _sw.start();
    setState(() => _phase = _Phase.running);
    HapticFeedback.mediumImpact();
  }

  void _reset() {
    _ticker?.cancel();
    _sub?.cancel();
    _sub = null;
    _sw
      ..stop()
      ..reset();
    _last = null;
    _dist = 0;
    _splits.clear();
    _lastSplitAt = 0;
    _route.clear();
    _samples.clear();
    _goalHit = false;
  }

  Future<void> _stop() async {
    _pause();
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Finalizar corrida?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('${fmtKm(_dist)} km em ${fmtDuration(_elapsed)}',
                  style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 18),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, 'save'),
                  child: const Text('Salvar corrida')),
              const SizedBox(height: 10),
              OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, 'resume'),
                  child: const Text('Continuar correndo')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'discard'),
                child: const Text('Descartar',
                    style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (choice == 'resume' || choice == null) {
      _resume();
      return;
    }
    if (choice == 'save') {
      if (_dist < 50 && _elapsed < 60) {
        _snack('Corrida muito curta para salvar.');
      } else {
        final run = RunLog(
          id: newId(),
          start: _started,
          durationSec: _elapsed,
          distanceM: _dist,
          splits: List.of(_splits),
          treadmill: _treadmill,
          route: List.of(_route),
        );
        AppScope.read(context).addRun(run);
        _showRunDetails(run, justFinished: true);
      }
    }
    _reset();
    WakelockPlus.disable().catchError((_) {});
    setState(() => _phase = _Phase.idle);
  }

  void _showRunDetails(RunLog run, {bool justFinished = false}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => _RunDetails(run: run, justFinished: justFinished),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Corrida')),
      body: _phase == _Phase.idle ? _idle() : _live(),
    );
  }

  // ---------- Tela parada ----------

  Widget _idle() {
    final s = AppScope.of(context);
    final weekKm =
        s.runsThisWeek.fold(0.0, (sum, r) => sum + r.distanceM) / 1000;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
                value: false,
                icon: Icon(Icons.gps_fixed_rounded),
                label: Text('Rua (GPS)')),
            ButtonSegment(
                value: true,
                icon: Icon(Icons.directions_walk_rounded),
                label: Text('Esteira')),
          ],
          selected: {_treadmill},
          onSelectionChanged: (v) => setState(() => _treadmill = v.first),
        ),
        const SizedBox(height: 14),
        const Text('Meta de distância',
            style: TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in const <double?>[null, 3, 5, 10, 21.1])
              ChoiceChip(
                label: Text(g == null ? 'Livre' : '${fmtNum(g)} km'),
                selected: _goalKm == g,
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: _goalKm == g ? Colors.black : AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (_) => setState(() => _goalKm = g),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: _start,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: AppColors.volt,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.volt.withValues(alpha: 0.35),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 64, color: Colors.black),
                  Text('INICIAR',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: 2)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _treadmill
              ? 'Ajuste a velocidade da esteira durante a corrida.'
              : 'Avisos a cada km com vibração. Deixe o GPS achar o sinal antes de sair.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.route_rounded,
                label: 'Nesta semana',
                value: fmtNum(weekKm, decimals: 1),
                unit: 'km',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.speed_rounded,
                color: AppColors.fire,
                label: 'Melhor ritmo (≥1 km)',
                value: fmtPace(s.bestPace),
                unit: '/km',
              ),
            ),
          ],
        ),
        const SectionTitle('Histórico'),
        if (s.runLogs.isEmpty)
          const EmptyState(
            icon: Icons.directions_run_rounded,
            title: 'Nenhuma corrida ainda',
            message: 'Sua primeira corrida vai aparecer aqui.',
          ),
        for (final r in s.runLogs.take(30))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              onTap: () => _showRunDetails(r),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.cardHigh,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: r.route.length > 1
                        ? CustomPaint(painter: RoutePainter(r.route, stroke: 2))
                        : Icon(
                            r.treadmill
                                ? Icons.directions_walk_rounded
                                : Icons.directions_run_rounded,
                            color: AppColors.muted),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${fmtKm(r.distanceM)} km',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w900)),
                        Text(
                          '${fmtDuration(r.durationSec)} · ${fmtPace(r.paceSecPerKm)} /km${r.treadmill ? ' · esteira' : ''}',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Text(relativeDay(r.start),
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ---------- Correndo ----------

  Widget _live() {
    if (_phase == _Phase.countdown) {
      return Center(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(_countdown),
          tween: Tween(begin: 1.6, end: 1),
          duration: const Duration(milliseconds: 400),
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Text('$_countdown',
              style: const TextStyle(
                  fontSize: 140,
                  fontWeight: FontWeight.w900,
                  color: AppColors.volt)),
        ),
      );
    }

    final paused = _phase == _Phase.paused;
    final kcal = AppScope.of(context).profile.weight * (_dist / 1000);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight - 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _treadmill ? const SizedBox(height: 8) : _gpsBadge(),
                _liveStats(paused, kcal),
                _liveButtons(paused),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _liveStats(bool paused, double kcal) {
    return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(paused ? 'PAUSADO' : 'TEMPO',
                style: TextStyle(
                    color: paused ? AppColors.fire : AppColors.muted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2)),
            FittedBox(
              child: Text(fmtDuration(_elapsed),
                  style: const TextStyle(
                      fontSize: 76,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                      fontFeatures: [FontFeature.tabularFigures()])),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: fmtKm(_dist),
                    style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: AppColors.volt,
                        fontFeatures: [FontFeature.tabularFigures()])),
                const TextSpan(
                    text: ' km',
                    style: TextStyle(fontSize: 20, color: AppColors.muted)),
              ]),
            ),
            if (_goalKm != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_dist / (_goalKm! * 1000)).clamp(0.0, 1.0),
                  minHeight: 10,
                  color: _goalHit ? AppColors.fire : AppColors.volt,
                  backgroundColor: AppColors.card,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _goalHit
                    ? 'Meta de ${fmtNum(_goalKm!)} km batida! 🎉'
                    : 'Faltam ${fmtKm(_goalKm! * 1000 - _dist)} km para a meta de ${fmtNum(_goalKm!)} km',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: StatTile(
                        label: 'Ritmo atual',
                        value: fmtPace(_treadmill
                            ? 3600 / _speedKmh
                            : _currentPace),
                        unit: '/km')),
                const SizedBox(width: 10),
                Expanded(
                    child: StatTile(
                        label: 'Ritmo médio',
                        value: fmtPace(_avgPace),
                        unit: '/km')),
                const SizedBox(width: 10),
                Expanded(
                    child: StatTile(
                        label: 'Calorias',
                        value: fmtInt(kcal),
                        unit: 'kcal')),
              ],
            ),
            if (_treadmill) ...[
              const SizedBox(height: 12),
              NumberStepper(
                label: 'Velocidade da esteira',
                value: _speedKmh,
                step: 0.5,
                min: 1,
                max: 25,
                decimals: 1,
                unit: 'km/h',
                onChanged: (v) => setState(() => _speedKmh = v),
              ),
            ],
            if (_splits.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  // Mostra as 4 parciais mais recentes.
                  for (var i = _splits.length - 1;
                      i >= 0 && i >= _splits.length - 4;
                      i--)
                    Chip(
                      label: Text(
                          'Km ${i + 1} · ${fmtPace(_splits[i].toDouble())}'),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
          ],
        );
  }

  Widget _liveButtons(bool paused) {
    return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _roundButton(
                  icon: Icons.stop_rounded,
                  color: AppColors.danger,
                  size: 72,
                  onTap: _stop,
                  label: 'Finalizar',
                ),
                const SizedBox(width: 28),
                _roundButton(
                  icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  color: AppColors.volt,
                  size: 96,
                  onTap: paused ? _resume : _pause,
                  label: paused ? 'Retomar' : 'Pausar',
                ),
              ],
            );
  }

  Widget _gpsBadge() {
    final acc = _accuracy;
    final (String txt, Color c) = acc == null
        ? ('Procurando GPS…', AppColors.muted)
        : acc <= 10
            ? ('GPS forte', AppColors.volt)
            : acc <= 30
                ? ('GPS ok', AppColors.fire)
                : ('GPS fraco', AppColors.danger);
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        avatar: Icon(Icons.gps_fixed_rounded, size: 16, color: c),
        label: Text(txt),
      ),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
    required String label,
  }) {
    return Column(
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, size: size * 0.5, color: Colors.black),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: AppColors.muted)),
      ],
    );
  }
}

class _RunDetails extends StatelessWidget {
  final RunLog run;
  final bool justFinished;
  const _RunDetails({required this.run, required this.justFinished});

  @override
  Widget build(BuildContext context) {
    final best = run.splits.isEmpty ? null : run.splits.reduce(math.min);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            if (justFinished)
              const Text('Corrida salva! 🏃',
                  style: TextStyle(
                      color: AppColors.volt, fontWeight: FontWeight.w800)),
            Text(fmtDateTime(run.start),
                style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 4),
            Text('${fmtKm(run.distanceM)} km',
                style: const TextStyle(
                    fontSize: 40, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: StatTile(
                        label: 'Tempo', value: fmtDuration(run.durationSec))),
                const SizedBox(width: 8),
                Expanded(
                    child: StatTile(
                        label: 'Ritmo médio',
                        value: fmtPace(run.paceSecPerKm),
                        unit: '/km')),
              ],
            ),
            if (run.route.length > 1) ...[
              const SizedBox(height: 16),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(20),
                child: CustomPaint(
                  painter: RoutePainter(run.route, stroke: 4, showEnds: true),
                  size: Size.infinite,
                ),
              ),
            ],
            if (run.splits.isNotEmpty) ...[
              const SectionTitle('Parciais por km'),
              for (var i = 0; i < run.splits.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 56,
                          child: Text('Km ${i + 1}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700))),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (best! / run.splits[i]).clamp(0.0, 1.0),
                            minHeight: 10,
                            color: run.splits[i] == best
                                ? AppColors.volt
                                : AppColors.water,
                            backgroundColor: AppColors.cardHigh,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 64,
                        child: Text(fmtPace(run.splits[i].toDouble()),
                            textAlign: TextAlign.right,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                AppScope.read(context).deleteRun(run.id);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger),
              label: const Text('Excluir corrida',
                  style: TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Desenha o percurso salvo (sem precisar de mapa ou chave de API).
class RoutePainter extends CustomPainter {
  final List<List<double>> route;
  final double stroke;
  final bool showEnds;
  RoutePainter(this.route, {this.stroke = 3, this.showEnds = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (route.length < 2) return;
    var minLat = route.first[0], maxLat = route.first[0];
    var minLng = route.first[1], maxLng = route.first[1];
    for (final p in route) {
      minLat = math.min(minLat, p[0]);
      maxLat = math.max(maxLat, p[0]);
      minLng = math.min(minLng, p[1]);
      maxLng = math.max(maxLng, p[1]);
    }
    final pad = stroke * 2;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    // Corrige a distorção da longitude conforme a latitude.
    final lngScale = math.cos((minLat + maxLat) / 2 * math.pi / 180);
    final spanX = math.max((maxLng - minLng) * lngScale, 1e-9);
    final spanY = math.max(maxLat - minLat, 1e-9);
    final scale = math.min(w / spanX, h / spanY);
    final offX = pad + (w - spanX * scale) / 2;
    final offY = pad + (h - spanY * scale) / 2;

    Offset toPx(List<double> p) => Offset(
          offX + (p[1] - minLng) * lngScale * scale,
          offY + (maxLat - p[0]) * scale,
        );

    final path = Path()..moveTo(toPx(route.first).dx, toPx(route.first).dy);
    for (final p in route.skip(1)) {
      final o = toPx(p);
      path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.volt
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    if (showEnds) {
      canvas.drawCircle(toPx(route.first), stroke * 1.6,
          Paint()..color = Colors.white);
      canvas.drawCircle(
          toPx(route.last), stroke * 1.6, Paint()..color = AppColors.fire);
    }
  }

  @override
  bool shouldRepaint(RoutePainter old) => old.route != route;
}
