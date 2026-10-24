import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../calc.dart';
import '../data/exercises.dart';
import '../generator.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';

/// Monta um plano completo em poucos toques.
class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  late Goal _goal = AppScope.read(context).profile.goal;
  int _days = 3;
  Place _place = Place.gym;
  Level _level = Level.beginner;
  bool _replace = true;

  List<WorkoutTemplate> get _preview => generatePlan(
        goal: _goal,
        days: _days,
        place: _place,
        level: _level,
        newId: newId,
      );

  void _save() {
    final s = AppScope.read(context);
    final plan = _preview;
    if (_replace) {
      for (final t in [...s.templates]) {
        s.deleteTemplate(t.id);
      }
    }
    for (final t in plan.reversed) {
      s.upsertTemplate(t);
    }
    s.setWeeklyGoal(_days);
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Plano criado: ${plan.length} treinos. Meta semanal ajustada para $_days.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;

    return Scaffold(
      appBar: AppBar(title: const Text('Gerar treino')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        children: [
          const Text(
            'Responda 4 perguntas e o app monta a divisão, os exercícios, as séries e o descanso.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SectionTitle('Objetivo'),
          _chips<Goal>(Goal.values, _goal, (g) => '${g.emoji} ${g.label}',
              (g) => setState(() => _goal = g)),
          const SectionTitle('Dias por semana'),
          Row(
            children: [
              for (var d = 2; d <= 6; d++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _DayButton(
                      day: d,
                      selected: _days == d,
                      onTap: () => setState(() => _days = d),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            switch (_days) {
              2 || 3 => 'Corpo inteiro em cada treino: ótimo para começar.',
              4 => 'Superior e inferior alternados.',
              5 => 'Empurrar, puxar, pernas, superior e inferior.',
              _ => 'Empurrar, puxar e pernas, duas vezes na semana.',
            },
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SectionTitle('Onde você treina?'),
          for (final p in Place.values)
            ChoiceCard(
              leading: p == Place.gym ? '🏋️' : '🏠',
              title: p.label,
              subtitle: p.description,
              selected: _place == p,
              onTap: () => setState(() => _place = p),
            ),
          const SectionTitle('Seu nível'),
          _chips<Level>(Level.values, _level, (l) => l.label,
              (l) => setState(() => _level = l)),
          const SizedBox(height: 4),
          Text(_level.description,
              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const SectionTitle('Prévia do plano'),
          for (final t in preview)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(t.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
                        Text('~${estimateMinutes(t.exercises)} min',
                            style: const TextStyle(color: AppColors.muted)),
                      ],
                    ),
                    Text(t.focus,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                    const SizedBox(height: 8),
                    for (final e in t.exercises)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.circle,
                                size: 6, color: AppColors.volt),
                            const SizedBox(width: 8),
                            Expanded(child: Text(exerciseOf(e.exerciseId).name)),
                            Text('${e.sets}×${e.reps}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _replace,
            onChanged: (v) => setState(() => _replace = v),
            title: const Text('Substituir meus treinos atuais'),
            subtitle: const Text('Desligado: o plano é adicionado aos que você já tem.'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text('Criar plano de $_days dias'),
          ),
        ),
      ),
    );
  }

  Widget _chips<T>(List<T> values, T selected, String Function(T) label,
      ValueChanged<T> onTap) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          ChoiceChip(
            label: Text(label(v)),
            selected: v == selected,
            showCheckmark: false,
            labelStyle: TextStyle(
              color: v == selected ? Colors.black : AppColors.text,
              fontWeight: FontWeight.w700,
            ),
            onSelected: (_) {
              HapticFeedback.selectionClick();
              onTap(v);
            },
          ),
      ],
    );
  }
}

class _DayButton extends StatelessWidget {
  final int day;
  final bool selected;
  final VoidCallback onTap;
  const _DayButton(
      {required this.day, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.volt : AppColors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text('$day',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: selected ? Colors.black : AppColors.text)),
      ),
    );
  }
}
