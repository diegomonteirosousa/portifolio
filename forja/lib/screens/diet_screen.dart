import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../calc.dart';
import '../data/foods.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';

/// Diário alimentar: tudo que você come, contado contra a sua meta.
class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  DateTime _day = dateOnly(DateTime.now());

  bool get _isToday => _day == dateOnly(DateTime.now());

  void _shiftDay(int delta) {
    final next = _day.add(Duration(days: delta));
    if (next.isAfter(dateOnly(DateTime.now()))) return;
    HapticFeedback.selectionClick();
    setState(() => _day = next);
  }

  Future<void> _add(Meal meal) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FoodPickerScreen(meal: meal, day: _day)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = s.profile;
    final entries = s.foodsOn(_day);
    double sum(double Function(FoodEntry) f) =>
        entries.fold(0.0, (a, e) => a + f(e));
    final kcal = sum((e) => e.kcal);
    final target = Calc.targetKcal(p);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dieta'),
        actions: [
          IconButton(
            onPressed: () => _shiftDay(-1),
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Dia anterior',
          ),
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _day = dateOnly(DateTime.now())),
              child: Text(_isToday ? 'Hoje' : relativeDay(_day),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          IconButton(
            onPressed: _isToday ? null : () => _shiftDay(1),
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Próximo dia',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.volt,
        foregroundColor: Colors.black,
        onPressed: () => _add(MealLabel.byHour(DateTime.now().hour)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Registrar refeição',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        children: [
          _Summary(
            kcal: kcal,
            target: target,
            protein: sum((e) => e.protein),
            carbs: sum((e) => e.carbs),
            fat: sum((e) => e.fat),
            profile: p,
          ),
          const SizedBox(height: 12),
          if (_isToday) _WaterRow(state: s),
          for (final meal in Meal.values)
            _MealSection(
              meal: meal,
              entries: entries.where((e) => e.meal == meal).toList(),
              onAdd: () => _add(meal),
            ),
          const SizedBox(height: 16),
          const Text(
            'Valores aproximados por porção, com base em tabelas brasileiras (TACO). Deslize um item para a esquerda para apagar.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final double kcal, target, protein, carbs, fat;
  final Profile profile;
  const _Summary({
    required this.kcal,
    required this.target,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final left = target - kcal;
    final over = left < 0;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              RingProgress(
                progress: target == 0 ? 0 : kcal / target,
                size: 116,
                stroke: 11,
                color: over ? AppColors.fire : AppColors.volt,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(fmtInt(kcal),
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900)),
                    Text('de ${fmtInt(target)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(over ? 'Acima da meta' : 'Restam',
                        style: TextStyle(
                            color: over ? AppColors.fire : AppColors.muted)),
                    Text('${fmtInt(left.abs())} kcal',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: over ? AppColors.fire : AppColors.text)),
                    const SizedBox(height: 4),
                    Text('Meta: ${profile.goal.label.toLowerCase()}',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _macro('Proteína', protein, Calc.proteinG(profile),
              const Color(0xFFFF8A80)),
          _macro('Carboidrato', carbs, Calc.carbsG(profile),
              const Color(0xFFFFD180)),
          _macro('Gordura', fat, Calc.fatG(profile), const Color(0xFF80D8FF)),
        ],
      ),
    );
  }

  Widget _macro(String label, double value, double goal, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          SizedBox(
              width: 92,
              child: Text(label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: goal <= 0 ? 0 : (value / goal).clamp(0.0, 1.0),
                minHeight: 8,
                color: color,
                backgroundColor: AppColors.cardHigh,
              ),
            ),
          ),
          SizedBox(
            width: 84,
            child: Text('${value.round()}/${goal.round()} g',
                textAlign: TextAlign.right,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _WaterRow extends StatelessWidget {
  final AppState state;
  const _WaterRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final goal = state.waterGoalToday;
    final drunk = state.waterToday;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            const Icon(Icons.water_drop_rounded, color: AppColors.water),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Água: ${fmtNum(drunk / 1000)} de ${fmtNum(goal / 1000)} L',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: goal == 0 ? 0 : (drunk / goal).clamp(0.0, 1.0),
                      minHeight: 6,
                      color: AppColors.water,
                      backgroundColor: AppColors.cardHigh,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '+250 ml',
              onPressed: () {
                HapticFeedback.lightImpact();
                state.addWater(250);
              },
              icon: const Icon(Icons.add_circle_rounded,
                  color: AppColors.water, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  final Meal meal;
  final List<FoodEntry> entries;
  final VoidCallback onAdd;
  const _MealSection(
      {required this.meal, required this.entries, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.read(context);
    final total = entries.fold(0.0, (a, e) => a + e.kcal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 0, 6),
          child: Row(
            children: [
              Text('${meal.emoji}  ${meal.label}',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (total > 0)
                Text('${fmtInt(total)} kcal',
                    style: const TextStyle(color: AppColors.muted)),
              IconButton(
                tooltip: 'Adicionar em ${meal.label}',
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, color: AppColors.volt),
              ),
            ],
          ),
        ),
        if (entries.isEmpty)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onAdd,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.cardHigh, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('Toque para adicionar',
                  style: TextStyle(color: AppColors.muted)),
            ),
          ),
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Dismissible(
              key: ValueKey(e.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.danger),
              ),
              onDismissed: (_) {
                s.removeFood(e.id);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${e.name} removido'),
                  action: SnackBarAction(
                      label: 'Desfazer', onPressed: () => s.addFood(e)),
                ));
              },
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                            '${fmtNum(e.servings)} porç. · P ${e.protein.round()} g · C ${e.carbs.round()} g · G ${e.fat.round()} g',
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text('${fmtInt(e.kcal)} kcal',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------- Escolher alimento ----------------

class FoodPickerScreen extends StatefulWidget {
  final Meal meal;
  final DateTime day;
  const FoodPickerScreen({super.key, required this.meal, required this.day});

  @override
  State<FoodPickerScreen> createState() => _FoodPickerScreenState();
}

class _FoodPickerScreenState extends State<FoodPickerScreen> {
  String _query = '';
  String? _category;
  late Meal _meal = widget.meal;

  String _norm(String s) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    var out = s.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      out = out.replaceAll(from[i], to[i]);
    }
    return out;
  }

  DateTime get _entryDate {
    final now = DateTime.now();
    final d = widget.day;
    if (dateOnly(now) == d) return now;
    return DateTime(d.year, d.month, d.day, 12);
  }

  Future<void> _choose({
    required String name,
    required String portion,
    required double kcal,
    required double protein,
    required double carbs,
    required double fat,
    double servings = 1,
  }) async {
    final result = await showModalBottomSheet<(double, Meal)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _PortionSheet(
        name: name,
        portion: portion,
        kcal: kcal,
        protein: protein,
        carbs: carbs,
        fat: fat,
        initialServings: servings,
        meal: _meal,
      ),
    );
    if (result == null || !mounted) return;
    final (qty, meal) = result;
    AppScope.read(context).addFood(FoodEntry(
      id: newId(),
      date: _entryDate,
      meal: meal,
      name: name,
      servings: qty,
      kcal: kcal * qty,
      protein: protein * qty,
      carbs: carbs * qty,
      fat: fat * qty,
    ));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$name adicionado em ${meal.label}'),
      duration: const Duration(seconds: 2),
    ));
    Navigator.pop(context);
  }

  Future<void> _manual() async {
    final name = TextEditingController();
    final kcal = TextEditingController();
    final prot = TextEditingController();
    final carb = TextEditingController();
    final fat = TextEditingController();
    double n(TextEditingController c) =>
        double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar manualmente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Nome do alimento'),
              ),
              const SizedBox(height: 8),
              _numField(kcal, 'Calorias (kcal)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _numField(prot, 'Prot. g')),
                  const SizedBox(width: 6),
                  Expanded(child: _numField(carb, 'Carb. g')),
                  const SizedBox(width: 6),
                  Expanded(child: _numField(fat, 'Gord. g')),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continuar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (name.text.trim().isEmpty || n(kcal) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Informe pelo menos o nome e as calorias')));
      return;
    }
    await _choose(
      name: name.text.trim(),
      portion: '1 porção',
      kcal: n(kcal),
      protein: n(prot),
      carbs: n(carb),
      fat: n(fat),
    );
  }

  Widget _numField(TextEditingController c, String hint) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          hintText: hint,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final q = _norm(_query);
    final foods = foodDatabase.where((f) {
      if (_category != null && f.category != _category) return false;
      return q.isEmpty || _norm(f.name).contains(q);
    }).toList();
    final recents = q.isEmpty && _category == null ? s.recentFoods : <FoodEntry>[];

    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar · ${_meal.label}'),
        actions: [
          PopupMenuButton<Meal>(
            tooltip: 'Trocar refeição',
            icon: const Icon(Icons.swap_horiz_rounded),
            onSelected: (m) => setState(() => _meal = m),
            itemBuilder: (_) => [
              for (final m in Meal.values)
                PopupMenuItem(value: m, child: Text('${m.emoji}  ${m.label}')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              autofocus: false,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Buscar: arroz, frango, banana…',
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
                _chip('Todos', _category == null,
                    () => setState(() => _category = null)),
                for (final c in foodCategories)
                  _chip(c, _category == c, () => setState(() => _category = c)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.cardHigh,
                    child: Icon(Icons.edit_note_rounded, color: AppColors.volt),
                  ),
                  title: const Text('Adicionar manualmente',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Digite nome e calorias da embalagem'),
                  onTap: _manual,
                ),
                if (recents.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text('RECENTES',
                        style: TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            fontSize: 12)),
                  ),
                  for (final r in recents)
                    ListTile(
                      leading: const Icon(Icons.history_rounded,
                          color: AppColors.muted),
                      title: Text(r.name),
                      subtitle: Text(
                          '${fmtInt(r.kcal / r.servings)} kcal por porção',
                          style: const TextStyle(color: AppColors.muted)),
                      onTap: () => _choose(
                        name: r.name,
                        portion: '1 porção',
                        kcal: r.kcal / r.servings,
                        protein: r.protein / r.servings,
                        carbs: r.carbs / r.servings,
                        fat: r.fat / r.servings,
                        servings: r.servings,
                      ),
                    ),
                  const Divider(),
                ],
                for (final f in foods)
                  ListTile(
                    title: Text(f.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(f.portion,
                        style: const TextStyle(color: AppColors.muted)),
                    trailing: Text('${fmtInt(f.kcal)} kcal',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    onTap: () => _choose(
                      name: f.name,
                      portion: f.portion,
                      kcal: f.kcal,
                      protein: f.protein,
                      carbs: f.carbs,
                      fat: f.fat,
                    ),
                  ),
                if (foods.isEmpty)
                  const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Nada encontrado',
                    message: 'Use "Adicionar manualmente" com os dados da embalagem.',
                  ),
              ],
            ),
          ),
        ],
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

