import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'calc.dart';
import 'data/exercises.dart';
import 'data/routines.dart';
import 'models.dart';
import 'services/notifications.dart';
import 'utils.dart';

class PersonalRecord {
  final String exerciseId;
  final double weight;
  final int reps;
  final DateTime date;
  PersonalRecord(this.exerciseId, this.weight, this.reps, this.date);
}

/// Estado global do app. Tudo fica salvo no aparelho (sem login).
class AppState extends ChangeNotifier {
  static const _key = 'forja_data_v1';
  static const _sessionKey = 'forja_session_v1';

  final SharedPreferences _prefs;

  bool onboarded = false;
  Profile profile = Profile();
  List<WorkoutTemplate> templates = [];
  List<WorkoutLog> workoutLogs = [];
  List<RunLog> runLogs = [];
  List<WeightEntry> weightLog = [];
  Map<String, int> water = {}; // dia -> ml
  ReminderSettings reminders = ReminderSettings();
  List<FoodEntry> foodLog = [];
  int weeklyGoal = 3; // treinos/corridas por semana

  /// Treino em andamento (salvo para retomar se o app fechar).
  Map<String, dynamic>? activeSession;

  AppState._(this._prefs);

  static Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = AppState._(prefs);
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        s._fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Falha ao ler dados salvos: $e');
      }
    }
    final session = prefs.getString(_sessionKey);
    if (session != null) {
      try {
        s.activeSession = jsonDecode(session) as Map<String, dynamic>;
      } catch (_) {
        await prefs.remove(_sessionKey);
      }
    }
    if (s.templates.isEmpty && !s.onboarded) {
      s.templates = starterTemplates(newId);
    }
    return s;
  }

  void _fromJson(Map<String, dynamic> j) {
    onboarded = j['onboarded'] as bool? ?? false;
    if (j['profile'] != null) {
      profile = Profile.fromJson(j['profile'] as Map<String, dynamic>);
    }
    templates = (j['templates'] as List? ?? [])
        .map((e) => WorkoutTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
    workoutLogs = (j['workoutLogs'] as List? ?? [])
        .map((e) => WorkoutLog.fromJson(e as Map<String, dynamic>))
        .toList();
    runLogs = (j['runLogs'] as List? ?? [])
        .map((e) => RunLog.fromJson(e as Map<String, dynamic>))
        .toList();
    weightLog = (j['weightLog'] as List? ?? [])
        .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    water = (j['water'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toInt()));
    if (j['reminders'] != null) {
      reminders =
          ReminderSettings.fromJson(j['reminders'] as Map<String, dynamic>);
    }
    foodLog = (j['foodLog'] as List? ?? [])
        .map((e) => FoodEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    weeklyGoal = (j['weeklyGoal'] as num?)?.toInt() ?? 3;
  }

  Map<String, dynamic> _toJson() => {
        'onboarded': onboarded,
        'profile': profile.toJson(),
        'templates': templates.map((e) => e.toJson()).toList(),
        'workoutLogs': workoutLogs.map((e) => e.toJson()).toList(),
        'runLogs': runLogs.map((e) => e.toJson()).toList(),
        'weightLog': weightLog.map((e) => e.toJson()).toList(),
        'water': water,
        'reminders': reminders.toJson(),
        'foodLog': foodLog.map((e) => e.toJson()).toList(),
        'weeklyGoal': weeklyGoal,
        'version': 2,
      };

  void _commit() {
    notifyListeners();
    _prefs.setString(_key, jsonEncode(_toJson()));
  }

  // ---------- Perfil ----------

  void completeOnboarding(Profile p) {
    profile = p..startWeight = p.weight;
    onboarded = true;
    weightLog = [WeightEntry(DateTime.now(), p.weight)];
    _commit();
  }

  void updateProfile(void Function(Profile p) change) {
    final before = profile.weight;
    change(profile);
    if ((profile.weight - before).abs() > 0.01) {
      _logWeight(profile.weight);
    }
    _commit();
  }

  void addWeight(double kg) {
    profile.weight = kg;
    _logWeight(kg);
    _commit();
  }

  void _logWeight(double kg) {
    final today = dayKey(DateTime.now());
    weightLog.removeWhere((w) => dayKey(w.date) == today);
    weightLog.add(WeightEntry(DateTime.now(), kg));
    weightLog.sort((a, b) => a.date.compareTo(b.date));
  }

  // ---------- Treinos ----------

  void upsertTemplate(WorkoutTemplate t) {
    final i = templates.indexWhere((x) => x.id == t.id);
    if (i >= 0) {
      templates[i] = t;
    } else {
      templates.insert(0, t);
    }
    _commit();
  }

  void deleteTemplate(String id) {
    templates.removeWhere((t) => t.id == id);
    _commit();
  }

  /// Próximo treino sugerido: o usado há mais tempo (rodízio A/B/C).
  WorkoutTemplate? get suggestedTemplate {
    WorkoutTemplate? best;
    var bestDate = DateTime(3000);
    // Em caso de empate, vence o primeiro da lista (ordem A, B, C).
    for (final t in templates) {
      final d = t.lastUsed ?? DateTime(2000);
      if (d.isBefore(bestDate)) {
        best = t;
        bestDate = d;
      }
    }
    return best;
  }

  void addWorkoutLog(WorkoutLog log, {String? templateId}) {
    workoutLogs.insert(0, log);
    if (templateId != null) {
      for (final t in templates) {
        if (t.id == templateId) t.lastUsed = DateTime.now();
      }
    }
    _commit();
  }

  void deleteWorkoutLog(String id) {
    workoutLogs.removeWhere((l) => l.id == id);
    _commit();
  }

  /// Última vez que o exercício foi feito (para mostrar no treino).
  LoggedExercise? lastPerformance(String exerciseId) {
    for (final log in workoutLogs) {
      for (final e in log.exercises) {
        if (e.exerciseId == exerciseId && e.sets.isNotEmpty) return e;
      }
    }
    return null;
  }

  double bestWeight(String exerciseId) {
    var best = 0.0;
    for (final log in workoutLogs) {
      for (final e in log.exercises) {
        if (e.exerciseId != exerciseId) continue;
        for (final s in e.sets) {
          if (s.weight > best) best = s.weight;
        }
      }
    }
    return best;
  }

  List<PersonalRecord> get personalRecords {
    final map = <String, PersonalRecord>{};
    for (final log in workoutLogs.reversed) {
      for (final e in log.exercises) {
        for (final s in e.sets) {
          if (s.weight <= 0) continue;
          final cur = map[e.exerciseId];
          if (cur == null ||
              s.weight > cur.weight ||
              (s.weight == cur.weight && s.reps > cur.reps)) {
            map[e.exerciseId] =
                PersonalRecord(e.exerciseId, s.weight, s.reps, log.start);
          }
        }
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // ---------- Corrida ----------

  void addRun(RunLog run) {
    runLogs.insert(0, run);
    _commit();
  }

  void deleteRun(String id) {
    runLogs.removeWhere((r) => r.id == id);
    _commit();
  }

  double? get bestPace {
    double? best;
    for (final r in runLogs) {
      final p = r.paceSecPerKm;
      if (p != null && r.distanceM >= 1000 && (best == null || p < best)) {
        best = p;
      }
    }
    return best;
  }

  // ---------- Água ----------

  int get waterToday => water[dayKey(DateTime.now())] ?? 0;

  double get trainingHoursToday {
    final today = dayKey(DateTime.now());
    var sec = 0;
    for (final l in workoutLogs) {
      if (dayKey(l.start) == today) sec += l.durationSec;
    }
    for (final r in runLogs) {
      if (dayKey(r.start) == today) sec += r.durationSec;
    }
    return sec / 3600;
  }

  int get waterGoalToday =>
      Calc.waterMl(profile.weight, trainingHours: trainingHoursToday);

  void addWater(int ml) {
    final k = dayKey(DateTime.now());
    water[k] = ((water[k] ?? 0) + ml).clamp(0, 20000).toInt();
    _commit();
  }

  // ---------- Atividade e ofensiva ----------

  Set<String> get activeDays => {
        ...workoutLogs.map((l) => dayKey(l.start)),
        ...runLogs.map((r) => dayKey(r.start)),
      };

  /// Dias seguidos com treino ou corrida (conta até ontem se hoje ainda não treinou).
  int get streak {
    final days = activeDays;
    var d = dateOnly(DateTime.now());
    if (!days.contains(dayKey(d))) {
      d = d.subtract(const Duration(days: 1));
    }
    var count = 0;
    while (days.contains(dayKey(d))) {
      count++;
      d = d.subtract(const Duration(days: 1));
    }
    return count;
  }

  DateTime get weekStart {
    final now = dateOnly(DateTime.now());
    return now.subtract(Duration(days: now.weekday - 1));
  }

  List<WorkoutLog> get workoutsThisWeek =>
      workoutLogs.where((l) => !l.start.isBefore(weekStart)).toList();

  List<RunLog> get runsThisWeek =>
      runLogs.where((r) => !r.start.isBefore(weekStart)).toList();

  /// Séries por grupo muscular na semana.
  Map<String, int> get muscleSetsThisWeek {
    final map = <String, int>{};
    for (final l in workoutsThisWeek) {
      for (final e in l.exercises) {
        final m = exerciseOf(e.exerciseId).muscle;
        map[m] = (map[m] ?? 0) + e.sets.length;
      }
    }
    return map;
  }

  void setWeeklyGoal(int goal) {
    weeklyGoal = goal.clamp(1, 7).toInt();
    _commit();
  }

  int get activitiesThisWeek =>
      {
        ...workoutsThisWeek.map((l) => dayKey(l.start)),
        ...runsThisWeek.map((r) => dayKey(r.start)),
      }.length;

  // ---------- Dieta ----------

  List<FoodEntry> foodsOn(DateTime day) {
    final k = dayKey(day);
    return foodLog.where((f) => dayKey(f.date) == k).toList();
  }

  void addFood(FoodEntry e) {
    foodLog.add(e);
    // Mantém só os últimos 120 dias para o armazenamento não crescer demais.
    final limit = DateTime.now().subtract(const Duration(days: 120));
    foodLog.removeWhere((f) => f.date.isBefore(limit));
    _commit();
  }

  void removeFood(String id) {
    foodLog.removeWhere((f) => f.id == id);
    _commit();
  }

  /// Alimentos usados recentemente (para adicionar com um toque).
  List<FoodEntry> get recentFoods {
    final seen = <String>{};
    final out = <FoodEntry>[];
    for (final f in foodLog.reversed) {
      if (seen.add(f.name.toLowerCase())) out.add(f);
      if (out.length >= 8) break;
    }
    return out;
  }

  // ---------- Treino em andamento ----------

  void saveSession(Map<String, dynamic> session) {
    activeSession = session;
    _prefs.setString(_sessionKey, jsonEncode(session));
  }

  void clearSession() {
    activeSession = null;
    _prefs.remove(_sessionKey);
    notifyListeners();
  }

  // ---------- Backup (sem login) ----------

  String exportBackup() => jsonEncode(_toJson());

  /// Restaura um backup. Retorna false se o texto não for válido.
  bool importBackup(String raw) {
    try {
      final j = jsonDecode(raw.trim()) as Map<String, dynamic>;
      if (j['profile'] == null) return false;
      _fromJson(j);
      onboarded = true;
      _commit();
      NotificationService.instance.reschedule(reminders);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------- Lembretes ----------

  Future<void> updateReminders(void Function(ReminderSettings r) change) async {
    change(reminders);
    _commit();
    await NotificationService.instance.reschedule(reminders);
  }

  // ---------- Privacidade ----------

  Future<void> eraseAll() async {
    await NotificationService.instance.cancelAll();
    await _prefs.remove(_key);
    await _prefs.remove(_sessionKey);
    activeSession = null;
    foodLog = [];
    weeklyGoal = 3;
    onboarded = false;
    profile = Profile();
    templates = starterTemplates(newId);
    workoutLogs = [];
    runLogs = [];
    weightLog = [];
    water = {};
    reminders = ReminderSettings();
    notifyListeners();
  }
}

/// Dá acesso ao AppState em qualquer widget.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
