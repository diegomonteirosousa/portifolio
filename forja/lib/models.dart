// Modelos de dados do app. Tudo é salvo localmente em JSON.

enum Sex { male, female }

enum Activity { sedentary, light, moderate, intense, athlete }

enum Goal { lose, gain, maintain, performance }

extension SexLabel on Sex {
  String get label => this == Sex.male ? 'Masculino' : 'Feminino';
}

extension ActivityLabel on Activity {
  String get label => const {
        Activity.sedentary: 'Sedentário',
        Activity.light: 'Leve',
        Activity.moderate: 'Moderado',
        Activity.intense: 'Intenso',
        Activity.athlete: 'Atleta',
      }[this]!;

  String get description => const {
        Activity.sedentary: 'Pouco ou nenhum exercício',
        Activity.light: '1 a 3 treinos por semana',
        Activity.moderate: '3 a 5 treinos por semana',
        Activity.intense: '6 a 7 treinos por semana',
        Activity.athlete: '2 treinos por dia',
      }[this]!;

  double get factor => const {
        Activity.sedentary: 1.2,
        Activity.light: 1.375,
        Activity.moderate: 1.55,
        Activity.intense: 1.725,
        Activity.athlete: 1.9,
      }[this]!;
}

extension GoalLabel on Goal {
  String get label => const {
        Goal.lose: 'Perder gordura',
        Goal.gain: 'Ganhar massa',
        Goal.maintain: 'Manter o peso',
        Goal.performance: 'Performance',
      }[this]!;

  String get emoji => const {
        Goal.lose: '🔥',
        Goal.gain: '💪',
        Goal.maintain: '⚖️',
        Goal.performance: '⚡',
      }[this]!;
}

class Profile {
  String name;
  double weight; // kg
  double height; // cm
  int age;
  Sex sex;
  Activity activity;
  Goal goal;
  double? targetWeight;
  double startWeight;
  DateTime? deadline;

  Profile({
    this.name = '',
    this.weight = 75,
    this.height = 170,
    this.age = 28,
    this.sex = Sex.male,
    this.activity = Activity.moderate,
    this.goal = Goal.maintain,
    this.targetWeight,
    double? startWeight,
    this.deadline,
  }) : startWeight = startWeight ?? weight;

  Map<String, dynamic> toJson() => {
        'name': name,
        'weight': weight,
        'height': height,
        'age': age,
        'sex': sex.index,
        'activity': activity.index,
        'goal': goal.index,
        'targetWeight': targetWeight,
        'startWeight': startWeight,
        'deadline': deadline?.toIso8601String(),
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        name: j['name'] as String? ?? '',
        weight: (j['weight'] as num?)?.toDouble() ?? 75,
        height: (j['height'] as num?)?.toDouble() ?? 170,
        age: (j['age'] as num?)?.toInt() ?? 28,
        sex: Sex.values[(j['sex'] as num?)?.toInt() ?? 0],
        activity: Activity.values[(j['activity'] as num?)?.toInt() ?? 2],
        goal: Goal.values[(j['goal'] as num?)?.toInt() ?? 2],
        targetWeight: (j['targetWeight'] as num?)?.toDouble(),
        startWeight: (j['startWeight'] as num?)?.toDouble(),
        deadline: j['deadline'] == null
            ? null
            : DateTime.tryParse(j['deadline'] as String),
      );
}

/// Exercício planejado dentro de um treino.
class PlannedExercise {
  String exerciseId;
  int sets;
  int reps;
  double weight; // kg (0 = peso do corpo)
  int restSec;

  PlannedExercise({
    required this.exerciseId,
    this.sets = 3,
    this.reps = 10,
    this.weight = 0,
    this.restSec = 90,
  });

  PlannedExercise copy() => PlannedExercise(
        exerciseId: exerciseId,
        sets: sets,
        reps: reps,
        weight: weight,
        restSec: restSec,
      );

  Map<String, dynamic> toJson() => {
        'e': exerciseId,
        's': sets,
        'r': reps,
        'w': weight,
        'rest': restSec,
      };

