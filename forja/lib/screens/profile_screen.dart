import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_info.dart';
import '../calc.dart';
import '../models.dart';
import '../services/notifications.dart';
import '../state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'legal_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = s.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.volt,
                  child: Text(
                    p.name.isEmpty ? '💪' : p.name[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name.isEmpty ? 'Atleta' : p.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const Row(
                        children: [
                          Icon(Icons.lock_outline_rounded,
                              size: 14, color: AppColors.muted),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text('Dados salvos só neste aparelho',
                                style: TextStyle(
                                    color: AppColors.muted, fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Editar nome',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editName(context, s),
                ),
              ],
            ),
          ),
          const SectionTitle('Seus números'),
          _ResultsGrid(profile: p),
          const SectionTitle('Objetivo'),
          _GoalSection(state: s),
          const SectionTitle('Dados do corpo'),
          _BodySection(state: s),
          const SectionTitle('Lembretes'),
          _RemindersSection(state: s),
          const SectionTitle('Backup sem login'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.copy_all_rounded,
                      color: AppColors.volt),
                  title: const Text('Copiar backup'),
                  subtitle: const Text(
                      'Guarde o texto para levar seus dados a outro celular'),
                  onTap: () => _copyBackup(context, s),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore_rounded,
                      color: AppColors.volt),
                  title: const Text('Restaurar backup'),
                  subtitle: const Text('Cole o texto copiado anteriormente'),
                  onTap: () => _restoreBackup(context, s),
                ),
              ],
            ),
          ),
          const SectionTitle('Privacidade e sobre'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined,
                      color: AppColors.volt),
                  title: const Text('Política de privacidade'),
                  subtitle: const Text('Seus dados ficam só neste celular'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen())),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.mail_outline_rounded,
                      color: AppColors.volt),
                  title: const Text('Fale com a gente'),
                  subtitle: const Text(AppInfo.supportEmail),
                  onTap: () {
                    Clipboard.setData(
                        const ClipboardData(text: AppInfo.supportEmail));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('E-mail de suporte copiado')));
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded,
                      color: AppColors.muted),
                  title: const Text('${AppInfo.name} ${AppInfo.version}'),
                  subtitle: const Text('Licenças de código aberto'),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: AppInfo.name,
                    applicationVersion: AppInfo.version,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.danger),
                  title: const Text('Apagar todos os meus dados'),
                  subtitle:
                      const Text('Treinos, corridas, medidas e configurações'),
                  onTap: () => _confirmErase(context, s),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Os cálculos são estimativas (Mifflin-St Jeor para metabolismo, 35 ml/kg para água) e não substituem a orientação de médico ou nutricionista. Gestantes, menores de 18 anos e pessoas com doenças renais ou cardíacas devem ter acompanhamento profissional.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context, AppState s) async {
    final ctrl = TextEditingController(text: s.profile.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Como quer ser chamado?'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Salvar')),
        ],
      ),
    );
    if (name != null) s.updateProfile((p) => p.name = name.trim());
  }

  Future<void> _confirmErase(BuildContext context, AppState s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar tudo?'),
        content: const Text(
            'Todos os seus treinos, corridas e medidas serão apagados deste aparelho. Isso não pode ser desfeito.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await s.eraseAll();
    if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _copyBackup(BuildContext context, AppState s) async {
    await Clipboard.setData(ClipboardData(text: s.exportBackup()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      duration: Duration(seconds: 5),
      content: Text(
          'Backup copiado! Cole num lugar seguro (e-mail, WhatsApp para você mesmo, notas).'),
    ));
  }

  Future<void> _restoreBackup(BuildContext context, AppState s) async {
    final ctrl = TextEditingController();
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    if (clip?.text != null && clip!.text!.trim().startsWith('{')) {
      ctrl.text = clip.text!;
    }
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Cole aqui o texto do backup. Os dados atuais deste aparelho serão substituídos.',
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              maxLines: 5,
              minLines: 3,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(hintText: '{ ... }'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restaurar')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final success = s.importBackup(ctrl.text);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? 'Backup restaurado com sucesso ✅'
            : 'Esse texto não é um backup válido do Forja.')));
  }
}