class _PortionSheet extends StatefulWidget {
  final String name;
  final String portion;
  final double kcal, protein, carbs, fat, initialServings;
  final Meal meal;

  const _PortionSheet({
    required this.name,
    required this.portion,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.initialServings,
    required this.meal,
  });

  @override
  State<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends State<_PortionSheet> {
  late double _qty = widget.initialServings;
  late Meal _meal = widget.meal;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(w.name,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            Text('Porção: ${w.portion}',
                style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            NumberStepper(
              label: 'Quantidade de porções',
              value: _qty,
              step: 0.5,
              min: 0.5,
              max: 20,
              decimals: 1,
              unit: '×',
              onChanged: (v) => setState(() => _qty = v),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: StatTile(
                        label: 'Calorias',
                        value: fmtInt(w.kcal * _qty),
                        unit: 'kcal')),
                const SizedBox(width: 8),
                Expanded(
                    child: StatTile(
                        label: 'Proteína',
                        value: '${(w.protein * _qty).round()}',
                        unit: 'g')),
                const SizedBox(width: 8),
                Expanded(
                    child: StatTile(
                        label: 'Carbo',
                        value: '${(w.carbs * _qty).round()}',
                        unit: 'g')),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in Meal.values)
                  ChoiceChip(
                    label: Text(m.label),
                    selected: _meal == m,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: _meal == m ? Colors.black : AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => setState(() => _meal = m),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, (_qty, _meal)),
                child: const Text('Adicionar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
