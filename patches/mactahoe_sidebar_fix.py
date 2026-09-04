#!/usr/bin/env python3
"""
Corrige a barra lateral transparente demais do MacTahoe em apps GTK4
(Nautilus, Configuracoes): a regra generica '.navigation-sidebar' vem com
'background-color: transparent', o que so e seguro quando existe um
elemento pai opaco por baixo. Em apps onde esse painel e o container mais
externo, o resultado e ver o conteudo de outras janelas atras vazando
atraves da barra lateral.
"""
import sys
from pathlib import Path

real_path = Path.home() / ".config/gtk-4.0/gtk.css"
if real_path.is_symlink():
    real_path = real_path.resolve()

if not real_path.exists():
    print(f"Não achei {real_path}", file=sys.stderr)
    sys.exit(1)

content = real_path.read_text()

OLD = """.navigation-sidebar {
  background-color: transparent;
  padding: 8px;
}"""
NEW = """.navigation-sidebar {
  background-color: color-mix(in srgb, @window_bg_color 96%, transparent);
  padding: 8px;
}"""

if OLD not in content:
    print("Padrão original não encontrado (já corrigido, ou versão do tema mudou?)", file=sys.stderr)
    sys.exit(1)

real_path.write_text(content.replace(OLD, NEW))
print(f"Corrigido em {real_path}")
