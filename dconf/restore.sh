#!/usr/bin/env bash
# Restaura atalhos, tema, favoritos do dock e configs de cada extensão
# a partir dos dumps dconf feitos no Fedora antigo.
#
# Rode DEPOIS de terminar o install.sh (etapas 1-7) e com as extensões
# extras já instaladas (ver ../EXTENSOES-EXTRAS.md), senão o dconf load
# vai gravar configs de extensões que o GNOME Shell ainda não conhece.
set -euo pipefail
cd "$(dirname "$0")"

echo "Restaurando configs via dconf..."
dconf load /org/gnome/desktop/wm/keybindings/        < wm-keybindings.ini
dconf load /org/gnome/settings-daemon/plugins/media-keys/ < media-keys.ini
dconf load /org/gnome/shell/keybindings/             < shell-keybindings.ini
dconf load /org/gnome/mutter/keybindings/            < mutter-keybindings.ini
dconf load /org/gnome/mutter/                        < mutter.ini
dconf load /org/gnome/desktop/wm/preferences/        < wm-preferences.ini
dconf load /org/gnome/desktop/interface/             < desktop-interface.ini
dconf load /org/gnome/shell/                         < shell.ini
dconf load /org/gnome/shell/extensions/              < shell-extensions.ini
dconf load /org/gnome/desktop/peripherals/           < peripherals.ini

echo "Pronto. Faça logout/login pra tudo (favoritos, tema, extensões) recarregar."
