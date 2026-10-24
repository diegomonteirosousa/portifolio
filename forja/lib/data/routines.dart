import '../models.dart';

/// Exercício de uma rotina pronta (imutável).
class RX {
  final String id;
  final int sets;
  final int reps;
  final int rest;
  const RX(this.id, this.sets, this.reps, [this.rest = 90]);

  PlannedExercise toPlanned() =>
      PlannedExercise(exerciseId: id, sets: sets, reps: reps, restSec: rest);
}

/// Rotina temática identificada apenas pelo apelido.
/// As inspirações ficam só na documentação interna, não no app,
/// para evitar uso de marca registrada ou direito de imagem.
class Routine {
  final String id;
  final String nickname;
  final String category;
  final String focus;
  final int difficulty; // 1 a 5
  final int minutes;
  final String story;
  final int color;
  final List<RX> exercises;

  const Routine({
    required this.id,
    required this.nickname,
    required this.category,
    required this.focus,
    required this.difficulty,
    required this.minutes,
    required this.story,
    required this.color,
    required this.exercises,
  });

  WorkoutTemplate toTemplate(String newId) => WorkoutTemplate(
        id: newId,
        name: 'Rotina $nickname',
        focus: focus,
        exercises: exercises.map((e) => e.toPlanned()).toList(),
      );
}

const routineCategories = ['Todos', 'Heróis', 'Luta', 'Atletas', 'Elas'];

