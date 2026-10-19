@echo off
cd /d "%~dp0"
if not exist .venv (
    echo Preparando o ambiente na primeira execucao...
    python -m venv .venv || (echo Instale o Python 3.10+ em https://python.org marcando "Add to PATH". & pause & exit /b 1)
    .venv\Scripts\python -m pip install --upgrade pip
    .venv\Scripts\python -m pip install -r requirements.txt || (pause & exit /b 1)
)
start "" .venv\Scripts\pythonw app.py
