"""
Núcleo de processamento do Limpa Podcast.

Fluxo:
  1. Extrai o áudio do vídeo com FFmpeg (WAV 48 kHz, float).
  2. Filtro passa-alta de fase zero (remove vento / ronco grave abaixo da voz).
  3. Redução de ruído, conforme o motor escolhido:
       - "ia": RNNoise (rede neural treinada para separar voz de ruído),
         via filtro arnndn do FFmpeg. Melhor para lugar aberto.
       - "espectral": "spectral gating" (noisereduce) com perfil de ruído
         aprendido nas pausas da fala ou num trecho indicado.
       - "ambos": espectral seguido da IA (limpeza máxima).
  4. Remonta o vídeo: copia a imagem original sem recodificar e troca só o
     áudio pelo áudio limpo (opcionalmente normalizado a -16 LUFS).

Também pode ser usado pela linha de comando:
  python nucleo.py entrada.mp4 saida.mp4 --intensidade 0.85
"""

import os
import shutil
import subprocess
import sys
import tempfile
import threading
from dataclasses import dataclass, field
from typing import Callable, Optional, Tuple

import numpy as np
import soundfile as sf
import noisereduce as nr
from scipy.signal import butter, sosfiltfilt

TAXA = 48000          # o RNNoise trabalha em 48 kHz
BLOCO_S = 30.0        # tamanho de cada bloco processado
MARGEM_S = 3.0        # sobreposição em cada lado do bloco
QUADRO_S = 0.1        # janela usada para achar trechos silenciosos
PERFIL_MAX_S = 10.0   # duração máxima do perfil automático de ruído
MOTORES = ("ia", "espectral", "ambos")


def _pasta_base():
    # Dentro de um executável do PyInstaller os arquivos ficam em sys._MEIPASS.
    return getattr(sys, "_MEIPASS", os.path.dirname(os.path.abspath(__file__)))


PASTA_MODELOS = os.path.join(_pasta_base(), "modelos")
MODELO_IA = "std.rnnn"

Progresso = Callable[[float, str], None]


class Cancelado(Exception):
    pass


@dataclass
class Config:
    motor: str = "ia"
    intensidade: float = 0.85               # 0..1, quanto do ruído é removido
    passa_alta_hz: Optional[float] = 80.0   # None desliga
    normalizar: bool = True                 # loudness de podcast (-16 LUFS)
    trecho_ruido: Optional[Tuple[float, float]] = None  # (início, fim) em s, só ruído
    bitrate_audio: str = "192k"
    cancelar: threading.Event = field(default_factory=threading.Event)


def ffmpeg_exe() -> str:
    """FFmpeg do sistema ou, se não houver, o que vem com o imageio-ffmpeg."""
    sistema = shutil.which("ffmpeg")
    if sistema:
        return sistema
    try:
        import imageio_ffmpeg
        return imageio_ffmpeg.get_ffmpeg_exe()
    except Exception as erro:
        raise RuntimeError(
            "FFmpeg não encontrado. Instale com 'pip install imageio-ffmpeg' "
            "ou baixe em https://ffmpeg.org"
        ) from erro


def _executar(args, cwd=None):
    flags = subprocess.CREATE_NO_WINDOW if sys.platform == "win32" else 0
    return subprocess.run(
        [ffmpeg_exe(), "-hide_banner", *args],
        capture_output=True, text=True, errors="replace", cwd=cwd, creationflags=flags,
    )


def _rodar(args, cwd=None):
    proc = _executar(["-loglevel", "error", "-y", *args], cwd)
    if proc.returncode != 0:
        raise RuntimeError("Erro do FFmpeg:\n" + proc.stderr.strip())


def tem_video(caminho: str) -> bool:
    linhas = _executar(["-i", caminho]).stderr.splitlines()
    return any("Video:" in l and "attached pic" not in l for l in linhas)


def extrair_audio(entrada, wav, inicio=None, duracao=None):
    args = []
    if inicio is not None:
        args += ["-ss", str(inicio)]
    args += ["-i", os.path.abspath(entrada)]
    if duracao is not None:
        args += ["-t", str(duracao)]
    args += ["-vn", "-ac", "2", "-ar", str(TAXA), "-c:a", "pcm_f32le", os.path.abspath(wav)]
    _rodar(args)


# ---------------------------------------------------------------- perfil de ruído
def _perfil_automatico(wav) -> Optional[np.ndarray]:
    """Junta os trechos mais silenciosos (pausas entre falas) como amostra de ruído."""
    quadro = int(QUADRO_S * TAXA)
    energias = np.array([
        np.sqrt(np.mean(b ** 2))
        for b in sf.blocks(wav, blocksize=quadro, dtype="float32", always_2d=True)
    ])
    validos = np.where(energias > 1e-5)[0]  # ignora silêncio digital
    if len(validos) < 10:
        return None
    qtd = int(np.clip(len(validos) * 0.05, 10, PERFIL_MAX_S / QUADRO_S))
    escolhidos = np.sort(validos[np.argsort(energias[validos])[:qtd]])
    with sf.SoundFile(wav) as f:
        partes = []
        for i in escolhidos:
            f.seek(int(i) * quadro)
            partes.append(f.read(quadro, dtype="float32", always_2d=True))
    return np.concatenate(partes).T