const routines = <Routine>[
  Routine(
    id: 'adonis',
    nickname: 'Adonis',
    category: 'Luta',
    focus: 'Boxe, condicionamento e abdômen trincado',
    difficulty: 4,
    minutes: 55,
    color: 0xFFE4572E,
    story:
        'Filho de uma lenda, você precisa provar que o nome é seu. Rounds no saco, corda e um core de aço.',
    exercises: [
      RX('pular_corda', 3, 120, 45),
      RX('saco_pancada', 5, 1, 60),
      RX('flexao', 4, 20, 60),
      RX('barra_fixa', 4, 8, 90),
      RX('mountain_climber', 3, 30, 45),
      RX('abdominal_infra', 3, 15, 45),
      RX('prancha', 3, 60, 45),
    ],
  ),
  Routine(
    id: 'ragnarok',
    nickname: 'Ragnarok',
    category: 'Heróis',
    focus: 'Força pesada, ombros, costas e braços grandes',
    difficulty: 5,
    minutes: 70,
    color: 0xFF4C8BF5,
    story:
        'O trovão não pede licença. Cargas altas e volume para construir um físico de deus nórdico.',
    exercises: [
      RX('levantamento_terra', 5, 5, 180),
      RX('desenvolvimento_militar', 4, 6, 150),
      RX('barra_fixa', 4, 8, 120),
      RX('remada_curvada', 4, 8, 120),
      RX('elevacao_lateral', 4, 12, 60),
      RX('rosca_direta', 3, 10, 60),
      RX('triceps_frances', 3, 10, 60),
    ],
  ),
  Routine(
    id: 'rocha',
    nickname: 'Rocha',
    category: 'Heróis',
    focus: 'Alto volume, cardio matinal e disciplina',
    difficulty: 5,
    minutes: 75,
    color: 0xFF8D6E63,
    story:
        'Acordar cedo, cardio em jejum e muito volume. A disciplina é o ingrediente principal.',
    exercises: [
      RX('sprint', 6, 100, 60),
      RX('supino_inclinado_halter', 4, 12, 75),
      RX('crucifixo', 3, 15, 60),
      RX('leg_press', 4, 15, 90),
      RX('remada_unilateral', 4, 12, 75),
      RX('elevacao_lateral', 4, 15, 45),
      RX('rosca_martelo', 3, 15, 45),
      RX('triceps_polia', 3, 15, 45),
    ],
  ),
  Routine(
    id: 'garanhao',
    nickname: 'Garanhão',
    category: 'Luta',
    focus: 'Boxe old school, escadarias e força',
    difficulty: 3,
    minutes: 50,
    color: 0xFFB71C1C,
    story:
        'Sem academia chique. Corrida, saco de pancada e flexões até a vitória.',
    exercises: [
      RX('sombra', 3, 180, 60),
      RX('saco_pancada', 4, 1, 60),
      RX('flexao', 5, 15, 45),
      RX('abdominal_crunch', 4, 25, 30),
      RX('barra_fixa', 3, 8, 90),
      RX('sprint', 5, 50, 60),
    ],
  ),
  Routine(
    id: 'aco',
    nickname: 'Aço',
    category: 'Heróis',
    focus: 'Hipertrofia, peito e ombros de herói',
    difficulty: 4,
    minutes: 65,
    color: 0xFF1565C0,
    story:
        'Um físico que parece vindo de outro planeta. Peito cheio e ombros largos.',
    exercises: [
      RX('supino_reto', 5, 6, 150),
      RX('supino_inclinado_halter', 4, 10, 90),
      RX('paralelas', 3, 12, 90),
      RX('desenvolvimento', 4, 10, 90),
      RX('elevacao_lateral', 4, 15, 45),
      RX('face_pull', 3, 15, 45),
    ],
  ),
  Routine(
    id: 'tridente',
    nickname: 'Tridente',
    category: 'Heróis',
    focus: 'Força funcional, pegada e resistência',
    difficulty: 4,
    minutes: 55,
    color: 0xFF00897B,
    story:
        'Rei dos mares e das ondas. Força bruta que funciona fora da academia.',
    exercises: [
      RX('kettlebell_swing', 4, 20, 60),
      RX('farmer_walk', 4, 40, 60),
      RX('barra_fixa', 4, 10, 90),
      RX('agachamento', 4, 8, 120),
      RX('box_jump', 3, 10, 60),
      RX('roda_abdominal', 3, 10, 60),
    ],
  ),
  Routine(
    id: 'garra',
    nickname: 'Garra',
    category: 'Heróis',
    focus: 'Volume alto, definição e costas em V',
    difficulty: 4,
    minutes: 60,
    color: 0xFFF9A825,
    story:
        'Regeneração rápida e pouca gordura. Costas largas, braços marcados.',
    exercises: [
      RX('barra_fixa', 4, 10, 75),
      RX('puxada_frente', 4, 12, 60),
      RX('remada_baixa', 4, 12, 60),
      RX('desenvolvimento', 3, 12, 60),
      RX('rosca_alternada', 3, 12, 45),
      RX('triceps_polia', 3, 15, 45),
      RX('elevacao_pernas', 3, 12, 45),
    ],
  ),
  Routine(
    id: 'baba_yaga',
    nickname: 'Baba Yaga',
    category: 'Luta',
    focus: 'Agilidade, artes marciais e condicionamento',
    difficulty: 4,
    minutes: 45,
    color: 0xFF37474F,
    story:
        'Silencioso, preciso e incansável. Treino de agente que precisa estar pronto a qualquer hora.',
    exercises: [
      RX('burpee', 4, 12, 45),
      RX('chute_alto', 4, 20, 45),
      RX('agachamento_salto', 4, 15, 45),
      RX('flexao', 4, 15, 45),
      RX('russian_twist', 3, 30, 30),
      RX('sombra', 3, 120, 45),
    ],
  ),
  Routine(
    id: 'carvalho',
    nickname: 'Carvalho',
    category: 'Atletas',
    focus: 'Fisiculturismo clássico, alto volume',
    difficulty: 5,
    minutes: 80,
    color: 0xFF6D4C41,
    story:
        'A era de ouro do fisiculturismo. Muitas séries, conexão mente-músculo e paciência.',
    exercises: [
      RX('supino_reto', 5, 10, 90),
      RX('crucifixo', 4, 12, 60),
      RX('barra_fixa', 5, 10, 90),
      RX('remada_curvada', 4, 10, 90),
      RX('crossover', 4, 15, 45),
      RX('abdominal_crunch', 4, 25, 30),
    ],
  ),
  Routine(
    id: 'maquina',
    nickname: 'Máquina',
    category: 'Atletas',
    focus: 'Explosão, core e pernas de jogador',
    difficulty: 4,
    minutes: 50,
    color: 0xFF2E7D32,
    story:
        'Corpo de atleta de elite aos 40. Potência, velocidade e recuperação levadas a sério.',
    exercises: [
      RX('box_jump', 4, 8, 75),
      RX('agachamento_bulgaro', 3, 10, 75),
      RX('sprint', 6, 40, 60),
      RX('stiff', 3, 10, 90),
      RX('prancha', 3, 60, 30),
      RX('russian_twist', 3, 30, 30),
    ],
  ),
  Routine(
    id: 'raio',
    nickname: 'Raio',
    category: 'Atletas',
    focus: 'Velocidade, tiros e potência de pernas',
    difficulty: 3,
    minutes: 40,
    color: 0xFFFFD600,
    story: 'Cada centésimo conta. Tiros curtos e pernas explosivas.',
    exercises: [
      RX('sprint', 8, 60, 90),
      RX('agachamento_salto', 4, 10, 60),
      RX('afundo', 3, 12, 60),
      RX('panturrilha', 4, 20, 45),
      RX('mountain_climber', 3, 30, 30),
    ],
  ),
  Routine(
    id: 'dragao',
    nickname: 'Dragão',
    category: 'Luta',
    focus: 'Artes marciais, abdômen e flexibilidade',
    difficulty: 3,
    minutes: 40,
    color: 0xFFFF6F00,
    story: 'Seja como a água. Velocidade, controle e um abdômen lendário.',
    exercises: [
      RX('sombra', 4, 120, 45),
      RX('chute_alto', 4, 20, 45),
      RX('flexao', 4, 20, 45),
      RX('elevacao_pernas', 4, 12, 45),
      RX('abdominal_crunch', 4, 25, 30),
      RX('prancha', 3, 60, 30),
    ],
  ),
  Routine(
    id: 'mao_de_pedra',
    nickname: 'Mão de Pedra',
    category: 'Luta',
    focus: 'Kickboxing e potência de golpe',
    difficulty: 4,
    minutes: 50,
    color: 0xFF5D4037,
    story: 'Um golpe muda a luta. Explosão de quadril e condicionamento.',
    exercises: [
      RX('kettlebell_swing', 4, 15, 60),
      RX('saco_pancada', 5, 1, 60),
      RX('chute_alto', 3, 20, 45),
      RX('burpee', 3, 10, 45),
      RX('russian_twist', 3, 30, 30),
    ],
  ),
  Routine(
    id: 'diana',
    nickname: 'Diana',
    category: 'Elas',
    focus: 'Força, glúteos, ombros e luta',
    difficulty: 4,
    minutes: 55,
    color: 0xFFC62828,
    story: 'Guerreira de uma ilha lendária. Força de verdade com estética atlética.',
    exercises: [
      RX('agachamento', 4, 8, 120),
      RX('elevacao_pelvica', 4, 10, 90),
      RX('desenvolvimento', 3, 10, 75),
      RX('barra_fixa', 3, 6, 90),
      RX('sombra', 3, 120, 45),
      RX('prancha', 3, 45, 30),
    ],
  ),
  Routine(
    id: 'natasha',
    nickname: 'Natasha',
    category: 'Elas',
    focus: 'Definição, agilidade e treino funcional',
    difficulty: 3,
    minutes: 45,
    color: 0xFF263238,
    story: 'Espiã de elite. Leve, rápida e sempre um passo à frente.',
    exercises: [
      RX('agachamento_salto', 4, 12, 45),
      RX('afundo', 3, 12, 60),
      RX('flexao', 3, 12, 45),
      RX('kettlebell_swing', 3, 15, 60),
      RX('mountain_climber', 3, 30, 30),
      RX('russian_twist', 3, 30, 30),
    ],
  ),
  Routine(
    id: 'poderosa',
    nickname: 'Poderosa',
    category: 'Elas',
    focus: 'Glúteos, pernas e definição',
    difficulty: 3,
    minutes: 50,
    color: 0xFFD81B60,
    story: 'Palco exige energia. Glúteos fortes e fôlego para o show inteiro.',
    exercises: [
      RX('elevacao_pelvica', 4, 12, 75),
      RX('agachamento_bulgaro', 3, 10, 60),
      RX('abducao', 4, 15, 45),
      RX('coice_polia', 3, 15, 45),
      RX('stiff', 3, 12, 75),
      RX('pular_corda', 3, 60, 45),
    ],
  ),
  Routine(
    id: 'musa_de_ferro',
    nickname: 'Musa de Ferro',
    category: 'Elas',
    focus: 'Pernas e glúteos com carga alta',
    difficulty: 5,
    minutes: 70,
    color: 0xFF7B1FA2,
    story: 'Carga pesada sem medo. Pernas construídas com anos de dedicação.',
    exercises: [
      RX('agachamento', 5, 8, 150),
      RX('leg_press', 4, 12, 120),
      RX('elevacao_pelvica', 4, 10, 90),
      RX('stiff', 4, 10, 90),
      RX('cadeira_extensora', 3, 15, 60),
      RX('mesa_flexora', 3, 15, 60),
    ],
  ),
];

