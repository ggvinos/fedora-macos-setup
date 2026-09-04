#!/usr/bin/env python3
"""Configura o Rounded Window Corners Reborn: mantem canto arredondado em
janelas maximizadas/fullscreen (vem desativado por padrao), e nao pula apps
libadwaita/GTK4 como Nautilus e Configuracoes (que sem isso ficam com canto
reto quando encostados/maximizados)."""
from pathlib import Path

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib

SCHEMA_DIR = Path.home() / ".local/share/gnome-shell/extensions/rounded-window-corners@fxgn/schemas"

src = Gio.SettingsSchemaSource.new_from_directory(
    str(SCHEMA_DIR), Gio.SettingsSchemaSource.get_default(), False
)
schema = src.lookup("org.gnome.shell.extensions.rounded-window-corners-reborn", False)
s = Gio.Settings.new_full(schema, None, None)

current = s.get_value("global-rounded-corner-settings").unpack()
current["keepRoundedCorners"]["maximized"] = True
current["keepRoundedCorners"]["fullscreen"] = True

new_variant = GLib.Variant(
    "a{sv}",
    {
        "padding": GLib.Variant("a{su}", current["padding"]),
        "keepRoundedCorners": GLib.Variant("a{sb}", current["keepRoundedCorners"]),
        "borderRadius": GLib.Variant("u", current["borderRadius"]),
        "smoothing": GLib.Variant("u", current["smoothing"]),
        "borderColor": GLib.Variant("ad", current["borderColor"]),
        "enabled": GLib.Variant("b", current["enabled"]),
    },
)
s.set_value("global-rounded-corner-settings", new_variant)
s.set_boolean("skip-libadwaita-app", False)

print("Rounded Window Corners configurado: cantos mantidos em janelas maximizadas/fullscreen, inclusive apps GTK4.")