def _perfil_manual(wav, trecho) -> np.ndarray:
    ini, fim = trecho
    if fim <= ini:
        raise ValueError("O fim do trecho de ruído deve ser maior que o início.")
    ruido, _ = sf.read(
        wav, start=int(ini * TAXA), stop=int(fim * TAXA),
        dtype="float32", always_2d=True,
    )
    if len(ruido) < TAXA * 0.5:
        raise ValueError("O trecho de ruído precisa ter pelo menos 0,5 s dentro do arquivo.")
    return ruido.T


# ---------------------------------------------------------------- etapas
def filtrar_espectral(origem, destino, cfg: Config, progresso: Progresso,
                      ruido: Optional[np.ndarray] = None):
    """Passa-alta e (se o motor pedir) redução espectral, em blocos sobrepostos."""
    info = sf.info(origem)
    total = info.frames
    usar_espectral = cfg.motor in ("espectral", "ambos")
    # Quando a IA vem depois, o espectral é mais leve para não somar artefatos.
    reducao = cfg.intensidade * (0.7 if cfg.motor == "ambos" else 1.0)

    sos = None
    if cfg.passa_alta_hz:
        sos = butter(4, cfg.passa_alta_hz, btype="highpass", fs=TAXA, output="sos")

    if usar_espectral:
        progresso(0.08, "Aprendendo o perfil do ruído...")
        if ruido is None:
            ruido = (_perfil_manual(origem, cfg.trecho_ruido) if cfg.trecho_ruido
                     else _perfil_automatico(origem))
        if ruido is None:
            raise ValueError("Não encontrei pausas na fala para aprender o ruído. "
                             "Indique um trecho só com ruído ou use o motor de IA.")
        if sos is not None:
            ruido = sosfiltfilt(sos, ruido, axis=-1)

    bloco = int(BLOCO_S * TAXA)
    margem = int(MARGEM_S * TAXA)
    with sf.SoundFile(origem) as entrada, sf.SoundFile(
        destino, "w", samplerate=TAXA, channels=info.channels, subtype="FLOAT"
    ) as saida:
        for inicio in range(0, total, bloco):
            if cfg.cancelar.is_set():
                raise Cancelado()
            fim = min(inicio + bloco, total)
            ler_ini = max(0, inicio - margem)
            entrada.seek(ler_ini)
            trecho = entrada.read(min(total, fim + margem) - ler_ini,
                                  dtype="float32", always_2d=True).T

            if sos is not None and trecho.shape[1] > 30:
                trecho = sosfiltfilt(sos, trecho, axis=-1)
            if usar_espectral and trecho.shape[1] >= 2048:
                trecho = nr.reduce_noise(
                    y=trecho, sr=TAXA, stationary=True, y_noise=ruido,
                    prop_decrease=reducao, n_fft=2048,
                    # suavização maior evita o som "metálico/robótico" na voz
                    freq_mask_smooth_hz=400, time_mask_smooth_ms=80,
                )

            util = trecho[:, inicio - ler_ini: inicio - ler_ini + (fim - inicio)]
            saida.write(np.clip(util.T, -1.0, 1.0).astype(np.float32))
            progresso(0.1 + 0.4 * fim / total,
                      f"Filtrando... {fim / TAXA:.0f}s de {total / TAXA:.0f}s")


def filtrar_ia(origem, destino, cfg: Config):
    """RNNoise: rede neural que mantém a voz e remove o resto."""
    modelo = os.path.join(PASTA_MODELOS, MODELO_IA)
    if not os.path.isfile(modelo):
        raise RuntimeError(f"Modelo de IA não encontrado em {modelo}")
    # O caminho do modelo é relativo (cwd) para não precisar escapar "C:\" no filtro.
    _rodar(["-i", os.path.abspath(origem),
            "-af", f"arnndn=m={MODELO_IA}:mix={cfg.intensidade:.2f}",
            "-c:a", "pcm_f32le", os.path.abspath(destino)], cwd=PASTA_MODELOS)