class _ResultsGrid extends StatelessWidget {
  final Profile profile;
  const _ResultsGrid({required this.profile});

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final bmi = Calc.bmi(p);
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            StatTile(
              icon: Icons.water_drop_rounded,
              color: AppColors.water,
              label: 'Água por dia (35 ml/kg)',
              value: fmtNum(Calc.waterMl(p.weight) / 1000),
              unit: 'L',
            ),
            StatTile(
              icon: Icons.bedtime_outlined,
              color: AppColors.fire,
              label: 'Metabolismo basal',
              value: fmtInt(Calc.bmr(p)),
              unit: 'kcal',
            ),
            StatTile(
              icon: Icons.bolt_rounded,
              label: 'Gasto total diário',
              value: fmtInt(Calc.tdee(p)),
              unit: 'kcal',
            ),
            StatTile(
              icon: Icons.restaurant_rounded,
              label: 'Meta: ${p.goal.label.toLowerCase()}',
              value: fmtInt(Calc.targetKcal(p)),
              unit: 'kcal',
            ),
          ],
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: _kv('IMC', fmtNum(bmi), Calc.bmiLabel(bmi)),
              ),
              Expanded(
                child: _kv('Proteína', '${Calc.proteinG(p).round()} g', 'por dia'),
              ),
              Expanded(
                child: _kv('Carbo', '${Calc.carbsG(p).round()} g', 'por dia'),
              ),
              Expanded(
                child: _kv('Gordura', '${Calc.fatG(p).round()} g', 'por dia'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Em dias de treino, a meta de água sobe 500 ml por hora de atividade.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _kv(String k, String v, String sub) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          Text(v,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(sub,
              style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        ],
      );
}

class _GoalSection extends StatelessWidget {
  final AppState state;
  const _GoalSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final p = state.profile;
    final hasTarget = p.goal == Goal.lose || p.goal == Goal.gain;
    final weeks = Calc.weeksToTarget(p);
    final aggressive = Calc.deadlineTooAggressive(p);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in Goal.values)
              _pill('${g.emoji} ${g.label}', p.goal == g, () {
                state.updateProfile((x) {
                  x.goal = g;
                  if ((g == Goal.lose || g == Goal.gain) &&
                      x.targetWeight == null) {
                    x.targetWeight = g == Goal.lose ? x.weight - 5 : x.weight + 4;
                    x.startWeight = x.weight;
                  }
                });
              }),
          ],
        ),
        const SizedBox(height: 14),
        const Text('Nível de atividade',
            style: TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in Activity.values)
              _pill(a.label, p.activity == a,
                  () => state.updateProfile((x) => x.activity = a)),
          ],
        ),
        const SizedBox(height: 4),
        Text(p.activity.description,
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        if (hasTarget) ...[
          const SizedBox(height: 16),
          NumberStepper(
            label: 'Peso meta',
            value: p.targetWeight ?? p.weight,
            step: 0.5,
            min: 30,
            max: 300,
            decimals: 1,
            unit: 'kg',
            onChanged: (v) => state.updateProfile((x) => x.targetWeight = v),
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.event_rounded),
              title: Text(p.deadline == null
                  ? 'Definir prazo (opcional)'
                  : 'Prazo: ${fmtDate(p.deadline!)} de ${p.deadline!.year}'),
              trailing: p.deadline == null
                  ? const Icon(Icons.chevron_right_rounded)
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () =>
                          state.updateProfile((x) => x.deadline = null),
                    ),
              onTap: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  initialDate:
                      p.deadline ?? now.add(Duration(days: 7 * (weeks ?? 12))),
                  firstDate: now.add(const Duration(days: 7)),
                  lastDate: now.add(const Duration(days: 730)),
                );
                if (d != null) state.updateProfile((x) => x.deadline = d);
              },
            ),
          ),
          const SizedBox(height: 10),
          _GoalProgress(profile: p, weeks: weeks),
          if (aggressive) ...[
            const SizedBox(height: 10),
            AppCard(
              color: AppColors.fire.withValues(alpha: 0.12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.fire),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Esse prazo exige mais de 1% do peso por semana, o que é agressivo. '
                      'Uma data realista seria por volta de ${weeks == null ? '-' : fmtDate(DateTime.now().add(Duration(days: weeks * 7)))}.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

Widget _pill(String label, bool selected, VoidCallback onTap) => ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: selected ? Colors.black : AppColors.text,
        fontWeight: FontWeight.w700,
      ),
      onSelected: (_) => onTap(),
    );

