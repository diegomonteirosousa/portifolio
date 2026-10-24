import 'package:flutter_test/flutter_test.dart';
import 'package:forja_fit/calc.dart';
import 'package:forja_fit/models.dart';
import 'package:forja_fit/utils.dart';

void main() {
  test('água: 35 ml por kg + 500 ml por hora de treino', () {
    expect(Calc.waterMl(80), 2800);
    expect(Calc.waterMl(80, trainingHours: 1), 3300);
  });

  test('TMB Mifflin-St Jeor (homem 80 kg, 180 cm, 30 anos)', () {
    final p = Profile(weight: 80, height: 180, age: 30, sex: Sex.male);
    expect(Calc.bmr(p), 1780);
  });

  test('meta de calorias nunca fica abaixo da TMB', () {
    final p = Profile(
        weight: 50,
        height: 160,
        age: 30,
        sex: Sex.female,
        activity: Activity.sedentary,
        goal: Goal.lose);
    expect(Calc.targetKcal(p), greaterThanOrEqualTo(Calc.bmr(p)));
  });

  test('anilhas por lado', () {
    expect(Calc.platesPerSide(100), [25.0, 15.0]);
    expect(Calc.platesPerSide(20), isEmpty);
  });

  test('formatação', () {
    expect(fmtPace(332), '5:32');
    expect(fmtDuration(3725), '1:02:05');
    expect(fmtInt(1234567), '1.234.567');
    expect(fmtNum(2.5), '2,5');
  });
}