  factory PlannedExercise.fromJson(Map<String, dynamic> j) => PlannedExercise(
        exerciseId: j['e'] as String,
        sets: (j['s'] as num).toInt(),
        reps: (j['r'] as num).toInt(),
        weight: (j['w'] as num).toDouble(),
        restSec: (j['rest'] as num).toInt(),
      );
}

/// Um treino montado pelo usuário (ou copiado de uma rotina).
class WorkoutTemplate {
  String id;
  String name;
  String focus;
  List<PlannedExercise> exercises;
  DateTime? lastUsed;

  WorkoutTemplate({
    required this.id,
    required this.name,
    this.focus = '',
    required this.exercises,
    this.lastUsed,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'focus': focus,
        'ex': exercises.map((e) => e.toJson()).toList(),
        'lastUsed': lastUsed?.toIso8601String(),
      };

  factory WorkoutTemplate.fromJson(Map<String, dynamic> j) => WorkoutTemplate(
        id: j['id'] as String,
        name: j['name'] as String,
        focus: j['focus'] as String? ?? '',
        exercises: (j['ex'] as List)
            .map((e) => PlannedExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
        lastUsed: j['lastUsed'] == null
            ? null
            : DateTime.tryParse(j['lastUsed'] as String),
      );
}

class LoggedSet {
  int reps;
  double weight;
  LoggedSet(this.reps, this.weight);

  Map<String, dynamic> toJson() => {'r': reps, 'w': weight};
  factory LoggedSet.fromJson(Map<String, dynamic> j) =>
      LoggedSet((j['r'] as num).toInt(), (j['w'] as num).toDouble());
}

class LoggedExercise {
  String exerciseId;
  List<LoggedSet> sets;
  LoggedExercise(this.exerciseId, this.sets);

  Map<String, dynamic> toJson() => {
        'e': exerciseId,
        'sets': sets.map((s) => s.toJson()).toList(),
      };
  factory LoggedExercise.fromJson(Map<String, dynamic> j) => LoggedExercise(
        j['e'] as String,
        (j['sets'] as List)
            .map((s) => LoggedSet.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

/// Registro de um treino de musculação concluído.
class WorkoutLog {
  String id;
  String name;
  DateTime start;
  int durationSec;
  List<LoggedExercise> exercises;

  WorkoutLog({
    required this.id,
    required this.name,
    required this.start,
    required this.durationSec,
    required this.exercises,
  });

  double get volume => exercises.fold(
      0.0,
      (sum, e) =>
          sum + e.sets.fold(0.0, (s, set) => s + set.reps * set.weight));

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'start': start.toIso8601String(),
        'dur': durationSec,
        'ex': exercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutLog.fromJson(Map<String, dynamic> j) => WorkoutLog(
        id: j['id'] as String,
        name: j['name'] as String,
        start: DateTime.parse(j['start'] as String),
        durationSec: (j['dur'] as num).toInt(),
        exercises: (j['ex'] as List)
            .map((e) => LoggedExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Registro de uma corrida (GPS ou esteira).
class RunLog {
  String id;
  DateTime start;
  int durationSec;
  double distanceM;
  List<int> splits; // segundos de cada km completo
  bool treadmill;
  List<List<double>> route; // [lat, lng] simplificado

  RunLog({
    required this.id,
    required this.start,
    required this.durationSec,
    required this.distanceM,
    required this.splits,
    required this.treadmill,
    required this.route,
  });

  /// Ritmo médio em segundos por km.
  double? get paceSecPerKm =>
      distanceM < 50 ? null : durationSec / (distanceM / 1000);

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': start.toIso8601String(),
        'dur': durationSec,
        'dist': distanceM,
        'splits': splits,
        'tm': treadmill,
        'route': route,
      };

  factory RunLog.fromJson(Map<String, dynamic> j) => RunLog(
        id: j['id'] as String,
        start: DateTime.parse(j['start'] as String),
        durationSec: (j['dur'] as num).toInt(),
        distanceM: (j['dist'] as num).toDouble(),
        splits: (j['splits'] as List).map((e) => (e as num).toInt()).toList(),
        treadmill: j['tm'] as bool? ?? false,
        route: (j['route'] as List? ?? [])
            .map((p) => (p as List).map((v) => (v as num).toDouble()).toList())
            .toList(),
      );
}

enum Meal { breakfast, lunch, snack, dinner }

extension MealLabel on Meal {
  String get label => const {
        Meal.breakfast: 'Café da manhã',
        Meal.lunch: 'Almoço',
        Meal.snack: 'Lanches',
        Meal.dinner: 'Jantar',
      }[this]!;

  String get emoji => const {
        Meal.breakfast: '☕',
        Meal.lunch: '🍛',
        Meal.snack: '🍎',
        Meal.dinner: '🌙',
      }[this]!;

  /// Refeição sugerida pelo horário.
  static Meal byHour(int h) {
    if (h < 10) return Meal.breakfast;
    if (h < 15) return Meal.lunch;
    if (h < 19) return Meal.snack;
    return Meal.dinner;
  }
}

/// Alimento registrado no diário.
class FoodEntry {
  String id;
  DateTime date;
  Meal meal;
  String name;
  double servings;
  double kcal; // total (já multiplicado pelas porções)
  double protein;
  double carbs;
  double fat;

  FoodEntry({
    required this.id,
    required this.date,
    required this.meal,
    required this.name,
    this.servings = 1,
    required this.kcal,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'd': date.toIso8601String(),
        'm': meal.index,
        'n': name,
        's': servings,
        'k': kcal,
        'p': protein,
        'c': carbs,
        'f': fat,
      };

  factory FoodEntry.fromJson(Map<String, dynamic> j) => FoodEntry(
        id: j['id'] as String,
        date: DateTime.parse(j['d'] as String),
        meal: Meal.values[(j['m'] as num).toInt()],
        name: j['n'] as String,
        servings: (j['s'] as num?)?.toDouble() ?? 1,
        kcal: (j['k'] as num).toDouble(),
        protein: (j['p'] as num?)?.toDouble() ?? 0,
        carbs: (j['c'] as num?)?.toDouble() ?? 0,
        fat: (j['f'] as num?)?.toDouble() ?? 0,
      );
}

class WeightEntry {
  DateTime date;
  double kg;
  WeightEntry(this.date, this.kg);

  Map<String, dynamic> toJson() => {'d': date.toIso8601String(), 'kg': kg};
  factory WeightEntry.fromJson(Map<String, dynamic> j) =>
      WeightEntry(DateTime.parse(j['d'] as String), (j['kg'] as num).toDouble());
}

class ReminderSettings {
  bool workoutOn;
  int workoutHour;
  int workoutMinute;
  Set<int> workoutDays; // 1 = segunda ... 7 = domingo
  bool waterOn;
  int waterEveryHours;
  int waterFrom;
  int waterTo;

  ReminderSettings({
    this.workoutOn = false,
    this.workoutHour = 18,
    this.workoutMinute = 0,
    Set<int>? workoutDays,
    this.waterOn = false,
    this.waterEveryHours = 2,
    this.waterFrom = 8,
    this.waterTo = 22,
  }) : workoutDays = workoutDays ?? {1, 2, 3, 4, 5};

  Map<String, dynamic> toJson() => {
        'wOn': workoutOn,
        'wH': workoutHour,
        'wM': workoutMinute,
        'wD': workoutDays.toList(),
        'aOn': waterOn,
        'aE': waterEveryHours,
        'aF': waterFrom,
        'aT': waterTo,
      };

  factory ReminderSettings.fromJson(Map<String, dynamic> j) => ReminderSettings(
        workoutOn: j['wOn'] as bool? ?? false,
        workoutHour: (j['wH'] as num?)?.toInt() ?? 18,
        workoutMinute: (j['wM'] as num?)?.toInt() ?? 0,
        workoutDays: ((j['wD'] as List?) ?? [1, 2, 3, 4, 5])
            .map((e) => (e as num).toInt())
            .toSet(),
        waterOn: j['aOn'] as bool? ?? false,
        waterEveryHours: (j['aE'] as num?)?.toInt() ?? 2,
        waterFrom: (j['aF'] as num?)?.toInt() ?? 8,
        waterTo: (j['aT'] as num?)?.toInt() ?? 22,
      );
}
