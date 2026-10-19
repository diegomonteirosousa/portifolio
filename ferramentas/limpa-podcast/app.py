"""
Limpa Podcast — interface desktop (Tkinter) para remover ruído de fundo
de vídeos de podcast preservando a voz.

Execute:  python app.py
"""

import os
import queue
import subprocess
import sys
import tempfile
import threading
import tkinter as tk
from tkinter import filedialog, messagebox, ttk

import nucleo

TIPOS_ENTRADA = [
    ("Vídeos e áudios", "*.mp4 *.mov *.mkv *.avi *.webm *.m4v *.mp3 *.wav *.m4a *.flac"),
    ("Todos os arquivos", "*.*"),
]
TIPOS_SAIDA = [
    ("Vídeo MP4", "*.mp4"), ("Vídeo MOV", "*.mov"), ("Vídeo MKV", "*.mkv"),
    ("Áudio WAV", "*.wav"), ("Áudio MP3", "*.mp3"),
]


def abrir_no_sistema(caminho):
    if sys.platform == "win32":
        os.startfile(caminho)
    elif sys.platform == "darwin":
        subprocess.Popen(["open", caminho])
    else:
        subprocess.Popen(["xdg-open", caminho])


def ler_tempo(texto):
    """Aceita '75', '1:15' ou '00:01:15' e devolve segundos."""
    texto = texto.strip().replace(",", ".")
    if not texto:
        return None
    segundos = 0.0
    for parte in texto.split(":"):
        segundos = segundos * 60 + float(parte)
    return segundos


