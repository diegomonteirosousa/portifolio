// Mantido para o `flutter create` não gerar um teste padrão incompatível.
import 'package:flutter_test/flutter_test.dart';
import 'package:forja_fit/data/exercises.dart';
import 'package:forja_fit/data/foods.dart';
import 'package:forja_fit/data/routines.dart';
import 'package:forja_fit/generator.dart';
import 'package:forja_fit/models.dart';

void main() {
  test('toda rotina usa exercícios que existem na biblioteca', () {
    for (final r in routines) {
      for (final e in r.exercises) {
        expect(exerciseById.containsKey(e.id), isTrue,
            reason: '${r.nickname}: ${e.id}');
      }
    }
  });

  test('gerador cria um treino por dia, só com exercícios válidos', () {
    var n = 0;
    String id() => '${n++}';
    for (final goal in Goal.values) {
      for (final place in Place.values) {
        for (final level in Level.values) {
          for (var days = 2; days <= 6; days++) {
            final plan = generatePlan(
                goal: goal, days: days, place: place, level: level, newId: id);
            expect(plan.length, days);
            for (final t in plan) {
              expect(t.exercises, isNotEmpty);
              final ids = t.exercises.map((e) => e.exerciseId).toList();
              expect(ids.toSet().length, ids.length,
                  reason: 'exercício repetido em ${t.name}');
              for (final e in ids) {
                expect(exerciseById.containsKey(e), isTrue, reason: e);
              }
            }
          }
        }
      }
    }
  });

  test('banco de alimentos tem categorias válidas e calorias coerentes', () {
    for (final f in foodDatabase) {
      expect(foodCategories, contains(f.category), reason: f.name);
      // 4 kcal/g de proteína e carboidrato, 9 kcal/g de gordura (±35%).
      final estimated = f.protein * 4 + f.carbs * 4 + f.fat * 9;
      // Bebidas alcoólicas ficam de fora: o álcool tem 7 kcal/g.
      if (f.kcal > 30 && f.name != 'Cerveja') {
        expect((estimated - f.kcal).abs() / f.kcal, lessThan(0.35),
            reason: f.name);
      }
    }
  });

  test('backup: alimento sobrevive à ida e volta em JSON', () {
    final e = FoodEntry(
        id: '1',
        date: DateTime(2026, 10, 16, 12),
        meal: Meal.lunch,
        name: 'Arroz',
        servings: 2,
        kcal: 256,
        protein: 5,
        carbs: 56,
        fat: 0.4);
    final back = FoodEntry.fromJson(e.toJson());
    expect(back.name, 'Arroz');
    expect(back.meal, Meal.lunch);
    expect(back.kcal, 256);
  });
}
