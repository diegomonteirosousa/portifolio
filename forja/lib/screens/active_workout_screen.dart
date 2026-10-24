import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../calc.dart';
import '../data/exercises.dart';
import '../models.dart';
import '../services/notifications.dart';
import '../state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'exercise_picker_screen.dart';

class _SetEntry {
  int reps;
  double weight;
  bool done;
  _SetEntry(this.reps, this.weight, [this.done = false]);

  Map<String, dynamic> toJson() => {'r': reps, 'w': weight, 'd': done};
  factory _SetEntry.fromJson(Map<String, dynamic> j) => _SetEntry(
      (j['r'] as num).toInt(), (j['w'] as num).toDouble(), j['d'] as bool);
}

class _ExState {
  String exerciseId;
  int restSec;
  final List<_SetEntry> sets;
  final GlobalKey key = GlobalKey();
  _ExState(this.exerciseId, this.restSec, this.sets);

  Map<String, dynamic> toJson() => {
        'e': exerciseId,
        'rest': restSec,
        'sets': sets.map((s) => s.toJson()).toList(),
      };
  factory _ExState.fromJson(Map<String, dynamic> j) => _ExState(
        j['e'] as String,
        (j['rest'] as num).toInt(),
        (j['sets'] as List)
            .map((s) => _SetEntry.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

/// Modo "na academia": tela acesa, botões grandes e descanso automático.
/// O progresso é salvo a cada série: se o app fechar, dá para retomar.
class ActiveWorkoutScreen extends StatefulWidget {
  final WorkoutTemplate? template;
  final Map<String, dynamic>? session;

  const ActiveWorkoutScreen({super.key, required WorkoutTemplate this.template})
      : session = null;

  /// Retoma um treino que ficou em andamento.
  const ActiveWorkoutScreen.resume({super.key, required Map<String, dynamic> this.session})
      : template = null;

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  DateTime _started = DateTime.now();
  late final List<_ExState> _exercises;
  late final String _templateId;
  late final String _name;
  Timer? _ticker;
  final _scroll = ScrollController();

  DateTime? _restEnd;
  int _restTotal = 0;

  @override
  void initState() {
    super.initState();
    final session = widget.session;
    if (session != null) {
      _templateId = session['templateId'] as String;
      _name = session['name'] as String;
      _started = DateTime.parse(session['started'] as String);
      _exercises = (session['exercises'] as List)
          .map((e) => _ExState.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      final t = widget.template!;
      _templateId = t.id;
      _name = t.name;
      _exercises = _fromTemplate(t);
    }
    _persist();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    WakelockPlus.enable().catchError((_) {});
  }

  void _persist() {
    AppScope.read(context).saveSession({
      'templateId': _templateId,
      'name': _name,
      'started': _started.toIso8601String(),
      'exercises': _exercises.map((e) => e.toJson()).toList(),
    });
  }

  /// setState + salva o progresso.
  void _update(VoidCallback fn) {
    setState(fn);
    _persist();
  }

  List<_ExState> _fromTemplate(WorkoutTemplate template) {
    final s = AppScope.read(context);
    return template.exercises.map((p) {
      final last = s.lastPerformance(p.exerciseId);
      return _ExState(
        p.exerciseId,
        p.restSec,
        List.generate(p.sets, (i) {
          var w = p.weight;
          if (w == 0 && last != null) {
            final ref = i < last.sets.length ? last.sets[i] : last.sets.last;
            w = ref.weight;
          }
          return _SetEntry(p.reps, w);
        }),
      );
    }).toList();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _scroll.dispose();
    WakelockPlus.disable().catchError((_) {});
    NotificationService.instance.cancelRestEnd();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    final end = _restEnd;
    if (end != null && !DateTime.now().isBefore(end)) {
      _restEnd = null;
      HapticFeedback.vibrate();
      SystemSound.play(SystemSoundType.alert);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Descanso concluído. Próxima série! 💪'),
        duration: Duration(seconds: 2),
      ));
    }
    setState(() {});
  }

  int get _elapsed => DateTime.now().difference(_started).inSeconds;

  int get _restLeft {
    final end = _restEnd;
    if (end == null) return 0;
    return end.difference(DateTime.now()).inSeconds.clamp(0, 3600).toInt() + 1;
  }

  int get _totalSets => _exercises.fold(0, (s, e) => s + e.sets.length);
  int get _doneSets =>
      _exercises.fold(0, (s, e) => s + e.sets.where((x) => x.done).length);

  void _startRest(int seconds) {
    setState(() {
      _restTotal = seconds;
      _restEnd = DateTime.now().add(Duration(seconds: seconds));
    });
    NotificationService.instance.scheduleRestEnd(seconds);
  }

  void _adjustRest(int delta) {
    final end = _restEnd;
    if (end == null) return;
    final newEnd = end.add(Duration(seconds: delta));
    if (!newEnd.isAfter(DateTime.now())) {
      _skipRest();
      return;
    }
    setState(() {
      _restEnd = newEnd;
      _restTotal = (_restTotal + delta).clamp(1, 3600).toInt();
    });
    NotificationService.instance
        .scheduleRestEnd(newEnd.difference(DateTime.now()).inSeconds);
  }

  void _skipRest() {
    setState(() => _restEnd = null);
    NotificationService.instance.cancelRestEnd();
  }

  void _toggleSet(_ExState ex, _SetEntry set) {
    _update(() => set.done = !set.done);
    if (!set.done) return;
    HapticFeedback.mediumImpact();
    if (_doneSets < _totalSets) _startRest(ex.restSec);
    // Terminou o exercício: rola até o próximo que ainda tem séries.
    if (ex.sets.every((x) => x.done)) {
      HapticFeedback.heavyImpact();
      final i = _exercises.indexOf(ex);
      final next = _exercises
          .skip(i + 1)
          .followedBy(_exercises.take(i))
          .where((e) => e.sets.any((x) => !x.done));
      if (next.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = next.first.key.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(ctx,
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                alignment: 0.05);
          }
        });
      }
    }
  }

  /// Texto da próxima série, mostrado durante o descanso.
  String? get _nextSetLabel {
    for (final ex in _exercises) {
      for (var i = 0; i < ex.sets.length; i++) {
        final set = ex.sets[i];
        if (set.done) continue;
        final w = set.weight > 0 ? '${fmtNum(set.weight)} kg × ' : '';
        return '${exerciseOf(ex.exerciseId).name} · série ${i + 1} · $w${set.reps}';
      }
    }
    return null;
  }

  Future<void> _editWeight(_ExState ex, _SetEntry set) async {
    final e = exerciseOf(ex.exerciseId);
    String? helper;
    if (e.equipment == 'Barra' && set.weight > 20) {
      final plates = Calc.platesPerSide(set.weight);
      if (plates.isNotEmpty) {
        helper =
            'Anilhas por lado (barra de 20 kg): ${plates.map((p) => fmtNum(p, decimals: 2)).join(' + ')}';
      }
    }
    final v = await showNumberDialog(context,
        title: 'Carga', initial: set.weight, unit: 'kg', helper: helper);
    if (v == null || v < 0) return;
    _update(() {
      set.weight = v;
      // Preenche as séries seguintes ainda não feitas com a mesma carga.
      final i = ex.sets.indexOf(set);
      for (var j = i + 1; j < ex.sets.length; j++) {
        if (!ex.sets[j].done) ex.sets[j].weight = v;
      }
    });
  }

  Future<void> _editReps(_SetEntry set) async {
    final v = await showNumberDialog(context,
        title: 'Repetições', initial: set.reps.toDouble());
    if (v == null || v < 0) return;
    _update(() => set.reps = v.round());
  }

  Future<void> _addExercise() async {
    final ids = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );
    if (ids == null) return;
    _update(() {
      for (final id in ids) {
        _exercises.add(_ExState(id, 90, List.generate(3, (_) => _SetEntry(10, 0))));
      }
    });
  }

  Future<void> _swapExercise(_ExState ex) async {
    final ids = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
          builder: (_) => const ExercisePickerScreen(single: true)),
    );
    if (ids == null || ids.isEmpty) return;
    _update(() => ex.exerciseId = ids.first);
  }

  Future<void> _askExit() async {
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
              const Text('Sair do treino?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('$_doneSets de $_totalSets séries feitas.',
                  style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, 'finish'),
                child: const Text('Finalizar e salvar'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx, 'continue'),
                child: const Text('Continuar treinando'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'discard'),
                child: const Text('Descartar treino',
                    style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (choice == 'finish') {
      await _finish();
    } else if (choice == 'discard') {
      AppScope.read(context).clearSession();
      Navigator.of(context).pop();
    }
  }

  Future<void> _finish() async {
    final s = AppScope.read(context);
    final logged = <LoggedExercise>[];
    final prs = <String>[];

    for (final ex in _exercises) {
      final done = ex.sets.where((x) => x.done).toList();
      if (done.isEmpty) continue;
      final best = s.bestWeight(ex.exerciseId);
      final maxNow =
          done.map((x) => x.weight).fold(0.0, (a, b) => a > b ? a : b);
      if (maxNow > 0 && maxNow > best && best > 0) {
        prs.add('${exerciseOf(ex.exerciseId).name}: ${fmtNum(maxNow)} kg');
      }
      logged.add(LoggedExercise(
          ex.exerciseId, done.map((x) => LoggedSet(x.reps, x.weight)).toList()));
    }

    if (logged.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Marque pelo menos uma série como feita ✓')));
      return;
    }

    final isSaved = s.templates.any((t) => t.id == _templateId);
    final log = WorkoutLog(
      id: newId(),
      name: _name,
      start: _started,
      durationSec: _elapsed,
      exercises: logged,
    );
    s.addWorkoutLog(log, templateId: isSaved ? _templateId : null);
    s.clearSession();
    _ticker?.cancel();
    await NotificationService.instance.cancelRestEnd();
    HapticFeedback.heavyImpact();

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SummaryDialog(log: log, prs: prs, streak: s.streak),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final resting = _restEnd != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askExit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _askExit,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17)),
              Text(fmtDuration(_elapsed),
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.volt,
                      fontFeatures: [FontFeature.tabularFigures()])),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16)),
                  onPressed: _finish,
                  child: const Text('Finalizar'),
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: _totalSets == 0 ? 0 : _doneSets / _totalSets,
              minHeight: 4,
              backgroundColor: AppColors.card,
            ),
          ),
        ),
        body: Stack(
          children: [
            // Column (e não ListView) para todos os cartões existirem
            // e a rolagem automática achar o próximo exercício.
            SingleChildScrollView(
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(12, 12, 12, resting ? 240 : 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final ex in _exercises)
                    Padding(
                      key: ex.key,
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _exerciseCard(s, ex),
                    ),
                  OutlinedButton.icon(
                    onPressed: _addExercise,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Adicionar exercício'),
                  ),
                ],
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              left: 12,
              right: 12,
              bottom: resting ? 16 : -260,
              child: SafeArea(top: false, child: _restPanel()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exerciseCard(AppState s, _ExState ex) {
    final e = exerciseOf(ex.exerciseId);
    final last = s.lastPerformance(ex.exerciseId);
    final allDone = ex.sets.isNotEmpty && ex.sets.every((x) => x.done);
    String? lastTxt;
    if (last != null) {
      final w = last.sets.map((x) => x.weight).fold(0.0, (a, b) => a > b ? a : b);
      lastTxt =
          'Última vez: ${last.sets.length}×${last.sets.first.reps}${w > 0 ? ' · ${fmtNum(w)} kg' : ''}';
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      color: allDone ? const Color(0xFF1C2414) : AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    Text(
                      [e.muscle, if (lastTxt != null) lastTxt].join(' · '),
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (allDone)
                const Icon(Icons.verified_rounded, color: AppColors.volt),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.muted),
                onSelected: (v) {
                  if (v == 'swap') _swapExercise(ex);
                  if (v == 'remove') _update(() => _exercises.remove(ex));
                  if (v == 'tip') {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('💡 ${e.tip}')));
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'tip', child: Text('Dica de execução')),
                  PopupMenuItem(
                      value: 'swap', child: Text('Trocar (aparelho ocupado)')),
                  PopupMenuItem(value: 'remove', child: Text('Remover')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Row(
              children: [
                SizedBox(width: 44, child: Text('SÉRIE', style: _hdr)),
                Expanded(child: Center(child: Text('KG', style: _hdr))),
                Expanded(child: Center(child: Text('REPS', style: _hdr))),
                SizedBox(width: 56),
              ],
            ),
          ),
          for (var i = 0; i < ex.sets.length; i++) _setRow(ex, i),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _update(() {
                  final ref = ex.sets.isEmpty ? _SetEntry(10, 0) : ex.sets.last;
                  ex.sets.add(_SetEntry(ref.reps, ref.weight));
                }),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Série'),
              ),
              if (ex.sets.length > 1 && !ex.sets.last.done)
                TextButton.icon(
                  onPressed: () => _update(() => ex.sets.removeLast()),
                  icon: const Icon(Icons.remove_rounded, size: 18),
                  label: const Text('Série'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.muted),
                ),
              const Spacer(),
              Text('Descanso ${ex.restSec}s',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }

  static const _hdr = TextStyle(
      color: AppColors.muted,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1);

  Widget _setRow(_ExState ex, int i) {
    final set = ex.sets[i];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(top: 6, right: 6),
      decoration: BoxDecoration(
        color: set.done
            ? AppColors.volt.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Center(
              child: Text('${i + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
          Expanded(
            child: _valueBox(
              set.weight == 0 ? '—' : fmtNum(set.weight, decimals: 2),
              set.done,
              () => _editWeight(ex, set),
            ),
          ),
          Expanded(
            child: _valueBox('${set.reps}', set.done, () => _editReps(set)),
          ),
          SizedBox(
            width: 56,
            child: Center(
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _toggleSet(ex, set),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: set.done ? AppColors.volt : AppColors.cardHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded,
                      color: set.done ? Colors.black : AppColors.muted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _valueBox(String text, bool done, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done ? Colors.transparent : AppColors.cardHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(text,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: done ? AppColors.volt : AppColors.text)),
          ),
        ),
      );

  Widget _restPanel() {
    final left = _restLeft;
    final progress = _restTotal == 0 ? 0.0 : 1 - (left / _restTotal);
    return Material(
      color: AppColors.cardHigh,
      borderRadius: BorderRadius.circular(24),
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: AppColors.volt),
                const SizedBox(width: 8),
                const Text('Descanso',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const Spacer(),
                Text(fmtDuration(left),
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        fontFeatures: [FontFeature.tabularFigures()])),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.card,
              ),
            ),
            if (_nextSetLabel != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.arrow_forward_rounded,
                      size: 16, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Próximo: $_nextSetLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _adjustRest(-15),
                    child: const Text('-15s'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _adjustRest(15),
                    child: const Text('+15s'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _skipRest,
                    child: const Text('Pular'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryDialog extends StatelessWidget {
  final WorkoutLog log;
  final List<String> prs;
  final int streak;
  const _SummaryDialog(
      {required this.log, required this.prs, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            const Text('Treino concluído!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            if (streak > 1)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('🔥 $streak dias seguidos',
                    style: const TextStyle(
                        color: AppColors.fire, fontWeight: FontWeight.w800)),
              ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                    child: StatTile(
                        label: 'Duração', value: fmtDuration(log.durationSec))),
                const SizedBox(width: 8),
                Expanded(
                    child:
                        StatTile(label: 'Séries', value: '${log.totalSets}')),
                const SizedBox(width: 8),
                Expanded(
                    child: StatTile(
                        label: 'Volume',
                        value: fmtInt(log.volume),
                        unit: 'kg')),
              ],
            ),
            if (prs.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.volt.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Novos recordes 🎉',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.volt)),
                    const SizedBox(height: 6),
                    for (final p in prs) Text('• $p'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Abre um treino. Se já houver um em andamento, pergunta antes.
Future<void> startWorkout(BuildContext context, WorkoutTemplate template,
    {bool replace = false}) async {
  final s = AppScope.read(context);
  final session = s.activeSession;
  final nav = Navigator.of(context);

  Route<void> route(Widget page) =>
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => page);

  if (session != null) {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Treino em andamento'),
        content: Text(
            'Você não terminou "${session['name']}". Quer continuar de onde parou?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'new'),
            child: const Text('Descartar e começar novo'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'resume'),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (choice == null) return;
    if (choice == 'resume') {
      final page = ActiveWorkoutScreen.resume(session: session);
      replace ? nav.pushReplacement(route(page)) : nav.push(route(page));
      return;
    }
    s.clearSession();
  }
  HapticFeedback.mediumImpact();
  final page = ActiveWorkoutScreen(template: template);
  replace ? nav.pushReplacement(route(page)) : nav.push(route(page));
}
