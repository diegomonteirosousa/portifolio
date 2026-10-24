import 'package:flutter/material.dart';

import '../data/exercises.dart';
import '../data/routines.dart';
import '../state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'active_workout_screen.dart';

class RoutineDetailScreen extends StatelessWidget {
  final Routine routine;
  const RoutineDetailScreen({super.key, required this.routine});

  @override
  Widget build(BuildContext context) {
    final r = routine;
    final c = Color(r.color);
    final totalSets = r.exercises.fold(0, (sum, e) => sum + e.sets);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: c,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
              title: Text(r.nickname,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c, AppColors.bg],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Align(
                  alignment: const Alignment(0.85, -0.1),
                  child: Icon(Icons.local_fire_department_rounded,
                      size: 120, color: Colors.white.withValues(alpha: 0.12)),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(r.focus,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(r.story,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 15, height: 1.4)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                          label: 'Duração', value: '${r.minutes}', unit: 'min'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                          label: 'Séries', value: '$totalSets'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(child: Difficulty(r.difficulty)),
                            const SizedBox(height: 10),
                            const Text('Nível',
                                style: TextStyle(
                                    color: AppColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (r.difficulty >= 5) ...[
                  const SizedBox(height: 12),
                  const Text(
                    '⚠️ Rotina avançada. Iniciante? Reduza séries e cargas pela metade nas primeiras semanas.',
                    style: TextStyle(color: AppColors.fire, fontSize: 13),
                  ),
                ],
                const SectionTitle('Exercícios'),
                for (var i = 0; i < r.exercises.length; i++)
                  _exerciseRow(i, r.exercises[i]),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppScope.read(context).upsertTemplate(r.toTemplate(newId()));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Rotina ${r.nickname} salva em Meus treinos')));
                  },
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Salvar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => startWorkout(context, r.toTemplate(newId()),
                      replace: true),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Começar agora'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exerciseRow(int i, RX e) {
    final ex = exerciseOf(e.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.cardHigh,
              child: Text('${i + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.text)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ex.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('${ex.muscle} · descanso ${e.rest}s',
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
            Text('${e.sets}×${e.reps}',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
