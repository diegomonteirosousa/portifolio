import 'package:flutter/material.dart';

import '../calc.dart';
import '../data/routines.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'active_workout_screen.dart';
import 'generator_screen.dart';
import 'routine_detail_screen.dart';
import 'workout_builder_screen.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  String _category = 'Todos';

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final filtered = _category == 'Todos'
        ? routines
        : routines.where((r) => r.category == _category).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Treinos')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.volt,
        foregroundColor: Colors.black,
        onPressed: () => showNewWorkoutOptions(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo treino',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: SectionTitle('Rotinas temáticas'),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final c in routineCategories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: _category == c ? Colors.black : AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) => setState(() => _category = c),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _RoutineCard(routine: filtered[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionTitle('Meus treinos (${s.templates.length})'),
          ),
          if (s.templates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const GeneratorScreen())),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: AppColors.volt),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          'Nenhum treino salvo. Toque aqui para o app montar um plano para você.'),
                    ),
                  ],
                ),
              ),
            ),
          for (final t in s.templates)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _TemplateTile(template: t),
            ),
        ],
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final Routine routine;
  const _RoutineCard({required this.routine});

  @override
  Widget build(BuildContext context) {
    final c = Color(routine.color);
    return SizedBox(
      width: 230,
      child: AppCard(
        padding: const EdgeInsets.all(16),
        gradient: LinearGradient(
          colors: [c.withValues(alpha: 0.85), c.withValues(alpha: 0.25)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => RoutineDetailScreen(routine: routine)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(routine.category.toUpperCase(),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.white70)),
            const Spacer(),
            Text(
              routine.nickname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              routine.focus,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Difficulty(routine.difficulty, color: Colors.white),
                const Spacer(),
                Text('${routine.minutes} min',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final WorkoutTemplate template;
  const _TemplateTile({required this.template});

  @override
  Widget build(BuildContext context) {
    final t = template;
    final s = AppScope.read(context);
    final meta = [
      '${t.exercises.length} exercícios',
      '~${estimateMinutes(t.exercises)} min',
      if (t.lastUsed != null) relativeDay(t.lastUsed!),
    ].join(' · ');

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => WorkoutBuilderScreen(existing: t)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                if (t.focus.isNotEmpty)
                  Text(t.focus,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 4),
                Text(meta,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.muted),
            onSelected: (v) {
              if (v == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => WorkoutBuilderScreen(existing: t)),
                );
              } else if (v == 'dup') {
                s.upsertTemplate(WorkoutTemplate(
                  id: newId(),
                  name: '${t.name} (cópia)',
                  focus: t.focus,
                  exercises: t.exercises.map((e) => e.copy()).toList(),
                ));
              } else if (v == 'del') {
                s.deleteTemplate(t.id);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('"${t.name}" excluído'),
                  action: SnackBarAction(
                    label: 'Desfazer',
                    onPressed: () => s.upsertTemplate(t),
                  ),
                ));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'dup', child: Text('Duplicar')),
              PopupMenuItem(value: 'del', child: Text('Excluir')),
            ],
          ),
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.volt,
              foregroundColor: Colors.black,
            ),
            tooltip: 'Começar',
            onPressed: () => startWorkout(context, t),
            icon: const Icon(Icons.play_arrow_rounded),
          ),
        ],
      ),
    );
  }
}

/// Escolha entre gerar um plano automático ou montar do zero.
void showNewWorkoutOptions(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Novo treino',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            AppCard(
              color: AppColors.cardHigh,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const GeneratorScreen()));
              },
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: AppColors.volt, size: 30),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gerar automaticamente',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                        Text('Objetivo, dias, local e nível: o app monta tudo',
                            style: TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            AppCard(
              color: AppColors.cardHigh,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const WorkoutBuilderScreen()));
              },
              child: const Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: AppColors.text, size: 30),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Montar do zero',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                        Text('Escolha cada exercício, série e carga',
                            style: TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
