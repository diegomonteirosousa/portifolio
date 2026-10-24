# Forja: app de treino sem login (Flutter)

Treino, corrida e nutrição num app só. Não tem cadastro: tudo fica salvo no próprio celular.

## O que já vem pronto

Navegação: **Início · Treinos · Corrida · Dieta · Progresso**. O Perfil abre pelo avatar no canto da tela inicial.

| Área | Funcionalidades |
| --- | --- |
| Primeiro acesso | 5 telas rápidas: nome (opcional), objetivo, corpo, nível de atividade e plano calculado. Os lembretes podem ser ativados ali mesmo. |
| Início | Treino do dia (rodízio automático A/B/C), aviso de **treino em andamento** para retomar, **meta semanal** com anel (toque para mudar), ofensiva, água com anel (a meta sobe nos dias de treino), **alimentação do dia em tempo real** (kcal e macros consumidos contra a meta), atalhos (correr, registrar refeição, peso, novo treino) e dica do dia. |
| Treinos | **Gerador automático** (objetivo, 2 a 6 dias, academia ou casa, nível): monta a divisão (corpo inteiro, superior/inferior, empurrar/puxar/pernas), os exercícios, as séries e o descanso. Também tem o montador manual, a biblioteca com 50 exercícios e 17 rotinas temáticas por apelido. |
| Treino ativo | Progresso **salvo a cada série** (fechou o app? retome do ponto onde parou). **Rola sozinho para o próximo exercício**, o descanso mostra **qual é a próxima série**, a carga da última vez vem preenchida, há calculadora de anilhas, troca de exercício e resumo com volume e recordes. |
| Corrida | GPS ou esteira, **meta de distância** (3, 5, 10 e 21 km) com barra de progresso, ritmo atual e médio, aviso a cada km, parciais, percurso desenhado e histórico. |
| Dieta | Diário por refeição com **69 alimentos brasileiros** (TACO), busca, recentes com um toque, porções, item manual pela embalagem, deslizar para apagar com desfazer, navegação por dias e água. |
| Progresso | Resumo da semana, séries por grupo muscular, histórico, gráfico de peso com linha da meta e recordes com 1RM estimado. |
| Perfil | Água, metabolismo basal, gasto total, metas, IMC, macros, progresso até o peso meta, lembretes, **backup sem login** (copiar/restaurar) e apagar todos os dados (LGPD). |

Os apelidos das rotinas aparecem sozinhos no app, sem nome de personagem ou famoso, para evitar problemas de marca e direito de imagem. As inspirações ficam só no documento do projeto.

## Como rodar (primeira vez)

1. Instale o Flutter (versão estável mais recente) e o Android Studio: https://docs.flutter.dev/get-started/install
2. Abra um terminal **dentro desta pasta** e rode, trocando `com.seunome` pelo seu domínio invertido:

```bash
flutter create --org com.diegomonteiro --project-name forja_fit --platforms android .
flutter pub get
dart run tool/setup.dart
flutter run
```

O `flutter create` gera a pasta `android/` sem apagar o código em `lib/`. O `tool/setup.dart` configura o resto:
- permissões, lembretes que sobrevivem a reiniciar o celular e o nome "Forja";
- o Android 16 (API 36), exigido pelo Google Play;
- as regras do R8 para a versão de loja;
- a assinatura de release;
- o ícone, o ícone de notificação e a tela de abertura.

**Para publicar no Google Play,** siga o **[PUBLICAR_GOOGLE_PLAY.md](PUBLICAR_GOOGLE_PLAY.md)**. Os textos e as respostas dos formulários estão em `store/FICHA_GOOGLE_PLAY.md`.

## Ícone e abertura

- **Ícone:** chama preta com miolo em gota sobre o verde-limão do app. Fica legível até nos tamanhos pequenos.
- **Abertura:** fundo escuro do app, logo no centro e "FORJA" no rodapé.

Para trocar, substitua os PNGs em `assets/icon/` e `assets/splash/` e rode de novo:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Testes

```bash
flutter test
```

Os testes conferem os cálculos (água, metabolismo, anilhas, formatação), as rotinas, o gerador de treinos (todas as 120 combinações de objetivo, local, nível e dias) e o banco de alimentos.

## Estrutura

```
lib/
  main.dart                 início do app
  theme.dart                tema escuro com destaque verde-limão
  models.dart               dados salvos (perfil, treinos, corridas, peso)
  state.dart                estado global + armazenamento local
  app_info.dart             e-mail de suporte, link da política e versão
  calc.dart                 água, metabolismo, calorias, metas, 1RM, anilhas
  generator.dart            gerador automático de planos de treino
  data/foods.dart           banco de alimentos brasileiros
  data/exercises.dart       biblioteca de exercícios
  data/routines.dart        rotinas temáticas e treinos iniciais
  services/notifications.dart  lembretes locais
  screens/                  telas
  widgets/common.dart       componentes reutilizáveis
assets/icon/                ícone do app, ícone adaptativo e ícone de notificação
assets/splash/              imagens da tela de abertura
tool/setup.dart             configura o Android, gera ícone e abertura
tool/criar_chave.dart       cria a chave de upload do Google Play
store/                      ficha da loja, política de privacidade e gráficos
PUBLICAR_GOOGLE_PLAY.md     passo a passo da publicação
```

## Próximos passos sugeridos

- Aviso por voz a cada km (`flutter_tts`).
- Backup opcional na nuvem com login anônimo (Supabase), sem obrigar cadastro.
- Política de privacidade, exigida pelas lojas porque o app guarda dados de saúde.

## Observações

- Os cálculos são estimativas e não substituem médico ou nutricionista. O app avisa isso no Perfil.
- O código foi escrito e revisado sem acesso ao SDK do Flutter, então a primeira compilação pode apontar algum detalhe pequeno. Se aparecer erro, copie a mensagem e peça a correção.
