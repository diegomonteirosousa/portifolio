class Exercise {
  final String id;
  final String name;
  final String muscle;
  final String equipment;
  final String tip;

  const Exercise(this.id, this.name, this.muscle, this.equipment, this.tip);
}

const muscleGroups = [
  'Peito',
  'Costas',
  'Pernas',
  'Glúteos',
  'Ombros',
  'Bíceps',
  'Tríceps',
  'Core',
  'Funcional',
];

const exerciseLibrary = <Exercise>[
  // Peito
  Exercise('supino_reto', 'Supino reto com barra', 'Peito', 'Barra',
      'Escápulas retraídas e pés firmes no chão.'),
  Exercise('supino_inclinado_halter', 'Supino inclinado com halteres', 'Peito',
      'Halteres', 'Banco a 30°. Desça até a linha do peito.'),
  Exercise('crucifixo', 'Crucifixo com halteres', 'Peito', 'Halteres',
      'Cotovelos levemente flexionados o tempo todo.'),
  Exercise('crossover', 'Crossover na polia', 'Peito', 'Polia',
      'Junte as mãos à frente do quadril, sem balançar o tronco.'),
  Exercise('flexao', 'Flexão de braço', 'Peito', 'Peso do corpo',
      'Corpo reto como uma prancha do início ao fim.'),
  Exercise('paralelas', 'Mergulho nas paralelas', 'Peito', 'Peso do corpo',
      'Incline o tronco à frente para focar no peito.'),
  // Costas
  Exercise('barra_fixa', 'Barra fixa', 'Costas', 'Peso do corpo',
      'Puxe os cotovelos em direção ao quadril.'),
  Exercise('puxada_frente', 'Puxada frontal', 'Costas', 'Máquina',
      'Leve a barra até o alto do peito, sem jogar o corpo para trás.'),
  Exercise('remada_curvada', 'Remada curvada com barra', 'Costas', 'Barra',
      'Coluna neutra e tronco a cerca de 45°.'),
  Exercise('remada_unilateral', 'Remada unilateral com halter', 'Costas',
      'Halteres', 'Puxe o halter em direção ao quadril.'),
  Exercise('remada_baixa', 'Remada baixa na polia', 'Costas', 'Polia',
      'Peito aberto e ombros para baixo.'),
  Exercise('levantamento_terra', 'Levantamento terra', 'Costas', 'Barra',
      'Barra colada às pernas e coluna neutra. Comece leve.'),
  // Pernas
  Exercise('agachamento', 'Agachamento livre', 'Pernas', 'Barra',
      'Joelhos na direção dos pés e peso no meio do pé.'),
  Exercise('leg_press', 'Leg press 45°', 'Pernas', 'Máquina',
      'Não tire a lombar do banco na descida.'),
  Exercise('cadeira_extensora', 'Cadeira extensora', 'Pernas', 'Máquina',
      'Segure 1 segundo no topo.'),
  Exercise('mesa_flexora', 'Mesa flexora', 'Pernas', 'Máquina',
      'Quadril colado no banco.'),
  Exercise('afundo', 'Afundo com halteres', 'Pernas', 'Halteres',
      'Passo longo e tronco ereto.'),
  Exercise('agachamento_bulgaro', 'Agachamento búlgaro', 'Pernas', 'Halteres',
      'Pé de trás apoiado no banco, desça controlando.'),
  Exercise('panturrilha', 'Panturrilha em pé', 'Pernas', 'Máquina',
      'Amplitude completa, pausa no alongamento.'),
  // Glúteos
  Exercise('elevacao_pelvica', 'Elevação pélvica', 'Glúteos', 'Barra',
      'Contraia o glúteo no topo por 1 segundo.'),
  Exercise('stiff', 'Stiff', 'Glúteos', 'Barra',
      'Leve o quadril para trás com joelhos levemente flexionados.'),
  Exercise('abducao', 'Cadeira abdutora', 'Glúteos', 'Máquina',
      'Movimento controlado, sem impulso.'),
  Exercise('coice_polia', 'Coice na polia', 'Glúteos', 'Polia',
      'Não arqueie a lombar.'),
  // Ombros
  Exercise('desenvolvimento', 'Desenvolvimento com halteres', 'Ombros',
      'Halteres', 'Não trave os cotovelos no topo.'),
  Exercise('desenvolvimento_militar', 'Desenvolvimento militar', 'Ombros',
      'Barra', 'Abdômen e glúteos contraídos.'),
  Exercise('elevacao_lateral', 'Elevação lateral', 'Ombros', 'Halteres',
      'Suba até a linha dos ombros, cotovelos à frente.'),
  Exercise('face_pull', 'Face pull', 'Ombros', 'Polia',
      'Puxe a corda em direção ao rosto, abrindo os cotovelos.'),
  // Bíceps
  Exercise('rosca_direta', 'Rosca direta com barra', 'Bíceps', 'Barra',
      'Cotovelos parados ao lado do corpo.'),
  Exercise('rosca_alternada', 'Rosca alternada', 'Bíceps', 'Halteres',
      'Gire o punho durante a subida.'),
  Exercise('rosca_martelo', 'Rosca martelo', 'Bíceps', 'Halteres',
      'Pegada neutra, sem balançar.'),
  // Tríceps
  Exercise('triceps_polia', 'Tríceps na polia', 'Tríceps', 'Polia',
      'Estenda totalmente e volte devagar.'),
  Exercise('triceps_frances', 'Tríceps francês', 'Tríceps', 'Halteres',
      'Cotovelos apontando para cima.'),
  Exercise('supino_fechado', 'Supino fechado', 'Tríceps', 'Barra',
      'Mãos na largura dos ombros.'),
  // Core
  Exercise('prancha', 'Prancha (segundos)', 'Core', 'Peso do corpo',
      'Use as repetições como segundos. Quadril alinhado.'),
  Exercise('abdominal_infra', 'Abdominal infra', 'Core', 'Peso do corpo',
      'Tire o quadril do chão no final.'),
  Exercise('abdominal_crunch', 'Abdominal crunch', 'Core', 'Peso do corpo',
      'Tire só as escápulas do chão.'),
  Exercise('elevacao_pernas', 'Elevação de pernas na barra', 'Core',
      'Peso do corpo', 'Sem balançar o corpo.'),
  Exercise('roda_abdominal', 'Roda abdominal', 'Core', 'Acessório',
      'Só vá até onde mantém a lombar neutra.'),
  Exercise('russian_twist', 'Giro russo', 'Core', 'Peso do corpo',
      'Gire o tronco, não só os braços.'),
  // Funcional / cardio
  Exercise('burpee', 'Burpee', 'Funcional', 'Peso do corpo',
      'Mantenha um ritmo constante.'),
  Exercise('pular_corda', 'Pular corda (segundos)', 'Funcional', 'Acessório',
      'Use as repetições como segundos.'),
  Exercise('kettlebell_swing', 'Kettlebell swing', 'Funcional', 'Kettlebell',
      'A força vem do quadril, não dos braços.'),
  Exercise('box_jump', 'Salto na caixa', 'Funcional', 'Acessório',
      'Aterrisse suave, com os joelhos flexionados.'),
  Exercise('sprint', 'Tiro de corrida (metros)', 'Funcional', 'Nenhum',
      'Use as repetições como metros.'),
  Exercise('saco_pancada', 'Saco de pancada (rounds de 3 min)', 'Funcional',
      'Acessório', 'Guarda alta e respiração no golpe.'),
  Exercise('sombra', 'Boxe de sombra (segundos)', 'Funcional', 'Nenhum',
      'Use as repetições como segundos.'),
  Exercise('farmer_walk', 'Caminhada do fazendeiro (metros)', 'Funcional',
      'Halteres', 'Ombros para trás e passos curtos.'),
  Exercise('mountain_climber', 'Escalador', 'Funcional', 'Peso do corpo',
      'Quadril baixo e joelhos rápidos.'),
  Exercise('agachamento_salto', 'Agachamento com salto', 'Funcional',
      'Peso do corpo', 'Aterrisse suave.'),
  Exercise('chute_alto', 'Chute frontal alternado', 'Funcional', 'Nenhum',
      'Controle o equilíbrio na perna de apoio.'),
];

final Map<String, Exercise> exerciseById = {
  for (final e in exerciseLibrary) e.id: e,
};

Exercise exerciseOf(String id) =>
    exerciseById[id] ??
    Exercise(id, id, 'Outro', '', '');