class _GoalProgress extends StatelessWidget {
  final Profile profile;
  final int? weeks;
  const _GoalProgress({required this.profile, required this.weeks});

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final target = p.targetWeight;
    if (target == null) return const SizedBox.shrink();
    final progress = Calc.goalProgress(p);
    final left = (p.weight - target).abs();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Progresso até a meta',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('${(progress * 100).round()}%',
                  style: const TextStyle(
                      color: AppColors.volt, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.cardHigh,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Início ${fmtNum(p.startWeight)} kg',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              const Spacer(),
              Text('Agora ${fmtNum(p.weight)} kg',
                  style: const TextStyle(fontSize: 12)),
              const Spacer(),
              Text('Meta ${fmtNum(target)} kg',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            left < 0.1
                ? 'Meta alcançada! 🎉 Que tal definir a próxima?'
                : 'Faltam ${fmtNum(left)} kg. No ritmo saudável (cerca de ${fmtNum(Calc.healthyWeeklyKg(p.weight), decimals: 2)} kg por semana), '
                    'você chega lá em ~$weeks semanas, por volta de ${fmtDate(DateTime.now().add(Duration(days: (weeks ?? 0) * 7)))}.',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _BodySection extends StatelessWidget {
  final AppState state;
  const _BodySection({required this.state});

  @override
  Widget build(BuildContext context) {
    final p = state.profile;
    return Column(
      children: [
        Row(
          children: [
            for (final sx in Sex.values)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _pill(sx.label, p.sex == sx,
                    () => state.updateProfile((x) => x.sex = sx)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        NumberStepper(
          label: 'Peso atual',
          value: p.weight,
          step: 0.5,
          min: 30,
          max: 300,
          decimals: 1,
          unit: 'kg',
          onChanged: (v) => state.updateProfile((x) => x.weight = v),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: NumberStepper(
                label: 'Altura',
                value: p.height,
                min: 120,
                max: 230,
                unit: 'cm',
                onChanged: (v) => state.updateProfile((x) => x.height = v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: NumberStepper(
                label: 'Idade',
                value: p.age.toDouble(),
                min: 13,
                max: 100,
                onChanged: (v) =>
                    state.updateProfile((x) => x.age = v.round()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RemindersSection extends StatelessWidget {
  final AppState state;
  const _RemindersSection({required this.state});

  Future<void> _toggle(BuildContext context, bool on,
      void Function(bool) apply) async {
    if (on) {
      await NotificationService.instance.requestPermission();
    }
    await state.updateReminders((r) => apply(on));
  }

  @override
  Widget build(BuildContext context) {
    final r = state.reminders;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.fitness_center_rounded),
            title: const Text('Lembrete de treino'),
            subtitle: Text(
                '${two(r.workoutHour)}:${two(r.workoutMinute)} · ${r.workoutDays.length} dias por semana'),
            value: r.workoutOn,
            onChanged: (v) =>
                _toggle(context, v, (on) => state.reminders.workoutOn = on),
          ),
          if (r.workoutOn) ...[
            ListTile(
              leading: const Icon(Icons.schedule_rounded),
              title: const Text('Horário'),
              trailing: Text('${two(r.workoutHour)}:${two(r.workoutMinute)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime:
                      TimeOfDay(hour: r.workoutHour, minute: r.workoutMinute),
                );
                if (t != null) {
                  await state.updateReminders((x) {
                    x.workoutHour = t.hour;
                    x.workoutMinute = t.minute;
                  });
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final day = i + 1;
                  final on = r.workoutDays.contains(day);
                  return InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => state.updateReminders((x) {
                      if (on && x.workoutDays.length > 1) {
                        x.workoutDays.remove(day);
                      } else {
                        x.workoutDays.add(day);
                      }
                    }),
                    child: Tooltip(
                      message: weekdayNames[i],
                      child: CircleAvatar(
                        radius: 19,
                        backgroundColor:
                            on ? AppColors.volt : AppColors.cardHigh,
                        child: Text(weekdayShort[i],
                            style: TextStyle(
                                color: on ? Colors.black : AppColors.muted,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.water_drop_outlined),
            title: const Text('Lembrete de água'),
            subtitle: Text(
                'A cada ${r.waterEveryHours}h, das ${r.waterFrom}h às ${r.waterTo}h'),
            value: r.waterOn,
            onChanged: (v) =>
                _toggle(context, v, (on) => state.reminders.waterOn = on),
          ),
          if (r.waterOn)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final h in const [1, 2, 3])
                    _pill('A cada ${h}h', r.waterEveryHours == h,
                        () => state.updateReminders((x) => x.waterEveryHours = h)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
