# Como publicar o Forja no Google Play: passo a passo

Siga em ordem. Os textos e as respostas dos formulários estão prontos em **`store/FICHA_GOOGLE_PLAY.md`**.

## Antes de começar
- [ ] **Flutter atualizado:** rode `flutter upgrade`. Use a versão estável mais recente (3.35 ou mais nova).
- [ ] **Android Studio** instalado, com o Android SDK.
- [ ] **Celular Android** com a depuração USB ligada, para testar de verdade.
- [ ] **Conta de desenvolvedor no Google Play:** taxa única de US$ 25 e verificação de identidade (documento e telefone).

---

## Passo 1: personalizar
1. Abra `lib/app_info.dart` e troque:
   - `supportEmail` pelo seu e-mail de contato;
   - `privacyUrl` pelo link onde a política vai ficar (passo 3).
2. Escolha o **ID do app**, no formato `com.seunome.forja`.
   - Ele aparece na URL da loja e **não pode ser mudado depois de publicar**.
   - Use só letras minúsculas, números, `_` e pontos.

## Passo 2: gerar o projeto Android e testar
Na pasta do projeto, rode (o ID `com.diegomonteiro.forja_fit` já está registrado no seu Play Console):
```bash
flutter create --org com.diegomonteiro --project-name forja_fit --platforms android .
flutter pub get
dart run tool/setup.dart
flutter run --release
```
O `setup.dart` configura:
- permissões e lembretes no Android;
- o Android 16 (API 36), exigido desde 31/08/2026;
- as regras do R8, sem as quais os lembretes quebram na versão de loja;
- o ícone, o ícone de notificação e a tela de abertura;
- a assinatura de release.

**Teste no celular, em modo release:**
- [ ] Primeiro acesso completo e permissão de notificações.
- [ ] Gerar um treino, fazer 2 séries, fechar o app à força e reabrir. O aviso "Retomar" precisa aparecer.
- [ ] Descanso: bloquear a tela durante o descanso. A notificação precisa chegar.
- [ ] Corrida com GPS: a explicação aparece, a permissão é pedida, a notificação "Corrida em andamento" aparece, a medição continua com a tela bloqueada e o histórico salva.
- [ ] Lembrete de treino: programar para daqui a 2 minutos e esperar chegar.
- [ ] Dieta: adicionar, apagar e desfazer.
- [ ] Backup: copiar, apagar todos os dados e restaurar.

## Passo 3: política de privacidade (já hospedada)
A política fica no GitHub Pages do portfólio, no arquivo `forja/privacidade.html`:

**https://diegomonteirosousa.github.io/portifolio/forja/privacidade.html**

Esse link já está em `lib/app_info.dart`. Cole-o também no Play Console, em *Conteúdo do app > Política de privacidade*.

Se mudar o texto da política, edite `lib/data/legal.dart` e o `privacidade.html` juntos.

## Passo 4: criar a chave de upload (uma única vez)
```bash
dart run tool/criar_chave.dart
```
O comando cria `android/upload-keystore.jks` e `android/key.properties`.

> ⚠️ **Faça backup desses dois arquivos e anote a senha** (pendrive e gerenciador de senhas). Eles não vão para o Git. Sem eles, você não envia atualizações. Se perder, dá para pedir uma chave nova ao Google em *Integridade do app > Assinatura do app*, mas leva alguns dias.

## Passo 5: gerar o arquivo da loja (.aab)
```bash
flutter build appbundle --release
```
O arquivo para enviar é `build/app/outputs/bundle/release/app-release.aab`.

**A cada nova versão,** aumente o número em `pubspec.yaml` (`version: 1.0.1+2`) e também em `lib/app_info.dart`. O número depois do `+` precisa sempre subir.

## Passo 6: criar o app no Play Console
1. Acesse https://play.google.com/console e toque em **Criar app**.
2. Preencha:
   - Nome: `Forja: Treino, Corrida e Dieta`;
   - Idioma padrão: Português (Brasil);
   - Tipo: **App**;
   - Preço: **Gratuito**;
   - aceite as declarações.
3. Em **Integridade do app > Assinatura do app**, mantenha a **assinatura de apps do Google Play** (é o padrão). A sua chave serve só para *upload*.

## Passo 7: preencher "Conteúdo do app"
Use as respostas prontas em `store/FICHA_GOOGLE_PLAY.md`, seção 2:
- política de privacidade, acesso ao app e anúncios;
- classificação do conteúdo, público-alvo e segurança dos dados;
- apps de saúde;
- **serviço em primeiro plano (localização)**, com o link do vídeo.

## Passo 8: ficha da loja
Em **Crescer > Presença na loja > Ficha principal da loja**:
- cole o nome e as descrições da seção 1;
- envie o ícone (512) e o gráfico de recurso (1024 × 500) da pasta `store/graficos/`;
- envie de 4 a 8 capturas de tela (veja a seção 4 da ficha).

## Passo 9: teste fechado (obrigatório para contas pessoais novas)
Contas pessoais criadas depois de novembro de 2023 precisam disso antes de publicar:
1. Em **Testar e lançar > Teste > Teste fechado**, crie uma faixa e envie o `.aab`.
2. Adicione **pelo menos 12 testadores** (recomendado de 14 a 16, por segurança) por e-mail ou Grupo do Google.
3. Os testadores precisam **aceitar o convite e instalar** pelo link de teste.
4. Mantenha o teste rodando por **14 dias seguidos** com 12 ou mais pessoas inscritas, e peça que **usem o app de verdade**. Desde 2026, o Google recusa testes com pouco uso.
5. Depois dos 14 dias, vá em **Painel > Solicitar acesso à produção** e responda as perguntas sobre o teste (o que foi testado e o que você melhorou).

> Conta de **organização** (com CNPJ e D-U-N-S) não tem essa exigência e pode ir direto para a produção.

## Passo 10: produção
1. Em **Produção > Criar nova versão**, envie o `.aab` (ou promova a versão do teste fechado).
2. Cole as notas da versão.
3. **Enviar para revisão.** A análise costuma levar de algumas horas a 7 dias.

---

## Problemas comuns
| Problema | Solução |
| --- | --- |
| "Você precisa usar um código de versão diferente" | Aumente o número depois do `+` no `pubspec.yaml` |
| "O app precisa segmentar a API 36" | Rode `dart run tool/setup.dart` de novo e atualize o Flutter |
| Lembretes não chegam na versão de loja | Confira se existe `android/app/proguard-rules.pro` (o `setup.dart` cria) |
| Rejeição por "serviço em primeiro plano" | Refaça o vídeo mostrando claramente o toque em "Iniciar" e a notificação |
| Rejeição por "política de privacidade" | O link precisa abrir sem login e mencionar localização e dados de saúde (a nossa já menciona) |
| `keytool` não encontrado | Instale o Android Studio ou use o caminho mostrado em `flutter doctor -v` |

## Perdi a chave
Em **Integridade do app > Assinatura do app > Solicitar redefinição da chave de upload**, siga as instruções. O Google aprova a troca em alguns dias.
