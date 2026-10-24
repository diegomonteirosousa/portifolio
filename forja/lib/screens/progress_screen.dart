import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../calc.dart';
import '../data/exercises.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Progresso'),
          bottom: const TabBar(
            indicatorColor: AppColors.volt,
            labelColor: AppColors.volt,
            unselectedLabelColor: AppColors.muted,
            dividerColor: Colors.transparent,
            labelStyle: TextStyle(fontWeight: FontWeight.w800),
            tabs: [
              Tab(text: 'Resumo'),
              Tab(text: 'Peso'),
              Tab(text: 'Recordes'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_SummaryTab(), _WeightTab(), _RecordsTab()],
        ),
      ),
    );
  }
}

// ---------------- Resumo ----------------

class _SummaryTab extends StatelessWidget {
  const _SummaryTab();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final workouts = s.workoutsThisWeek;
    final runs = s.runsThisWeek;
    final km = runs.fold(0.0, (a, r) => a + r.distanceM) / 1000;
    final volume = workouts.fold(0.0, (a, w) => a + w.volume);
    final minutes = (workouts.fold(0, (a, w) => a + w.durationSec) +
            runs.fold(0, (a, r) => a + r.durationSec)) ~/
        60;
    final muscles = s.muscleSetsThisWeek;
    final maxSets = muscles.values.fold(1, math.max);

    final history = <({DateTime date, Widget tile})>[
      for (final w in s.workoutLogs.take(40))
        (date: w.start, tile: _WorkoutLogTile(log: w)),
      for (final r in s.runLogs.take(40))
        (date: r.start, tile: _RunLogTile(run: r)),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const Text('Esta semana',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: [
            StatTile(
                icon: Icons.fitness_center_rounded,
                label: 'Treinos',
                value: '${workouts.length}'),
            StatTile(
                icon: Icons.route_rounded,
                color: AppColors.water,
                label: 'Corrida',
                value: fmtNum(km),
                unit: 'km'),
            StatTile(
                icon: Icons.scale_rounded,
                color: AppColors.fire,
                label: 'Volume levantado',
                value: fmtInt(volume),
                unit: 'kg'),
            StatTile(
                icon: Icons.schedule_rounded,
                color: AppColors.text,
                label: 'Tempo ativo',
                value: '$minutes',
                unit: 'min'),
          ],
        ),
        const SectionTitle('Músculos treinados (séries)'),
        AppCard(
          child: Column(
            children: [
              for (final m in muscleGroups)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(m,
                            style: TextStyle(
                                color: (muscles[m] ?? 0) == 0
                                    ? AppColors.muted
                                    : AppColors.text,
                                fontSize: 13)),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (muscles[m] ?? 0) / maxSets,
                            minHeight: 10,
                            backgroundColor: AppColors.cardHigh,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        child: Text('${muscles[m] ?? 0}',
                            textAlign: TextAlign.right,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              if (muscles.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                      'Nenhum treino nesta semana ainda. Os músculos esquecidos ficam em cinza.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ),
            ],
          ),
        ),
        const SectionTitle('Histórico'),
        if (history.isEmpty)
          const EmptyState(
            icon: Icons.history_rounded,
            title: 'Nada por aqui ainda',
            message: 'Treinos e corridas concluídos aparecem nesta lista.',
          ),
        for (final h in history)
          Padding(padding: const EdgeInsets.only(bottom: 10), child: h.tile),
      ],
    );
  }
}

class _WorkoutLogTile extends StatelessWidget {
  final WorkoutLog log;
  const _WorkoutLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => _details(context),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.cardHigh,
            child: Icon(Icons.fitness_center_rounded, color: AppColors.volt),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.name,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                    '${fmtDuration(log.durationSec)} · ${log.totalSets} séries · ${fmtInt(log.volume)} kg',
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          Text(relativeDay(log.start),
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }

