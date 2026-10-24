import 'dart:math' as math;

import 'models.dart';

/// Duração estimada de um treino, em minutos.
int estimateMinutes(List<PlannedExercise> exercises) {
  var sec = 0;
  for (final e in exercises) {
    sec += e.sets * (math.min(e.reps * 3, 90) + e.restSec);
  }
  return math.max(10, (sec / 60).round());
}

/// Cálculos de saúde. São estimativas e não substituem um profissional.
class Calc {
  /// Água diária: 35 ml por kg + 500 ml por hora de treino.
  static int waterMl(double weightKg, {double trainingHours = 0}) =>
      (35 * weightKg + 500 * trainingHours).round();

  /// Taxa de metabolismo basal (Mifflin-St Jeor), em kcal/dia.
  static double bmr(Profile p) {
    final base = 10 * p.weight + 6.25 * p.height - 5 * p.age;
    return p.sex == Sex.male ? base + 5 : base - 161;
  }

  /// Gasto energético total diário.
  static double tdee(Profile p) => bmr(p) * p.activity.factor;

  /// Meta de calorias conforme o objetivo. Nunca abaixo da TMB.
  static double targetKcal(Profile p) {
    final t = tdee(p);
    final adjusted = switch (p.goal) {
      Goal.lose => t * 0.82,
      Goal.gain => t * 1.10,
      Goal.maintain => t,
      Goal.performance => t * 1.05,
    };
    return math.max(adjusted, bmr(p));
  }

  /// Proteína diária sugerida (g).
  static double proteinG(Profile p) {
    final perKg = switch (p.goal) {
      Goal.lose => 2.0,
      Goal.gain => 2.0,
      Goal.maintain => 1.6,
      Goal.performance => 1.8,
    };
    return p.weight * perKg;
  }

  static double fatG(Profile p) => p.weight * 0.9;

  static double carbsG(Profile p) {
    final kcalLeft = targetKcal(p) - proteinG(p) * 4 - fatG(p) * 9;
    return math.max(0.0, kcalLeft / 4);
  }

  static double bmi(Profile p) {
    final m = p.height / 100;
    return p.weight / (m * m);
  }

  static String bmiLabel(double bmi) {
    if (bmi < 18.5) return 'Abaixo do peso';
    if (bmi < 25) return 'Peso normal';
    if (bmi < 30) return 'Sobrepeso';
    return 'Obesidade';
  }

  /// Ritmo saudável: 0,75% do peso por semana.
  static double healthyWeeklyKg(double weight) => weight * 0.0075;

  /// Semanas estimadas até a meta de peso.
  static int? weeksToTarget(Profile p) {
    final t = p.targetWeight;
    if (t == null) return null;
    final diff = (p.weight - t).abs();
    if (diff < 0.1) return 0;
    return (diff / healthyWeeklyKg(p.weight)).ceil();
  }

  /// Verdadeiro se o prazo escolhido exige mais de 1% do peso por semana.
  static bool deadlineTooAggressive(Profile p) {
    final t = p.targetWeight;
    final d = p.deadline;
    if (t == null || d == null) return false;
    final days = d.difference(DateTime.now()).inDays;
    if (days <= 0) return true;
    final perWeek = (p.weight - t).abs() / (days / 7);
    return perWeek > p.weight * 0.01;
  }

  /// Progresso (0 a 1) do peso inicial até a meta.
  static double goalProgress(Profile p) {
    final t = p.targetWeight;
    if (t == null) return 0;
    final total = (p.startWeight - t).abs();
    if (total < 0.1) return 1;
    final done = (p.startWeight - p.weight) * (t < p.startWeight ? 1 : -1);
    return (done / total).clamp(0.0, 1.0);
  }

  /// 1RM estimado (Epley).
  static double oneRm(double weight, int reps) =>
      reps <= 1 ? weight : weight * (1 + reps / 30);

  /// Anilhas por lado para uma barra (padrão 20 kg).
  static List<double> platesPerSide(double total, {double bar = 20}) {
    const plates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];
    var remaining = (total - bar) / 2;
    final out = <double>[];
    if (remaining <= 0) return out;
    for (final p in plates) {
      while (remaining >= p - 0.001) {
        out.add(p);
        remaining -= p;
      }
    }
    return out;
  }
}
