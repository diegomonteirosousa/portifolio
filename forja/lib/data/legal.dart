import '../app_info.dart';

/// Seção de um texto legal (título + parágrafos).
class LegalSection {
  final String title;
  final List<String> paragraphs;
  const LegalSection(this.title, this.paragraphs);
}

/// Política de privacidade. O mesmo texto está em store/politica-de-privacidade.html.
const privacyPolicy = <LegalSection>[
  LegalSection('Resumo', [
    'O ${AppInfo.name} não tem cadastro, não usa servidor e não envia seus dados para ninguém. '
        'Tudo o que você registra fica salvo apenas no seu celular.',
  ]),
  LegalSection('Quais dados o app guarda', [
    'Perfil: nome ou apelido (opcional), idade, sexo, peso, altura, nível de atividade, objetivo e peso meta.',
    'Atividades: treinos montados, séries, cargas, corridas (tempo, distância, parciais e percurso) e recordes.',
    'Alimentação e saúde: refeições registradas, consumo de água e histórico de peso.',
    'Configurações: horários dos lembretes e meta semanal.',
    'Esses dados são usados só para mostrar seus números, calcular metas e acompanhar seu progresso dentro do app.',
  ]),
  LegalSection('Localização', [
    'A localização (GPS) é usada somente durante uma corrida que você mesmo inicia, para medir distância, ritmo e desenhar o percurso.',
    'Enquanto a corrida está ativa, o Android mostra uma notificação "Corrida em andamento" e a medição continua mesmo com a tela bloqueada. '
        'Ao finalizar ou pausar a corrida, o app para de usar a localização.',
    'O percurso fica salvo apenas no seu celular. O app não acessa sua localização em nenhum outro momento.',
  ]),
  LegalSection('Notificações', [
    'Os lembretes de treino, de água e do fim do descanso são criados no próprio celular. '
        'Você pode desligá-los a qualquer momento no Perfil ou nas configurações do Android.',
  ]),
  LegalSection('Compartilhamento', [
    'O ${AppInfo.name} não vende, não compartilha e não transfere seus dados para terceiros. '
        'O app não tem anúncios, não usa ferramentas de análise (analytics) e não exige internet para funcionar.',
  ]),
  LegalSection('Backup', [
    'A função "Copiar backup" gera um texto com seus dados. Só você decide onde guardar esse texto. '
        'Ele não é enviado automaticamente para lugar nenhum.',
  ]),
  LegalSection('Seus direitos (LGPD)', [
    'Você pode ver e editar seus dados no próprio app. Para apagar tudo, use "Apagar todos os meus dados" no Perfil ou desinstale o app. '
        'Como não guardamos dados em servidores, não há cópia dos seus dados com a gente.',
  ]),
  LegalSection('Crianças', [
    'O app não é direcionado a menores de 13 anos.',
  ]),
  LegalSection('Saúde', [
    'Os cálculos de água, metabolismo, calorias e metas são estimativas e não substituem a orientação de médico, nutricionista ou profissional de educação física.',
  ]),
  LegalSection('Contato', [
    'Dúvidas sobre privacidade: ${AppInfo.supportEmail}',
    'Última atualização: ${AppInfo.policyDate}.',
  ]),
];