  void _details(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20),
            children: [
              Text(fmtDateTime(log.start),
                  style: const TextStyle(color: AppColors.muted)),
              Text(log.name,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              for (final e in log.exercises) ...[
                Text(exerciseOf(e.exerciseId).name,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final st in e.sets)
                      Chip(
                        label: Text(st.weight > 0
                            ? '${fmtNum(st.weight)} kg × ${st.reps}'
                            : '${st.reps} reps'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              TextButton.icon(
                onPressed: () {
                  AppScope.read(context).deleteWorkoutLog(log.id);
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.danger),
                label: const Text('Excluir registro',
                    style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunLogTile extends StatelessWidget {
  final RunLog run;
  const _RunLogTile({required this.run});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.cardHigh,
            child: Icon(Icons.directions_run_rounded, color: AppColors.water),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Corrida · ${fmtKm(run.distanceM)} km',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                    '${fmtDuration(run.durationSec)} · ${fmtPace(run.paceSecPerKm)} /km',
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          Text(relativeDay(run.start),
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

// ---------------- Peso ----------------

class _WeightTab extends StatelessWidget {
  const _WeightTab();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final log = s.weightLog;
    final p = s.profile;
    final change = log.isEmpty ? 0.0 : p.weight - log.first.kg;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                  label: 'Peso atual', value: fmtNum(p.weight), unit: 'kg'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Desde o início',
                value: '${change > 0 ? '+' : ''}${fmtNum(change)}',
                unit: 'kg',
                color: AppColors.fire,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'IMC',
                value: fmtNum(Calc.bmi(p)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          child: SizedBox(
            height: 200,
            child: log.length < 2
                ? const Center(
                    child: Text(
                      'Registre seu peso em dias diferentes para ver o gráfico.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : CustomPaint(
                    painter: _WeightChart(log, target: p.targetWeight),
                    size: Size.infinite,
                  ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () async {
            final v = await showNumberDialog(context,
                title: 'Peso de hoje', initial: p.weight, unit: 'kg');
            if (v != null && v > 20 && v < 400) s.addWeight(v);
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Registrar peso'),
        ),
        const SectionTitle('Registros'),
        for (final w in log.reversed.take(30))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.monitor_weight_outlined,
                color: AppColors.muted),
            title: Text('${fmtNum(w.kg)} kg',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            trailing: Text(fmtDate(w.date),
                style: const TextStyle(color: AppColors.muted)),
          ),
      ],
    );
  }
}

class _WeightChart extends CustomPainter {
  final List<WeightEntry> data;
  final double? target;
  _WeightChart(this.data, {this.target});

  @override
  void paint(Canvas canvas, Size size) {
    final values = data.map((e) => e.kg).toList();
    var minV = values.reduce(math.min);
    var maxV = values.reduce(math.max);
    final t = target;
    if (t != null) {
      minV = math.min(minV, t);
      maxV = math.max(maxV, t);
    }
    minV -= 1;
    maxV += 1;

    const left = 36.0, bottom = 22.0, top = 8.0;
    final w = size.width - left;
    final h = size.height - bottom - top;
    final t0 = data.first.date.millisecondsSinceEpoch.toDouble();
    final t1 = data.last.date.millisecondsSinceEpoch.toDouble();
    final span = math.max(t1 - t0, 1.0);

    double y(double v) => top + h - (v - minV) / (maxV - minV) * h;
    double x(DateTime d) => left + (d.millisecondsSinceEpoch - t0) / span * w;

    final label = TextPainter(textDirection: TextDirection.ltr);
    final grid = Paint()
      ..color = AppColors.cardHigh
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final v = minV + (maxV - minV) * i / 3;
      final yy = y(v);
      canvas.drawLine(Offset(left, yy), Offset(size.width, yy), grid);
      label
        ..text = TextSpan(
            text: v.toStringAsFixed(0),
            style: const TextStyle(color: AppColors.muted, fontSize: 10))
        ..layout();
      label.paint(canvas, Offset(0, yy - label.height / 2));
    }

    if (t != null) {
      final yy = y(t);
      final dash = Paint()
        ..color = AppColors.fire
        ..strokeWidth = 1.5;
      for (var xx = left; xx < size.width; xx += 10) {
        canvas.drawLine(Offset(xx, yy), Offset(xx + 5, yy), dash);
      }
      label
        ..text = const TextSpan(
            text: 'meta',
            style: TextStyle(color: AppColors.fire, fontSize: 10))
        ..layout();
      label.paint(canvas, Offset(size.width - label.width, yy - 14));
    }

    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final o = Offset(x(data[i].date), y(data[i].kg));
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.volt
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
    for (final e in data) {
      canvas.drawCircle(
          Offset(x(e.date), y(e.kg)), 3.5, Paint()..color = AppColors.volt);
    }

    for (final e in [data.first, data.last]) {
      label
        ..text = TextSpan(
            text: fmtDate(e.date),
            style: const TextStyle(color: AppColors.muted, fontSize: 10))
        ..layout();
      final dx = math.max(
          left, math.min(x(e.date) - label.width / 2, size.width - label.width));
      label.paint(canvas, Offset(dx, size.height - 14));
    }
  }

  @override
  bool shouldRepaint(_WeightChart old) => true;
}

// ---------------- Recordes ----------------

class _RecordsTab extends StatelessWidget {
  const _RecordsTab();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final prs = s.personalRecords;
    if (prs.isEmpty) {
      return const EmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'Sem recordes ainda',
        message:
            'Registre a carga nas séries e seus melhores levantamentos aparecem aqui.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: prs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final pr = prs[i];
        final e = exerciseOf(pr.exerciseId);
        return AppCard(
          child: Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(
                        '1RM estimado: ${fmtNum(Calc.oneRm(pr.weight, pr.reps))} kg · ${fmtDate(pr.date)}',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${fmtNum(pr.weight)} kg',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.volt)),
                  Text('× ${pr.reps}',
                      style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
