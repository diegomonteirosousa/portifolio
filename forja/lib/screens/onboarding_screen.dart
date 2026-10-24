import 'package:flutter/material.dart';

import '../calc.dart';
import '../models.dart';
import '../services/notifications.dart';
import '../state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'legal_screen.dart';

/// Primeiro acesso: sem cadastro, só perguntas rápidas.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  final _name = TextEditingController();
  final Profile _p = Profile();
  int _step = 0;
  bool _remindWorkout = true;
  bool _remindWater = true;

  static const _steps = 5;

  @override
  void dispose() {
    _page.dispose();
    _name.dispose();
    super.dispose();
  }

  void _go(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    _page.animateToPage(step,
        duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  void _setGoal(Goal g) {
    setState(() {
      _p.goal = g;
      if (g == Goal.lose) {
        _p.targetWeight = (_p.weight - 5).roundToDouble();
      } else if (g == Goal.gain) {
        _p.targetWeight = (_p.weight + 4).roundToDouble();
      } else {
        _p.targetWeight = null;
      }
    });
  }

  Future<void> _finish() async {
    final state = AppScope.read(context);
    _p.name = _name.text.trim();
    state.completeOnboarding(_p);
    if (_remindWorkout || _remindWater) {
      await NotificationService.instance.requestPermission();
      await state.updateReminders((r) {
        r.workoutOn = _remindWorkout;
        r.waterOn = _remindWater;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _step == 0 ? null : () => _go(_step - 1),
                    icon: Icon(Icons.arrow_back_rounded,
                        color: _step == 0 ? Colors.transparent : null),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: (_step + 1) / _steps),
                        duration: const Duration(milliseconds: 300),
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          minHeight: 6,
                          backgroundColor: AppColors.card,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _welcome(),
                  _goal(),
                  _body(),
                  _activity(),
                  _result(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _step < _steps - 1 ? () => _go(_step + 1) : _finish,
                  child: Text(_step == 0
                      ? 'Começar'
                      : _step < _steps - 1
                          ? 'Continuar'
                          : 'Bora treinar 🔥'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pad(List<Widget> children) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        children: children,
      );

  Widget _title(String t, String sub) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1.1)),
            const SizedBox(height: 8),
            Text(sub,
                style: const TextStyle(color: AppColors.muted, fontSize: 15)),
          ],
        ),
      );

  Widget _welcome() => _pad([
        const SizedBox(height: 12),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.volt,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.local_fire_department_rounded,
              color: Colors.black, size: 42),
        ),
        const SizedBox(height: 24),
        const Text('FORJA',
            style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: AppColors.volt)),
        const SizedBox(height: 6),
        const Text('Treino, corrida e nutrição.\nSem cadastro. Sem enrolação.',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, height: 1.25)),
        const SizedBox(height: 28),
        _feature(Icons.lock_outline_rounded,
            'Seus dados ficam só no seu celular. Nada de conta ou senha.'),
        _feature(Icons.fitness_center_rounded,
            'Monte treinos ou siga rotinas temáticas prontas.'),
        _feature(Icons.directions_run_rounded,
            'Cronômetro de corrida com GPS e parciais por km.'),
        _feature(Icons.water_drop_outlined,
            'Meta de água e calorias calculadas para você.'),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen())),
            icon: const Icon(Icons.privacy_tip_outlined, size: 18),
            label: const Text('Como cuidamos dos seus dados'),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Como quer ser chamado? (opcional)',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
      ]);

  Widget _feature(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.volt),
            const SizedBox(width: 14),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
          ],
        ),
      );

  Widget _goal() => _pad([
        _title('Qual é o seu objetivo?',
            'Isso ajusta suas calorias e as sugestões de treino.'),
        for (final g in Goal.values)
          ChoiceCard(
            leading: g.emoji,
            title: g.label,
            subtitle: switch (g) {
              Goal.lose => 'Queimar gordura mantendo os músculos',
              Goal.gain => 'Hipertrofia e força',
              Goal.maintain => 'Saúde e constância',
              Goal.performance => 'Correr mais, render mais',
            },
            selected: _p.goal == g,
            onTap: () => _setGoal(g),
          ),
      ]);

  Widget _body() => _pad([
        _title('Sobre você',
            'Usado para calcular metabolismo, água e calorias. Fica só no aparelho.'),
        Row(
          children: [
            for (final s in Sex.values)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: s == Sex.male ? 8 : 0),
                  child: ChoiceCard(
                    title: s.label,
                    selected: _p.sex == s,
                    onTap: () => setState(() => _p.sex = s),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        NumberStepper(
          label: 'Idade',
          value: _p.age.toDouble(),
          min: 13,
          max: 100,
          unit: 'anos',
          onChanged: (v) => setState(() => _p.age = v.round()),
        ),
        const SizedBox(height: 14),
        NumberStepper(
          label: 'Peso atual',
          value: _p.weight,
          step: 0.5,
          min: 30,
          max: 300,
          decimals: 1,
          unit: 'kg',
          onChanged: (v) => setState(() => _p.weight = v),
        ),
        const SizedBox(height: 14),
        NumberStepper(
          label: 'Altura',
          value: _p.height,
          min: 120,
          max: 230,
          unit: 'cm',
          onChanged: (v) => setState(() => _p.height = v),
        ),
        if (_p.goal == Goal.lose || _p.goal == Goal.gain) ...[
          const SizedBox(height: 14),
          NumberStepper(
            label: 'Peso que quero chegar',
            value: _p.targetWeight ?? _p.weight,
            step: 0.5,
            min: 30,
            max: 300,
            decimals: 1,
            unit: 'kg',
            onChanged: (v) => setState(() => _p.targetWeight = v),
          ),
        ],
      ]);

  Widget _activity() => _pad([
        _title('Quanto você se movimenta?',
            'Conte treinos e trabalho físico. Na dúvida, escolha o menor.'),
        for (final a in Activity.values)
          ChoiceCard(
            title: a.label,
            subtitle: a.description,
            selected: _p.activity == a,
            onTap: () => setState(() => _p.activity = a),
          ),
      ]);

  Widget _result() {
    final weeks = Calc.weeksToTarget(_p);
    return _pad([
      _title(
          _name.text.trim().isEmpty
              ? 'Seu plano está pronto'
              : '${_name.text.trim()}, seu plano está pronto',
          'Valores estimados. Você pode ajustar tudo no Perfil.'),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.45,
        children: [
          StatTile(
            icon: Icons.local_fire_department_rounded,
            label: 'Meta diária',
            value: fmtInt(Calc.targetKcal(_p)),
            unit: 'kcal',
          ),
          StatTile(
            icon: Icons.water_drop_rounded,
            color: AppColors.water,
            label: 'Água por dia',
            value: fmtNum(Calc.waterMl(_p.weight) / 1000),
            unit: 'litros',
          ),
          StatTile(
            icon: Icons.bedtime_outlined,
            color: AppColors.fire,
            label: 'Metabolismo basal',
            value: fmtInt(Calc.bmr(_p)),
            unit: 'kcal',
          ),
          StatTile(
            icon: Icons.egg_alt_outlined,
            color: AppColors.text,
            label: 'Proteína',
            value: fmtInt(Calc.proteinG(_p)),
            unit: 'g',
          ),
        ],
      ),
      if (weeks != null && weeks > 0) ...[
        const SizedBox(height: 12),
        AppCard(
          child: Row(
            children: [
              const Icon(Icons.flag_rounded, color: AppColors.volt),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Chegando a ${fmtNum(_p.targetWeight!)} kg em cerca de $weeks semanas, num ritmo saudável.',
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 18),
      const Text('Lembretes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _remindWorkout,
        onChanged: (v) => setState(() => _remindWorkout = v),
        title: const Text('Lembrar de treinar'),
        subtitle: const Text('Segunda a sexta, às 18h. Dá para mudar depois.'),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _remindWater,
        onChanged: (v) => setState(() => _remindWater = v),
        title: const Text('Lembrar de beber água'),
        subtitle: const Text('A cada 2 horas, das 8h às 22h.'),
      ),
    ]);
  }
}
