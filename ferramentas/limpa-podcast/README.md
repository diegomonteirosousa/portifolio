# Limpa Podcast 🎙️

Ferramenta desktop para **remover ruído de fundo de vídeos de podcast preservando a voz**.
Feita pensando em gravações em lugar aberto: vento, trânsito, pessoas conversando ao fundo, pássaros.

O vídeo **não é recodificado**: a imagem original é copiada sem perda e só o áudio é trocado pelo áudio limpo.

## Como funciona

1. **Corte de graves (passa-alta, 80 Hz)**: remove o ronco do vento e do trânsito, que fica abaixo da voz.
2. **Redução de ruído**, com três métodos:
   | Método | Quando usar |
   |---|---|
   | **IA de voz** (padrão) | Lugar aberto, ruídos que mudam o tempo todo. Usa o RNNoise, uma rede neural treinada para separar fala de ruído. |
   | **Espectral** | Ruído constante (chiado, ar-condicionado, gerador). Aprende o "som do ruído" nas pausas da fala, ou num trecho que você indica, e remove só ele. |
   | **Espectral + IA** | Ruído muito forte. Aplica os dois em sequência. |
3. **Normalização de volume** em -16 LUFS, o padrão de Spotify, Apple Podcasts e YouTube.

Nos testes com fala real misturada a vento, trânsito e ruído ambiente, o método de IA reduziu o ruído nas pausas em ~18 dB (Espectral + IA: ~22 dB) em relação à voz, mantendo a voz praticamente intacta.

## Instalação e uso

Requisito: **Python 3.10 ou mais novo** ([python.org](https://www.python.org/downloads/); no Windows, marque *"Add Python to PATH"*).
O FFmpeg é baixado automaticamente junto com as dependências.

- **Windows**: dê dois cliques em `iniciar_windows.bat`
- **macOS / Linux**: rode `./iniciar_mac_linux.sh`
  (no Linux pode ser preciso instalar o Tkinter: `sudo apt install python3-tk`)

A primeira execução demora um pouco porque instala as dependências.

### Passo a passo

1. Clique em **Abrir...** e escolha o vídeo. O arquivo de saída é sugerido como `nome_sem_ruido.mp4`.
2. Deixe **IA de voz** marcado. Para lugar aberto é a melhor escolha.
3. Clique em **Gerar prévia**: são gerados 20 s de *antes* e *depois* para você comparar de ouvido.
4. Ajuste a **intensidade**:
   - ainda tem muito ruído → aumente (ou use *Espectral + IA*);
   - voz "metálica", abafada ou cortando no fim das palavras → diminua.
5. Clique em **Remover ruído do vídeo inteiro**.

> **Dica:** se existe um momento só com o ruído de fundo, sem ninguém falando (por exemplo, os primeiros segundos antes de começar), use o método Espectral e marque *"usar um trecho só com ruído"* informando esse intervalo (ex.: `0:00` até `0:03`). Isso deixa a limpeza mais precisa.

Formatos de entrada: MP4, MOV, MKV, AVI, WEBM, M4V, além de áudios (MP3, WAV, M4A, FLAC).
Também dá para salvar só o áudio, escolhendo `.wav` ou `.mp3` como saída.

## Linha de comando

```bash
python nucleo.py entrada.mp4 saida.mp4                        # IA de voz, 85%
python nucleo.py entrada.mp4 saida.mp4 --motor ambos --intensidade 0.9
python nucleo.py entrada.mp4 saida.mp4 --motor espectral --ruido 0 3
python nucleo.py entrada.mp4 previa.mp4 --previa 120          # só 20 s a partir de 2:00
```

## Gerar um executável (.exe), sem precisar de Python

```bash
pip install -r requirements.txt pyinstaller
# Windows (use ; no --add-data)
pyinstaller --noconfirm --windowed --name LimpaPodcast --add-data "modelos;modelos" --collect-data imageio_ffmpeg --collect-submodules noisereduce app.py
# macOS / Linux (use :)
pyinstaller --noconfirm --windowed --name LimpaPodcast --add-data "modelos:modelos" --collect-data imageio_ffmpeg --collect-submodules noisereduce app.py
```

O programa fica em `dist/LimpaPodcast/`. Para distribuir, copie essa pasta inteira.

## Arquivos

- `app.py`: interface gráfica (Tkinter)
- `nucleo.py`: processamento (extração, filtros, IA, remontagem do vídeo)
- `modelos/std.rnnn`: modelo RNNoise original da Xiph.org (licença BSD), no formato do filtro `arnndn` do FFmpeg ([richardpl/arnndn-models](https://github.com/richardpl/arnndn-models))