def montar_saida(entrada, wav_limpo, saida, cfg: Config, inicio=None, duracao=None):
    filtros = ["loudnorm=I=-16:TP=-1.5:LRA=11"] if cfg.normalizar else []
    ext = os.path.splitext(saida)[1].lower()
    so_audio = ext in (".wav", ".mp3", ".m4a", ".flac", ".aac") or not tem_video(entrada)

    args = []
    if so_audio:
        args += ["-i", wav_limpo]
        if filtros:
            args += ["-af", ",".join(filtros), "-ar", str(TAXA)]
        codecs = {".wav": ["-c:a", "pcm_s16le"], ".flac": ["-c:a", "flac"],
                  ".mp3": ["-c:a", "libmp3lame", "-b:a", cfg.bitrate_audio]}
        args += codecs.get(ext, ["-c:a", "aac", "-b:a", cfg.bitrate_audio])
        _rodar(args + [saida])
        return

    if inicio is not None:
        args += ["-ss", str(inicio)]
    args += ["-i", entrada]
    if duracao is not None:
        args += ["-t", str(duracao)]
    args += ["-i", wav_limpo, "-map", "0:v:0", "-map", "1:a:0"]
    # Num corte (prévia) o vídeo precisa ser recodificado para começar no ponto exato.
    args += ["-c:v", "libx264", "-preset", "veryfast", "-crf", "20"] if inicio is not None \
        else ["-c:v", "copy"]
    if filtros:
        args += ["-af", ",".join(filtros), "-ar", str(TAXA)]
    args += ["-c:a", "libopus" if ext == ".webm" else "aac", "-b:a", cfg.bitrate_audio,
             "-shortest"]
    if ext in (".mp4", ".mov", ".m4v"):
        args += ["-movflags", "+faststart"]
    _rodar(args + [saida])


def processar(entrada, saida, cfg: Optional[Config] = None,
              progresso: Optional[Progresso] = None,
              inicio: Optional[float] = None, duracao: Optional[float] = None):
    """Remove o ruído de `entrada` e grava em `saida`. `inicio`/`duracao` geram um corte."""
    cfg = cfg or Config()
    if cfg.motor not in MOTORES:
        raise ValueError(f"Motor inválido: {cfg.motor}")
    progresso = progresso or (lambda f, m: None)
    if not os.path.isfile(entrada):
        raise FileNotFoundError(entrada)
    entrada, saida = os.path.abspath(entrada), os.path.abspath(saida)

    with tempfile.TemporaryDirectory(prefix="limpa_podcast_") as tmp:
        bruto = os.path.join(tmp, "1_original.wav")
        filtrado = os.path.join(tmp, "2_filtrado.wav")
        limpo = os.path.join(tmp, "3_limpo.wav")

        progresso(0.02, "Extraindo o áudio...")
        extrair_audio(entrada, bruto, inicio, duracao)
        if sf.info(bruto).frames < TAXA * 0.1:
            raise ValueError("Não há áudio nesse ponto do arquivo (o início passa do fim?).")

        ruido = None
        if cfg.trecho_ruido and inicio is not None and cfg.motor != "ia":
            # No corte o trecho de ruído pode ficar de fora: lê do arquivo inteiro.
            ini, fim = cfg.trecho_ruido
            perfil_wav = os.path.join(tmp, "perfil.wav")
            extrair_audio(entrada, perfil_wav, ini, fim - ini)
            ruido = _perfil_manual(perfil_wav, (0.0, fim - ini))
        filtrar_espectral(bruto, filtrado, cfg, progresso, ruido)

        if cfg.motor in ("ia", "ambos"):
            if cfg.cancelar.is_set():
                raise Cancelado()
            progresso(0.55, "Separando a voz do ruído com IA...")
            filtrar_ia(filtrado, limpo, cfg)
        else:
            limpo = filtrado

        if cfg.cancelar.is_set():
            raise Cancelado()
        progresso(0.85, "Gerando o arquivo final...")
        montar_saida(entrada, limpo, saida, cfg, inicio, duracao)
    progresso(1.0, "Pronto!")


def gerar_previa(entrada, pasta, cfg: Config, inicio: float, duracao: float = 20.0,
                 progresso: Optional[Progresso] = None):
    """Gera dois WAVs curtos (antes e depois) para comparar de ouvido."""
    antes = os.path.join(pasta, "previa_1_ANTES.wav")
    depois = os.path.join(pasta, "previa_2_DEPOIS.wav")
    extrair_audio(entrada, antes, inicio, duracao)
    processar(entrada, depois, cfg, progresso, inicio, duracao)
    return antes, depois


def _cli():
    import argparse
    p = argparse.ArgumentParser(description="Remove ruído de fundo de vídeos/podcasts.")
    p.add_argument("entrada")
    p.add_argument("saida")
    p.add_argument("--motor", choices=MOTORES, default="ia")
    p.add_argument("--intensidade", type=float, default=0.85, help="0 a 1")
    p.add_argument("--passa-alta", type=float, default=80.0, help="Hz; 0 desliga")
    p.add_argument("--sem-normalizar", action="store_true")
    p.add_argument("--ruido", nargs=2, type=float, metavar=("INICIO", "FIM"),
                   help="trecho (s) que contém só ruído, para o motor espectral")
    p.add_argument("--previa", type=float, metavar="INICIO",
                   help="processa só 20 s a partir deste ponto")
    a = p.parse_args()
    cfg = Config(
        motor=a.motor, intensidade=a.intensidade,
        passa_alta_hz=a.passa_alta or None, normalizar=not a.sem_normalizar,
        trecho_ruido=tuple(a.ruido) if a.ruido else None,
    )
    processar(a.entrada, a.saida, cfg, lambda f, m: print(f"[{f * 100:5.1f}%] {m}"),
              a.previa, 20.0 if a.previa is not None else None)


if __name__ == "__main__":
    _cli()
