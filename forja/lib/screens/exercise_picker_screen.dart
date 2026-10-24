import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/exercises.dart';
import '../theme.dart';

/// Biblioteca de exercícios com busca e filtro por músculo.
/// Retorna a lista de ids escolhidos, na ordem em que foram tocados.
class ExercisePickerScreen extends StatefulWidget {
  final bool single;
  const ExercisePickerScreen({super.key, this.single = false});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  String _query = '';
  String? _muscle;
  final List<String> _selected = [];

  String _normalize(String s) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    var out = s.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      out = out.replaceAll(from[i], to[i]);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final q = _normalize(_query);
    final list = exerciseLibrary.where((e) {
      if (_muscle != null && e.muscle != _muscle) return false;
      if (q.isEmpty) return true;
      return _normalize(e.name).contains(q) || _normalize(e.muscle).contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Exercícios')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Buscar exercício',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip('Todos', _muscle == null, () => setState(() => _muscle = null)),
                for (final m in muscleGroups)
                  _chip(m, _muscle == m, () => setState(() => _muscle = m)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final e = list[i];
                final idx = _selected.indexOf(e.id);
                final sel = idx >= 0;
                return ListTile(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (widget.single) {
                      Navigator.pop(context, [e.id]);
                      return;
                    }
                    setState(() {
                      if (sel) {
                        _selected.remove(e.id);
                      } else {
                        _selected.add(e.id);
                      }
                    });
                  },
                  leading: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: sel ? AppColors.volt : AppColors.card,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: sel
                          ? Text('${idx + 1}',
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900))
                          : const Icon(Icons.add_rounded,
                              color: AppColors.muted, size: 20),
                    ),
                  ),
                  title: Text(e.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${e.muscle} · ${e.equipment}\n${e.tip}',
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12)),
                  isThreeLine: true,
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.single || _selected.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  child: Text('Adicionar ${_selected.length} '
                      '${_selected.length == 1 ? 'exercício' : 'exercícios'}'),
                ),
              ),
            ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          labelStyle: TextStyle(
            color: selected ? Colors.black : AppColors.text,
            fontWeight: FontWeight.w700,
          ),
          onSelected: (_) => onTap(),
        ),
      );
}