/// Treinos iniciais para quem está começando.
List<WorkoutTemplate> starterTemplates(String Function() id) => [
      WorkoutTemplate(
        id: id(),
        name: 'Full Body Iniciante',
        focus: 'Corpo inteiro, 3x por semana',
        exercises: [
          PlannedExercise(exerciseId: 'agachamento', sets: 3, reps: 10, restSec: 90),
          PlannedExercise(exerciseId: 'supino_reto', sets: 3, reps: 10, restSec: 90),
          PlannedExercise(exerciseId: 'puxada_frente', sets: 3, reps: 12, restSec: 75),
          PlannedExercise(exerciseId: 'desenvolvimento', sets: 3, reps: 12, restSec: 75),
          PlannedExercise(exerciseId: 'prancha', sets: 3, reps: 30, restSec: 45),
        ],
      ),
      WorkoutTemplate(
        id: id(),
        name: 'Treino A · Superior',
        focus: 'Peito, costas, ombros e braços',
        exercises: [
          PlannedExercise(exerciseId: 'supino_inclinado_halter', sets: 4, reps: 10),
          PlannedExercise(exerciseId: 'remada_baixa', sets: 4, reps: 10),
          PlannedExercise(exerciseId: 'elevacao_lateral', sets: 3, reps: 15, restSec: 60),
          PlannedExercise(exerciseId: 'rosca_direta', sets: 3, reps: 12, restSec: 60),
          PlannedExercise(exerciseId: 'triceps_polia', sets: 3, reps: 12, restSec: 60),
        ],
      ),
      WorkoutTemplate(
        id: id(),
        name: 'Treino B · Inferior',
        focus: 'Pernas, glúteos e core',
        exercises: [
          PlannedExercise(exerciseId: 'leg_press', sets: 4, reps: 12, restSec: 120),
          PlannedExercise(exerciseId: 'stiff', sets: 3, reps: 10, restSec: 90),
          PlannedExercise(exerciseId: 'cadeira_extensora', sets: 3, reps: 15, restSec: 60),
          PlannedExercise(exerciseId: 'panturrilha', sets: 4, reps: 15, restSec: 45),
          PlannedExercise(exerciseId: 'abdominal_infra', sets: 3, reps: 15, restSec: 45),
        ],
      ),
    ];
