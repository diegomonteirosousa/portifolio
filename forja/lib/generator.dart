import 'models.dart';

enum Place { gym, home }

enum Level { beginner, intermediate, advanced }

extension PlaceLabel on Place {
  String get label => this == Place.gym ? 'Academia' : 'Em casa';
  String get description => this == Place.gym
      ? 'Máquinas, barras e halteres'
      : 'Peso do corpo e halteres';
}

extension LevelLabel on Level {
  String get label => const {
        Level.beginner: 'Iniciante',
        Level.intermediate: 'Intermediário',
        Level.advanced: 'Avançado',
      }[this]!;

  String get description => const {
        Level.beginner: 'Menos de 6 meses treinando',
        Level.intermediate: '6 meses a 2 anos',
        Level.advanced: 'Mais de 2 anos, com constância',
      }[this]!;
}

/// Grupos de movimento e os exercícios possíveis em cada local.
const _pools = <Place, Map<String, List<String>>>{
  Place.gym: {
    'peito': ['supino_reto', 'supino_inclinado_halter', 'crucifixo', 'crossover'],
    'costas': ['puxada_frente', 'remada_curvada', 'remada_baixa', 'remada_unilateral', 'barra_fixa'],
    'ombros': ['desenvolvimento', 'elevacao_lateral', 'face_pull', 'desenvolvimento_militar'],
    'quadriceps': ['agachamento', 'leg_press', 'cadeira_extensora', 'afundo', 'agachamento_bulgaro'],
    'posterior': ['stiff', 'mesa_flexora', 'elevacao_pelvica', 'abducao'],
    'panturrilha': ['panturrilha'],
    'biceps': ['rosca_direta', 'rosca_martelo', 'rosca_alternada'],
    'triceps': ['triceps_polia', 'triceps_frances', 'supino_fechado'],
    'core': ['prancha', 'abdominal_infra', 'elevacao_pernas', 'roda_abdominal'],
    'cardio': ['burpee', 'kettlebell_swing', 'mountain_climber'],
  },
  Place.home: {
    'peito': ['flexao', 'crucifixo', 'paralelas'],
    'costas': ['remada_unilateral', 'barra_fixa'],
    'ombros': ['desenvolvimento', 'elevacao_lateral'],
    'quadriceps': ['agachamento_bulgaro', 'afundo', 'agachamento_salto'],
    'posterior': ['elevacao_pelvica', 'stiff'],
    'panturrilha': ['panturrilha'],
    'biceps': ['rosca_alternada', 'rosca_martelo'],
    'triceps': ['triceps_frances', 'paralelas'],
    'core': ['prancha', 'abdominal_crunch', 'russian_twist', 'abdominal_infra'],
    'cardio': ['burpee', 'mountain_climber', 'pular_corda'],
  },
};

class _Day {
  final String name;
  final String focus;
  final List<String> slots;
  const _Day(this.name, this.focus, this.slots);
}

const _fullA = _Day('Corpo inteiro', 'Pernas, peito, costas e ombros',
    ['quadriceps', 'peito', 'costas', 'ombros', 'posterior', 'biceps', 'core']);
const _fullB = _Day('Corpo inteiro', 'Posterior, costas, peito e tríceps',
    ['posterior', 'costas', 'peito', 'quadriceps', 'triceps', 'ombros', 'core']);
const _fullC = _Day('Corpo inteiro', 'Pernas, costas, peito e ombros',
    ['quadriceps', 'costas', 'peito', 'posterior', 'ombros', 'triceps', 'core']);
const _upper = _Day('Superior', 'Peito, costas, ombros e braços',
    ['peito', 'costas', 'ombros', 'peito', 'costas', 'biceps', 'triceps']);
const _lower = _Day('Inferior', 'Pernas, glúteos e core',
    ['quadriceps', 'posterior', 'quadriceps', 'posterior', 'panturrilha', 'core']);
