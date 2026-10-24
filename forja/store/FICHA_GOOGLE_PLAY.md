# Ficha do Google Play: textos e respostas prontos

Copie e cole cada bloco no Play Console. Os limites de caracteres já foram conferidos.

---

## 1. Ficha principal da loja

**Nome do app** (30/30 caracteres)
```
Forja: Treino, Corrida e Dieta
```

**Descrição breve** (77/80 caracteres)
```
Monte treinos, corra com GPS e controle a dieta. Sem cadastro e sem anúncios.
```

**Descrição completa**
```
Forja é o app de treino que vai direto ao ponto: abra, treine e acompanhe sua evolução. Sem cadastro, sem anúncios e sem enviar seus dados para lugar nenhum.

💪 TREINOS QUE SE MONTAM SOZINHOS
• Gerador automático: escolha objetivo, dias por semana, se treina na academia ou em casa e seu nível. O Forja monta a divisão, os exercícios, as séries e o descanso.
• Montador manual com biblioteca de 50 exercícios e dicas de execução.
• 17 rotinas temáticas prontas, com histórias e níveis de dificuldade.

⏱️ MODO ACADEMIA
• Tela sempre acesa e botões grandes.
• Descanso automático ao marcar a série, com aviso por vibração e notificação.
• A carga da última vez já vem preenchida.
• Calculadora de anilhas, troca rápida de exercício e recordes pessoais.
• Fechou o app sem querer? O treino fica salvo e você continua de onde parou.

🏃 CORRIDA COM GPS
• Distância, tempo, ritmo atual e médio, calorias e parciais a cada km.
• Meta de distância (3, 5, 10 ou 21 km) com barra de progresso.
• Funciona com a tela bloqueada e desenha o seu percurso.
• Modo esteira, sem GPS.

🥗 DIETA E ÁGUA
• Diário alimentar com alimentos brasileiros (arroz, feijão, tapioca, cuscuz, PF...).
• Calorias e macros do dia contados em tempo real contra a sua meta.
• Meta de água calculada pelo seu peso, que aumenta nos dias de treino.

📊 PROGRESSO
• Meta semanal, ofensiva de dias seguidos e músculos treinados na semana.
• Gráfico de peso com a linha da sua meta.
• Metabolismo basal, gasto calórico diário, IMC e previsão de quando você chega ao peso desejado.

🔒 PRIVACIDADE DE VERDADE
Tudo fica salvo apenas no seu celular. Para trocar de aparelho, use o backup em texto, sem precisar criar conta.

⚠️ Os cálculos são estimativas e não substituem a orientação de médico, nutricionista ou profissional de educação física.
```

**Recursos gráficos** (pasta `store/graficos/`)
| Item | Arquivo | Exigência |
| --- | --- | --- |
| Ícone do app | `icone-512.png` | 512 × 512, PNG |
| Gráfico de recurso | `grafico-de-recurso-1024x500.png` | 1024 × 500, PNG ou JPG |
| Capturas de tela do celular | você tira (veja a seção 8) | mínimo de 2, recomendado de 4 a 8 |

**Categoria:** Saúde e fitness
**Tags sugeridas:** Fitness, Corrida, Treino, Dieta e nutrição
**E-mail de contato:** o mesmo de `lib/app_info.dart`
**Política de privacidade:** `https://diegomonteirosousa.github.io/portifolio/forja/privacidade.html`

---

## 2. Conteúdo do app (Política > Conteúdo do app)

### Política de privacidade
Cole: `https://diegomonteirosousa.github.io/portifolio/forja/privacidade.html`

### Acesso ao app
- Marque: **"Todas as funcionalidades estão disponíveis sem acesso especial"**.
- Motivo: não existe login.

### Anúncios
- Marque: **"Não, meu app não contém anúncios"**.

### Classificação do conteúdo (questionário IARC)
- **Categoria:** "Todos os outros tipos de app" (ou Utilitários/Produtividade, se aparecer).
- Responda **Não** a: violência, medo, sexualidade, linguagem imprópria, drogas, jogos de azar, compras digitais e conteúdo gerado por usuários.
- Interação entre usuários: **Não**.
- Compartilha a localização do usuário com outros usuários: **Não**.
- **Resultado esperado:** Livre / PEGI 3 / Everyone.

### Público-alvo e conteúdo
- **Faixas etárias:** 13 a 15, 16 a 17 e 18 ou mais.
  - Não marque menores de 13: isso ativaria a política para Famílias.
