#!/usr/bin/env bash
cd "$(dirname "$0")" || exit 1
if [ ! -d .venv ]; then
    echo "Preparando o ambiente na primeira execução..."
    python3 -m venv .venv || exit 1
    .venv/bin/python -m pip install --upgrade pip
    .venv/bin/python -m pip install -r requirements.txt || exit 1
fi
exec .venv/bin/python app.py