const _push = _Day('Empurrar', 'Peito, ombros e tríceps',
    ['peito', 'peito', 'ombros', 'ombros', 'triceps', 'triceps']);
const _pull = _Day('Puxar', 'Costas, bíceps e core',
    ['costas', 'costas', 'costas', 'biceps', 'biceps', 'core']);
const _legs = _Day('Pernas', 'Quadríceps, posterior e glúteos',
    ['quadriceps', 'posterior', 'quadriceps', 'posterior', 'panturrilha', 'core']);

List<_Day> _split(int days) {
  switch (days) {
    case <= 2:
      return [_fullA, _fullB];
    case 3:
      return [_fullA, _fullB, _fullC];
    case 4:
      return [_upper, _lower, _upper, _lower];
    case 5:
      return [_push, _pull, _legs, _upper, _lower];
    default:
      return [_push, _pull, _legs, _push, _pull, _legs];
  }
}

/// Monta um plano de treino conforme objetivo, dias, local e nível.
List<WorkoutTemplate> generatePlan({
  required Goal goal,
  required int days,
  required Place place,
  required Level level,
  required String Function() newId,
}) {
  final pool = _pools[place]!;
  final split = _split(days);
  final maxExercises = switch (level) {
    Level.beginner => 5,
    Level.intermediate => 6,
    Level.advanced => 7,
  };

  var (sets, reps, rest) = switch (goal) {
    Goal.gain => (4, 10, 90),
    Goal.lose => (3, 14, 50),
    Goal.maintain => (3, 12, 75),
    Goal.performance => (4, 6, 120),
  };
  if (level == Level.beginner && sets > 3) sets = 3;
  if (level == Level.advanced && (goal == Goal.gain || goal == Goal.performance)) {
    sets += 1;
  }
  if (level == Level.beginner) rest += 15;

  const letters = 'ABCDEF';
  final usedCount = <String, int>{}; // rodízio de variações entre os dias
  final plan = <WorkoutTemplate>[];

  for (var d = 0; d < split.length; d++) {
    final day = split[d];
    final chosen = <String>[];
    for (final slot in day.slots) {
      if (chosen.length >= maxExercises) break;
      final options = pool[slot] ?? const <String>[];
      if (options.isEmpty) continue;
      final start = usedCount[slot] ?? 0;
      for (var k = 0; k < options.length; k++) {
        final id = options[(start + k) % options.length];
        if (!chosen.contains(id)) {
          chosen.add(id);
          usedCount[slot] = start + k + 1;
          break;
        }
      }
    }
    // Para emagrecer, um finalizador metabólico no fim de cada treino.
    if (goal == Goal.lose) {
      final cardio = pool['cardio']!;
      chosen.add(cardio[d % cardio.length]);
    }

    plan.add(WorkoutTemplate(
      id: newId(),
      name: 'Treino ${letters[d]} · ${day.name}',
      focus: day.focus,
      exercises: [
        for (final id in chosen)
          _planned(id, sets, reps, rest),
      ],
    ));
  }
  return plan;
}

PlannedExercise _planned(String id, int sets, int reps, int rest) {
  // Ajustes para exercícios medidos em tempo ou isométricos.
  if (id == 'prancha') {
    return PlannedExercise(exerciseId: id, sets: 3, reps: 40, restSec: 45);
  }
  if (id == 'pular_corda') {
    return PlannedExercise(exerciseId: id, sets: 3, reps: 60, restSec: 45);
  }
  if (const ['burpee', 'mountain_climber', 'kettlebell_swing']
      .contains(id)) {
    return PlannedExercise(exerciseId: id, sets: 3, reps: 15, restSec: 40);
  }
  if (const ['panturrilha', 'abdominal_infra', 'abdominal_crunch', 'russian_twist',
      'elevacao_pernas', 'roda_abdominal'].contains(id)) {
    return PlannedExercise(exerciseId: id, sets: 3, reps: 15, restSec: 45);
  }
  return PlannedExercise(exerciseId: id, sets: sets, reps: reps, restSec: rest);
}