- Pode atrair crianças sem querer? **Não**.

### Segurança dos dados (Data safety)
O app não envia nenhum dado para fora do celular. Pela definição do Google, processar dados apenas no aparelho **não conta como coleta**.

| Pergunta | Resposta |
| --- | --- |
| O app coleta ou compartilha algum dos tipos de dados exigidos? | **Não** |
| Todos os dados coletados são criptografados em trânsito? | Não se aplica (nada é transmitido) |
| Os usuários podem pedir a exclusão dos dados? | Não se aplica. Mesmo assim, o app tem "Apagar todos os meus dados" no Perfil |

> Se no futuro você adicionar login, backup na nuvem, analytics, anúncios ou pagamentos, **refaça este formulário**.

### Apps de saúde (se o formulário aparecer)
- Marque **Atividade física e condicionamento** e **Nutrição e controle de peso**.
- O app **não** é um dispositivo médico e **não** usa a Conexão Saúde (Health Connect).

### Serviço em primeiro plano: localização
O Android 14+ exige esta declaração porque a corrida continua medindo com a tela bloqueada.

- **Tipo de serviço:** Localização.
- **Caso de uso:** "Navegação ou rastreamento de percurso". Se não existir, escolha "Outro" e cole a descrição abaixo.
- **Descrição da funcionalidade:**
```
O usuário toca em "Iniciar" na aba Corrida. Enquanto a corrida está ativa, o app usa o GPS para medir distância, ritmo e desenhar o percurso, inclusive com a tela bloqueada. Uma notificação "Corrida em andamento" fica visível o tempo todo. Ao pausar ou finalizar, o serviço é encerrado. A localização fica salva apenas no aparelho e não é enviada a servidores.
```
- **Impacto se o sistema adiar ou interromper:**
```
A medição da corrida fica errada: a distância, o ritmo e o percurso deixam de ser registrados no trecho em que o serviço foi interrompido.
```
- **Link do vídeo:** um vídeo curto (30 a 60 s, pode ser "Não listado" no YouTube) mostrando:
  1. Abrir o app e ir à aba **Corrida**.
  2. Escolher "Rua (GPS)" e tocar em **Iniciar**.
  3. Aceitar a explicação e a permissão de localização.
  4. Mostrar a notificação "Corrida em andamento" na barra de status.
  5. Bloquear a tela, andar alguns metros, desbloquear e mostrar a distância aumentando.
  6. Tocar em **Finalizar**.

Para gravar, use o gravador de tela do próprio Android (painel rápido > "Gravar tela").

### Permissões que o app usa (para referência)
| Permissão | Para quê |
| --- | --- |
| Localização precisa/aproximada | Medir a corrida, só quando o usuário inicia |
| Serviço em primeiro plano (localização) | Continuar medindo a corrida com a tela bloqueada |
| Notificações | Lembretes de treino e água, fim do descanso e corrida em andamento |
| Inicialização do sistema | Manter os lembretes depois de reiniciar o celular |
| Vibração e manter acordado | Avisos de descanso e a tela acesa no treino |

O app **não** pede localização em segundo plano (`ACCESS_BACKGROUND_LOCATION`) nem alarmes exatos. Por isso, não precisa das declarações dessas permissões.

---

## 3. Notas da versão 1.0.0
```
Primeira versão do Forja!
• Gerador de treinos e 17 rotinas temáticas
• Modo academia com descanso automático
• Corrida com GPS, meta de distância e parciais
• Diário alimentar com alimentos brasileiros
• Metas de água, calorias e treinos por semana
```

---

## 4. Capturas de tela: o que mostrar

Use o emulador **Pixel 2** do Android Studio (1080 × 1920). O Google não aceita imagens em que um lado tenha mais que o dobro do outro, e alguns celulares novos (1080 × 2400) passam desse limite.

Ordem sugerida, com dados de exemplo preenchidos:
1. **Início:** treino do dia, meta semanal, água e alimentação.
2. **Treino ativo:** séries marcadas e o painel de descanso com a "próxima série".
3. **Gerador de treino:** a prévia do plano.
4. **Corrida:** em andamento, com a meta de 5 km.
5. **Dieta:** o anel de calorias e as refeições.
6. **Progresso:** o gráfico de peso.

Para tirar a captura no emulador, use o botão de câmera na barra lateral ou rode `flutter screenshot`.