class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Limpa Podcast — remoção de ruído de fundo")
        self.minsize(620, 560)
        self.fila = queue.Queue()
        self.cfg_atual = None
        self.pasta_previa = tempfile.mkdtemp(prefix="limpa_podcast_previa_")

        self.var_entrada = tk.StringVar()
        self.var_saida = tk.StringVar()
        self.var_motor = tk.StringVar(value="ia")
        self.var_intensidade = tk.DoubleVar(value=85)
        self.var_passa_alta = tk.BooleanVar(value=True)
        self.var_passa_alta_hz = tk.StringVar(value="80")
        self.var_normalizar = tk.BooleanVar(value=True)
        self.var_usar_trecho = tk.BooleanVar(value=False)
        self.var_ruido_ini = tk.StringVar(value="0:00")
        self.var_ruido_fim = tk.StringVar(value="0:03")
        self.var_previa_ini = tk.StringVar(value="1:00")
        self.var_status = tk.StringVar(value="Escolha um vídeo para começar.")

        self._montar()
        self._atualizar_trecho()
        self.after(100, self._ler_fila)

    # ------------------------------------------------------------ interface
    def _montar(self):
        raiz = ttk.Frame(self, padding=14)
        raiz.pack(fill="both", expand=True)
        raiz.columnconfigure(1, weight=1)

        ttk.Label(raiz, text="Vídeo original:").grid(row=0, column=0, sticky="w")
        ttk.Entry(raiz, textvariable=self.var_entrada).grid(row=0, column=1, sticky="ew", padx=6)
        ttk.Button(raiz, text="Abrir...", command=self._escolher_entrada).grid(row=0, column=2)

        ttk.Label(raiz, text="Salvar como:").grid(row=1, column=0, sticky="w", pady=(6, 0))
        ttk.Entry(raiz, textvariable=self.var_saida).grid(row=1, column=1, sticky="ew", padx=6, pady=(6, 0))
        ttk.Button(raiz, text="Escolher...", command=self._escolher_saida).grid(row=1, column=2, pady=(6, 0))

        # Motor
        modo = ttk.LabelFrame(raiz, text="Método de limpeza", padding=10)
        modo.grid(row=2, column=0, columnspan=3, sticky="ew", pady=(14, 0))
        for valor, texto in (
            ("ia", "IA de voz — recomendado para lugar aberto (vento, carros, pessoas, pássaros)"),
            ("espectral", "Espectral — para ruído constante (chiado, ar-condicionado, gerador)"),
            ("ambos", "Espectral + IA — limpeza máxima para ruído muito forte"),
        ):
            ttk.Radiobutton(modo, variable=self.var_motor, value=valor, text=texto,
                            command=self._atualizar_trecho).pack(anchor="w")

        trecho = ttk.Frame(modo)
        trecho.pack(anchor="w", pady=(8, 0))
        self.chk_trecho = ttk.Checkbutton(
            trecho, variable=self.var_usar_trecho, command=self._atualizar_trecho,
            text="Espectral: usar um trecho só com ruído (sem fala) como referência: de",
        )
        self.chk_trecho.pack(side="left")
        self.ent_ruido_ini = ttk.Entry(trecho, textvariable=self.var_ruido_ini, width=7)
        self.ent_ruido_ini.pack(side="left", padx=4)
        ttk.Label(trecho, text="até").pack(side="left")
        self.ent_ruido_fim = ttk.Entry(trecho, textvariable=self.var_ruido_fim, width=7)
        self.ent_ruido_fim.pack(side="left", padx=4)

        # Ajustes
        ajustes = ttk.LabelFrame(raiz, text="Ajustes", padding=10)
        ajustes.grid(row=3, column=0, columnspan=3, sticky="ew", pady=(10, 0))
        ajustes.columnconfigure(1, weight=1)

        ttk.Label(ajustes, text="Intensidade da limpeza:").grid(row=0, column=0, sticky="w")
        ttk.Scale(ajustes, from_=20, to=100, variable=self.var_intensidade,
                  command=lambda _: self._rotulo_intensidade()).grid(row=0, column=1, sticky="ew", padx=6)
        self.lbl_intensidade = ttk.Label(ajustes, width=5)
        self.lbl_intensidade.grid(row=0, column=2)
        self._rotulo_intensidade()
        ttk.Label(
            ajustes, foreground="#666",
            text="Se a voz ficar \"metálica\" ou abafada, diminua. 70–90% costuma ser o ideal.",
        ).grid(row=1, column=0, columnspan=3, sticky="w")

        linha = ttk.Frame(ajustes)
        linha.grid(row=2, column=0, columnspan=3, sticky="w", pady=(8, 0))
        ttk.Checkbutton(linha, variable=self.var_passa_alta,
                        text="Cortar graves abaixo de").pack(side="left")
        ttk.Entry(linha, textvariable=self.var_passa_alta_hz, width=5).pack(side="left", padx=4)
        ttk.Label(linha, text="Hz (vento e ronco de trânsito)").pack(side="left")

        ttk.Checkbutton(
            ajustes, variable=self.var_normalizar,
            text="Normalizar volume para padrão de podcast (-16 LUFS)",
        ).grid(row=3, column=0, columnspan=3, sticky="w", pady=(4, 0))

        # Prévia
        previa = ttk.LabelFrame(raiz, text="Ouvir antes de processar tudo", padding=10)
        previa.grid(row=4, column=0, columnspan=3, sticky="ew", pady=(10, 0))
        ttk.Label(previa, text="Gerar 20 s a partir de").pack(side="left")
        ttk.Entry(previa, textvariable=self.var_previa_ini, width=7).pack(side="left", padx=4)
        self.btn_previa = ttk.Button(previa, text="Gerar prévia (antes/depois)", command=self._previa)
        self.btn_previa.pack(side="left", padx=8)

        # Ações
        acoes = ttk.Frame(raiz)
        acoes.grid(row=5, column=0, columnspan=3, sticky="ew", pady=(16, 0))
        self.btn_processar = ttk.Button(acoes, text="Remover ruído do vídeo inteiro",
                                        command=self._processar)
        self.btn_processar.pack(side="left")
        self.btn_cancelar = ttk.Button(acoes, text="Cancelar", command=self._cancelar,
                                       state="disabled")
        self.btn_cancelar.pack(side="left", padx=8)

        self.barra = ttk.Progressbar(raiz, maximum=100)
        self.barra.grid(row=6, column=0, columnspan=3, sticky="ew", pady=(12, 4))
        ttk.Label(raiz, textvariable=self.var_status).grid(row=7, column=0, columnspan=3, sticky="w")

    def _rotulo_intensidade(self):
        self.lbl_intensidade.config(text=f"{self.var_intensidade.get():.0f}%")

    def _atualizar_trecho(self):
        espectral = self.var_motor.get() != "ia"
        self.chk_trecho.config(state="normal" if espectral else "disabled")
        estado = "normal" if espectral and self.var_usar_trecho.get() else "disabled"
        self.ent_ruido_ini.config(state=estado)
        self.ent_ruido_fim.config(state=estado)

    def _escolher_entrada(self):
        caminho = filedialog.askopenfilename(title="Escolha o vídeo", filetypes=TIPOS_ENTRADA)
        if not caminho:
            return
        self.var_entrada.set(caminho)
        base, ext = os.path.splitext(caminho)
        if ext.lower() in (".avi", ".webm"):
            ext = ".mp4"
        self.var_saida.set(f"{base}_sem_ruido{ext}")
        self.var_status.set("Dica: gere uma prévia para ajustar a intensidade.")

    def _escolher_saida(self):
        inicial = self.var_saida.get()
        caminho = filedialog.asksaveasfilename(
            title="Salvar vídeo limpo como", filetypes=TIPOS_SAIDA, defaultextension=".mp4",
            initialdir=os.path.dirname(inicial) or None,
            initialfile=os.path.basename(inicial) or None,
        )
        if caminho:
            self.var_saida.set(caminho)

    # ------------------------------------------------------------ execução
    def _ler_config(self):
        entrada = self.var_entrada.get().strip()
        if not entrada or not os.path.isfile(entrada):
            raise ValueError("Escolha um vídeo válido.")
        passa_alta = None
        if self.var_passa_alta.get():
            passa_alta = float(self.var_passa_alta_hz.get().replace(",", "."))
            if not 20 <= passa_alta <= 300:
                raise ValueError("O corte de graves deve ficar entre 20 e 300 Hz.")
        trecho = None
        if self.var_usar_trecho.get() and self.var_motor.get() != "ia":
            ini, fim = ler_tempo(self.var_ruido_ini.get()), ler_tempo(self.var_ruido_fim.get())
            if ini is None or fim is None or fim - ini < 0.5:
                raise ValueError("O trecho de ruído precisa ter pelo menos 0,5 segundo.")
            trecho = (ini, fim)
        return entrada, nucleo.Config(
            motor=self.var_motor.get(),
            intensidade=self.var_intensidade.get() / 100,
            passa_alta_hz=passa_alta,
            normalizar=self.var_normalizar.get(),
            trecho_ruido=trecho,
        )

    def _iniciar(self, tarefa):
        self.btn_processar.config(state="disabled")
        self.btn_previa.config(state="disabled")
        self.btn_cancelar.config(state="normal")
        self.barra["value"] = 0

        def progresso(fracao, msg):
            self.fila.put(("progresso", fracao, msg))

        def rodar():
            try:
                self.fila.put(("ok", tarefa(progresso)))
            except nucleo.Cancelado:
                self.fila.put(("cancelado",))
            except Exception as erro:
                self.fila.put(("erro", str(erro)))

        threading.Thread(target=rodar, daemon=True).start()

    def _previa(self):
        try:
            entrada, cfg = self._ler_config()
            inicio = ler_tempo(self.var_previa_ini.get()) or 0.0
        except ValueError as erro:
            messagebox.showerror("Limpa Podcast", str(erro))
            return
        self.cfg_atual = cfg

        def tarefa(progresso):
            antes, depois = nucleo.gerar_previa(entrada, self.pasta_previa, cfg, inicio, 20, progresso)
            return ("previa", antes, depois)

        self._iniciar(tarefa)

    def _processar(self):
        try:
            entrada, cfg = self._ler_config()
        except ValueError as erro:
            messagebox.showerror("Limpa Podcast", str(erro))
            return
        saida = self.var_saida.get().strip()
        if not saida:
            messagebox.showerror("Limpa Podcast", "Escolha onde salvar o resultado.")
            return
        if os.path.abspath(saida) == os.path.abspath(entrada):
            messagebox.showerror("Limpa Podcast", "O arquivo de saída não pode ser o original.")
            return
        if os.path.exists(saida) and not messagebox.askyesno(
                "Limpa Podcast", f"{os.path.basename(saida)} já existe. Substituir?"):
            return
        self.cfg_atual = cfg

        def tarefa(progresso):
            nucleo.processar(entrada, saida, cfg, progresso)
            return ("final", saida)

        self._iniciar(tarefa)

    def _cancelar(self):
        if self.cfg_atual:
            self.cfg_atual.cancelar.set()
            self.var_status.set("Cancelando...")

    def _finalizar(self):
        self.btn_processar.config(state="normal")
        self.btn_previa.config(state="normal")
        self.btn_cancelar.config(state="disabled")

    def _ler_fila(self):
        try:
            while True:
                item = self.fila.get_nowait()
                tipo = item[0]
                if tipo == "progresso":
                    self.barra["value"] = item[1] * 100
                    self.var_status.set(item[2])
                elif tipo == "ok":
                    self._finalizar()
                    self.barra["value"] = 100
                    resultado = item[1]
                    if resultado[0] == "previa":
                        self.var_status.set("Prévia pronta: compare ANTES e DEPOIS.")
                        abrir_no_sistema(os.path.dirname(resultado[1]))
                    else:
                        self.var_status.set(f"Concluído: {resultado[1]}")
                        if messagebox.askyesno("Limpa Podcast",
                                               "Vídeo limpo salvo! Deseja abrir a pasta?"):
                            abrir_no_sistema(os.path.dirname(os.path.abspath(resultado[1])))
                elif tipo == "cancelado":
                    self._finalizar()
                    self.barra["value"] = 0
                    self.var_status.set("Cancelado.")
                elif tipo == "erro":
                    self._finalizar()
                    self.var_status.set("Ocorreu um erro.")
                    messagebox.showerror("Limpa Podcast", item[1])
        except queue.Empty:
            pass
        self.after(100, self._ler_fila)


if __name__ == "__main__":
    App().mainloop()
