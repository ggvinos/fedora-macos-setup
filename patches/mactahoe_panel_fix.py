#!/usr/bin/env python3
"""
Deixa o painel superior do MacTahoe 100% transparente, sem as "capsulas"
(fundo em pilula solida atras do relogio, do Activities, dos icones da
bandeja), pra ficar igual ao menu bar do macOS: so texto/icones brancos
direto sobre o fundo, sem nenhum retangulo/pilula por tras.

Tambem deixa o hover mais claro (branco translucido) em vez do cinza escuro
padrao do tema, que destoava muito num painel transparente.
"""
import sys
from pathlib import Path

path = Path(sys.argv[1])
content = path.read_text()
replacements = [
    (
        "#panel .panel-button {\n"
        "  -natural-hpadding: 12px;\n"
        "  -minimum-hpadding: 12px;\n"
        "  color: white;\n"
        "  transition-duration: 150ms;\n"
        "  border: 6px solid transparent !important;\n"
        "  border-radius: 9999px;\n"
        "  box-shadow: inset 0 0 0 1000px #2a2a2a;\n"
        "}",
        "#panel .panel-button {\n"
        "  -natural-hpadding: 12px;\n"
        "  -minimum-hpadding: 12px;\n"
        "  color: white;\n"
        "  transition-duration: 150ms;\n"
        "  border: 6px solid transparent !important;\n"
        "  border-radius: 9999px;\n"
        "  box-shadow: none;\n"
        "  background-color: transparent;\n"
        "}",
    ),
    (
        "#panel .panel-button:hover {\n"
        "  color: white;\n"
        "  background-color: transparent;\n"
        "  box-shadow: inset 0 0 0 1000px #4a4a4a;\n"
        "}",
        "#panel .panel-button:hover {\n"
        "  color: white;\n"
        "  background-color: transparent;\n"
        "  box-shadow: inset 0 0 0 1000px rgba(255, 255, 255, 0.18);\n"
        "}",
    ),
    (
        "#panel .panel-button.clock-display .clock {\n"
        "  border-radius: 9999px;\n"
        "  background-color: transparent;\n"
        "  padding: 0 16px !important;\n"
        "  margin: 0 !important;\n"
        "  border: 6px solid transparent !important;\n"
        "  box-shadow: inset 0 0 0 1000px #2a2a2a;\n"
        "}",
        "#panel .panel-button.clock-display .clock {\n"
        "  border-radius: 9999px;\n"
        "  background-color: transparent;\n"
        "  padding: 0 16px !important;\n"
        "  margin: 0 !important;\n"
        "  border: 6px solid transparent !important;\n"
        "  box-shadow: none;\n"
        "}",
    ),
    (
        "#panel .panel-button:hover.clock-display .clock {\n"
        "  background-color: transparent;\n"
        "  box-shadow: inset 0 0 0 1000px #4a4a4a;\n"
        "}",
        "#panel .panel-button:hover.clock-display .clock {\n"
        "  background-color: transparent;\n"
        "  box-shadow: inset 0 0 0 1000px rgba(255, 255, 255, 0.18);\n"
        "}",
    ),
    (
        "#panel .panel-button:active, #panel .panel-button:overview, #panel .panel-button:focus, #panel .panel-button:checked {\n"
        "  color: white;\n"
        "  background-color: transparent;\n"
        "  box-shadow: inset 0 0 0 1000px #666666;\n"
        "}",
        "#panel .panel-button:active, #panel .panel-button:overview, #panel .panel-button:focus, #panel .panel-button:checked {\n"
        "  color: white;\n"
        "  background-color: transparent;\n"
        "  box-shadow: inset 0 0 0 1000px rgba(255, 255, 255, 0.28);\n"
        "}",
    ),
    (
        "#panel .panel-button:active.clock-display .clock, #panel .panel-button:overview.clock-display .clock, #panel .panel-button:focus.clock-display .clock, #panel .panel-button:checked.clock-display .clock {\n"
        "  background-color: transparent;\n"
        "  box-shadow: inset 0 0 0 1000px #666666;\n"
        "}",
        "#panel .panel-button:active.clock-display .clock, #panel .panel-button:overview.clock-display .clock, #panel .panel-button:focus.clock-display .clock, #panel .panel-button:checked.clock-display .clock {\n"
        "  background-color: transparent;\n"
        "  box-shadow: inset 0 0 0 1000px rgba(255, 255, 255, 0.28);\n"
        "}",
    ),
]

applied = 0
for old, new in replacements:
    if old in content:
        content = content.replace(old, new)
        applied += 1

path.write_text(content)
print(f"{applied}/{len(replacements)} regras do painel corrigidas em {path}")
if applied == 0:
    sys.exit(1)
