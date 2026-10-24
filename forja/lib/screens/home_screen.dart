import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../calc.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'active_workout_screen.dart';
import 'diet_screen.dart';
import 'generator_screen.dart';
import 'profile_screen.dart';
import 'shell.dart';
import 'workouts_screen.dart';

const _tips = [
  'Dormir 7 a 9 horas rende mais ganho do que qualquer suplemento.',
  'Bateu as repetições em todas as séries? Suba um pouco a carga na próxima.',
  'Proteína espalhada em 3 a 5 refeições ajuda na recuperação.',
  'Aquecimento leve antes da carga pesada protege as articulações.',
  'Constância vence intensidade: 3 treinos por semana todo mês valem mais que 6 numa semana só.',
  'Sede já é sinal de desidratação leve. Beba antes dela chegar.',
  'Uma semana mais leve a cada 6 a 8 semanas ajuda a voltar mais forte.',
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  Future<void> _logWeight(BuildContext context, AppState s) async {
    final v = await showNumberDialog(context,
        title: 'Peso de hoje', initial: s.profile.weight, unit: 'kg');
    if (v == null || v <= 20 || v >= 400) return;
    final before = s.profile.weight;
    s.addWeight(v);
    if (!context.mounted) return;
    final diff = v - before;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(diff.abs() < 0.05
            ? 'Peso registrado: ${fmtNum(v)} kg.'
            : 'Peso registrado: ${fmtNum(v)} kg (${diff > 0 ? '+' : ''}${fmtNum(diff)} kg). Metas recalculadas.')));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final name = s.profile.name;
    final tip = _tips[DateTime.now().day % _tips.length];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting(),
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 15)),
                    Text(
                      name.isEmpty ? 'Bora treinar?' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8),
                    ),
                  ],
                ),
              ),
              _StreakPill(streak: s.streak),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Perfil e ajustes',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.volt,
                    child: Text(
                      name.isEmpty ? '💪' : name[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (s.activeSession != null) ...[
            _ResumeBanner(session: s.activeSession!),
            const SizedBox(height: 12),
          ],
          const _TodayWorkoutCard(),
          const SizedBox(height: 12),
          _WeekCard(state: s),
          const SizedBox(height: 12),
          const _WaterCard(),
          const SizedBox(height: 12),
          _NutritionCard(state: s),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.6,
            children: [
              _QuickAction(
                icon: Icons.directions_run_rounded,
                label: 'Correr agora',
                onTap: () => MainShell.goTo(context, MainShell.run),
              ),
              _QuickAction(
                icon: Icons.restaurant_rounded,
                label: 'Registrar refeição',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FoodPickerScreen(
                      meal: MealLabel.byHour(DateTime.now().hour),
                      day: dateOnly(DateTime.now()),
                    ),
                  ),
                ),
              ),
              _QuickAction(
                icon: Icons.monitor_weight_outlined,
                label: 'Registrar peso',
                onTap: () => _logWeight(context, s),
              ),
              _QuickAction(
                icon: Icons.add_circle_outline_rounded,
                label: 'Novo treino',
                onTap: () => showNewWorkoutOptions(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    color: AppColors.volt),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dica do dia',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(tip,
                          style: const TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeBanner extends StatelessWidget {
  final Map<String, dynamic> session;
  const _ResumeBanner({required this.session});

  @override
  Widget build(BuildContext context) {
    final started = DateTime.tryParse(session['started'] as String? ?? '');
    final exercises = (session['exercises'] as List?) ?? const [];
    var done = 0, total = 0;
    for (final e in exercises) {
      for (final st in ((e as Map)['sets'] as List)) {
        total++;
        if ((st as Map)['d'] == true) done++;
      }
    }
    return AppCard(
      color: AppColors.fire.withValues(alpha: 0.16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => ActiveWorkoutScreen.resume(session: session),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle_fill_rounded,
              color: AppColors.fire, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Treino em andamento',
                    style: TextStyle(
                        color: AppColors.fire, fontWeight: FontWeight.w800)),
                Text('${session['name']} · $done de $total séries'
                    '${started == null ? '' : ' · desde ${two(started.hour)}:${two(started.minute)}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Text('Retomar',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  final int streak;
  const _StreakPill({required this.streak});

  @override
  Widget build(BuildContext context) {
    final on = streak > 0;
    return Tooltip(
      message: 'Dias seguidos com treino ou corrida',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: on ? AppColors.fire.withValues(alpha: 0.15) : AppColors.card,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department_rounded,
                color: on ? AppColors.fire : AppColors.muted, size: 22),
            const SizedBox(width: 4),
            Text('$streak',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: on ? AppColors.fire : AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _TodayWorkoutCard extends StatelessWidget {
  const _TodayWorkoutCard();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = s.suggestedTemplate;
    final doneToday = s.workoutLogs.any(
        (l) => dayKey(l.start) == dayKey(DateTime.now()));

    if (t == null) {
      return AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vamos montar seu treino?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text(
                'Responda 4 perguntas e receba um plano pronto, com séries e descanso.',
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const GeneratorScreen())),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Gerar meu plano'),
            ),
          ],
        ),
      );
    }

    final minutes = estimateMinutes(t.exercises);
    return AppCard(
      padding: const EdgeInsets.all(20),
      gradient: const LinearGradient(
        colors: [Color(0xFF2A3510), Color(0xFF1B1F14)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(doneToday ? 'PRÓXIMO TREINO' : 'TREINO DE HOJE',
                  style: const TextStyle(
                      color: AppColors.volt,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      fontSize: 12)),
              const Spacer(),
              if (doneToday)
                const Text('✅ Hoje já foi',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(t.name,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5)),
          if (t.focus.isNotEmpty)
            Text(t.focus, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 12),
          Row(
            children: [
              _meta(Icons.list_rounded, '${t.exercises.length} exercícios'),
              const SizedBox(width: 16),
              _meta(Icons.schedule_rounded, '~$minutes min'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => startWorkout(context, t),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Começar treino'),
                ),
              ),
              if (s.templates.length > 1) ...[
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Escolher outro treino',
                  style: IconButton.styleFrom(
                      minimumSize: const Size(52, 52),
                      backgroundColor: AppColors.cardHigh),
                  onPressed: () => MainShell.goTo(context, MainShell.workouts),
                  icon: const Icon(Icons.swap_horiz_rounded),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: AppColors.muted)),
        ],
      );
}

class _WeekCard extends StatelessWidget {
  final AppState state;
  const _WeekCard({required this.state});

  Future<void> _editGoal(BuildContext context) async {
    final goal = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Meta da semana',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text('Quantos dias por semana você quer se exercitar?',
                  style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (var d = 1; d <= 7; d++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(ctx, d),
                          child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: state.weeklyGoal == d
                                  ? AppColors.volt
                                  : AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('$d',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: state.weeklyGoal == d
                                        ? Colors.black
                                        : AppColors.text)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (goal != null) state.setWeeklyGoal(goal);
  }

  @override
  Widget build(BuildContext context) {
    final start = state.weekStart;
    final days = state.activeDays;
    final today = dayKey(DateTime.now());
    final done = state.activitiesThisWeek;
    final goal = state.weeklyGoal;
    final reached = done >= goal;

    return AppCard(
      onTap: () => _editGoal(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RingProgress(
                progress: done / goal,
                size: 46,
                stroke: 6,
                color: reached ? AppColors.fire : AppColors.volt,
                center: Text('$done',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 15)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        reached
                            ? 'Meta da semana batida! 🎉'
                            : 'Esta semana: $done de $goal dias',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(
                        reached
                            ? 'Tudo a partir daqui é bônus.'
                            : 'Faltam ${goal - done}. Toque para mudar a meta.',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final d = start.add(Duration(days: i));
              final k = dayKey(d);
              final active = days.contains(k);
              final isToday = k == today;
              return Column(
                children: [
                  Text(weekdayShort[i],
                      style: TextStyle(
                          color: isToday ? AppColors.volt : AppColors.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: active ? AppColors.volt : AppColors.cardHigh,
                      shape: BoxShape.circle,
                      border: isToday && !active
                          ? Border.all(color: AppColors.volt, width: 2)
                          : null,
                    ),
                    child: active
                        ? const Icon(Icons.check_rounded,
                            size: 18, color: Colors.black)
                        : Center(
                            child: Text('${d.day}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.muted))),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  const _WaterCard();

  void _add(BuildContext context, AppState s, int ml) {
    final before = s.waterToday;
    s.addWater(ml);
    HapticFeedback.lightImpact();
    final goal = s.waterGoalToday;
    if (before < goal && s.waterToday >= goal) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meta de água batida! 💧🎉')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final goal = s.waterGoalToday;
    final drunk = s.waterToday;
    final progress = goal == 0 ? 0.0 : drunk / goal;

    return AppCard(
      child: Row(
        children: [
          RingProgress(
            progress: progress,
            color: AppColors.water,
            size: 104,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.water_drop_rounded,
                    color: AppColors.water, size: 20),
                Text(fmtNum(drunk / 1000),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900)),
                Text('de ${fmtNum(goal / 1000)} L',
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Água',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                    if (drunk > 0)
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => s.addWater(-250),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.undo_rounded,
                              size: 18, color: AppColors.muted),
                        ),
                      ),
                  ],
                ),
                Text(
                  drunk >= goal
                      ? 'Meta do dia concluída!'
                      : 'Faltam ${fmtNum((goal - drunk) / 1000)} L'
                          '${s.trainingHoursToday > 0 ? ' (meta maior por causa do treino)' : ''}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final ml in const [250, 500])
                      ActionChip(
                        avatar: const Icon(Icons.add_rounded,
                            size: 16, color: AppColors.water),
                        label: Text('$ml ml'),
                        onPressed: () => _add(context, s, ml),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final AppState state;
  const _NutritionCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final p = state.profile;
    final today = state.foodsOn(DateTime.now());
    double sum(double Function(FoodEntry) f) =>
        today.fold(0.0, (a, e) => a + f(e));
    final eaten = sum((e) => e.kcal);
    final target = Calc.targetKcal(p);
    final left = target - eaten;

    return AppCard(
      onTap: () => MainShell.goTo(context, MainShell.diet),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Alimentação de hoje',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const Spacer(),
              Text(p.goal.label,
                  style: const TextStyle(color: AppColors.muted)),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
          const SizedBox(height: 10),
          Text.rich(TextSpan(children: [
            TextSpan(
                text: fmtInt(eaten),
                style: const TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w900)),
            TextSpan(
                text: ' / ${fmtInt(target)} kcal',
                style: const TextStyle(color: AppColors.muted, fontSize: 15)),
          ])),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: target == 0 ? 0 : (eaten / target).clamp(0.0, 1.0),
              minHeight: 8,
              color: left < 0 ? AppColors.fire : AppColors.volt,
              backgroundColor: AppColors.cardHigh,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            today.isEmpty
                ? 'Nada registrado ainda. Toque para anotar o que comeu.'
                : left >= 0
                    ? 'Restam ${fmtInt(left)} kcal'
                    : '${fmtInt(-left)} kcal acima da meta',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _macro('Proteína', sum((e) => e.protein), Calc.proteinG(p),
                  const Color(0xFFFF8A80)),
              _macro('Carbo', sum((e) => e.carbs), Calc.carbsG(p),
                  const Color(0xFFFFD180)),
              _macro('Gordura', sum((e) => e.fat), Calc.fatG(p),
                  const Color(0xFF80D8FF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macro(String label, double value, double goal, Color color) =>
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: goal <= 0 ? 0 : (value / goal).clamp(0.0, 1.0),
                  minHeight: 4,
                  color: color,
                  backgroundColor: AppColors.cardHigh,
                ),
              ),
              const SizedBox(height: 6),
              Text('${value.round()}/${goal.round()} g',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(label,
                  style:
                      const TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ),
      );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.volt),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                maxLines: 2,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
