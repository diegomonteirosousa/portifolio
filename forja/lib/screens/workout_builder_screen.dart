import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../calc.dart';
import '../data/exercises.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'exercise_picker_screen.dart';

/// Montador de treino: escolha exercícios e ajuste séries, reps, carga e descanso.
class WorkoutBuilderScreen extends StatefulWidget {
  final WorkoutTemplate? existing;
  const WorkoutBuilderScreen({super.key, this.existing});

  @override
  State<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends State<WorkoutBuilderScreen> {
  late final TextEditingController _name;
  late final TextEditingController _focus;
  late final List<PlannedExercise> _items;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _focus = TextEditingController(text: e?.focus ?? '');
    _items = e?.exercises.map((x) => x.copy()).toList() ?? [];
  }

  @override
  void dispose() {
    _name.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _addExercises() async {
    final ids = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );
    if (ids == null || ids.isEmpty) return;
    setState(() {
      for (final id in ids) {
        final muscle = exerciseOf(id).muscle;
        final isCardio = muscle == 'Funcional' || muscle == 'Core';
        _items.add(PlannedExercise(
          exerciseId: id,
          sets: 3,
          reps: isCardio ? 15 : 10,
          restSec: isCardio ? 45 : 90,
        ));
      }
    });
  }

  void _save() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Adicione pelo menos um exercício')));
      return;
    }
    final name = _name.text.trim().isEmpty ? 'Meu treino' : _name.text.trim();
    AppScope.read(context).upsertTemplate(WorkoutTemplate(
      id: widget.existing?.id ?? newId(),
      name: name,
      focus: _focus.text.trim(),
      exercises: _items,
      lastUsed: widget.existing?.lastUsed,
    ));
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Montar treino' : 'Editar treino'),
        actions: [
          if (widget.existing != null)
            IconButton(
              tooltip: 'Excluir treino',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () {
                AppScope.read(context).deleteTemplate(widget.existing!.id);
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              decoration: const InputDecoration(
                  hintText: 'Nome do treino (ex.: Treino A · Peito)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _focus,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  hintText: 'Foco ou observação (opcional)'),
            ),
            const SizedBox(height: 8),
            if (_items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                child: Text(
                  '${_items.length} exercícios · ~${estimateMinutes(_items)} min · segure e arraste para reordenar',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              )
            else
              const EmptyState(
                icon: Icons.playlist_add_rounded,
                title: 'Treino vazio',
                message: 'Adicione exercícios da biblioteca para começar.',
              ),
          ],
        ),
        itemCount: _items.length,
        onReorder: (from, to) {
          setState(() {
            if (to > from) to--;
            final item = _items.removeAt(from);
            _items.insert(to, item);
          });
        },
        itemBuilder: (_, i) {
          final item = _items[i];
          return Padding(
            key: ObjectKey(item),
            padding: const EdgeInsets.only(bottom: 10),
            child: _ExerciseEditor(
              item: item,
              onChanged: () => setState(() {}),
              onRemove: () => setState(() => _items.removeAt(i)),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addExercises,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Exercícios'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Salvar treino'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseEditor extends StatelessWidget {
  final PlannedExercise item;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _ExerciseEditor({
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final ex = exerciseOf(item.exerciseId);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 14),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.drag_indicator_rounded,
                  color: AppColors.muted, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex.name,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(ex.muscle,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _MiniStepper(
                label: 'Séries',
                value: item.sets.toDouble(),
                min: 1,
                max: 10,
                onChanged: (v) {
                  item.sets = v.round();
                  onChanged();
                },
              ),
              _MiniStepper(
                label: 'Reps',
                value: item.reps.toDouble(),
                min: 1,
                max: 300,
                onChanged: (v) {
                  item.reps = v.round();
                  onChanged();
                },
              ),
              _MiniStepper(
                label: 'Kg',
                value: item.weight,
                step: 2.5,
                max: 500,
                onChanged: (v) {
                  item.weight = v;
                  onChanged();
                },
              ),
              _MiniStepper(
                label: 'Descanso',
                value: item.restSec.toDouble(),
                step: 15,
                min: 15,
                max: 600,
                suffix: 's',
                onChanged: (v) {
                  item.restSec = v.round();
                  onChanged();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStepper extends StatelessWidget {
  final String label;
  final double value;
  final double step;
  final double min;
  final double max;
  final String suffix;
  final ValueChanged<double> onChanged;

  const _MiniStepper({
    required this.label,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.min = 0,
    this.max = 999,
    this.suffix = '',
  });

  void _set(double v) {
    HapticFeedback.selectionClick();
    onChanged(v.clamp(min, max).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          const SizedBox(height: 4),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              final v = await showNumberDialog(context,
                  title: label, initial: value, unit: suffix);
              if (v != null) _set(v);
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${fmtNum(value)}$suffix',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tiny(Icons.remove_rounded, () => _set(value - step)),
              _tiny(Icons.add_rounded, () => _set(value + step)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tiny(IconData icon, VoidCallback onTap) => InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: AppColors.muted),
        ),
      );
}
