#!/usr/bin/env python3
"""Configura o Blur my Shell: painel transparente (sem tingir de cor), blur
na gaveta de apps, no overview e na tela de bloqueio."""
import subprocess
from pathlib import Path

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio

SCHEMA_DIR = Path.home() / ".local/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas"


def settings_for(schema_id):
    src = Gio.SettingsSchemaSource.new_from_directory(
        str(SCHEMA_DIR), Gio.SettingsSchemaSource.get_default(), False
    )
    schema = src.lookup(schema_id, False)
    return Gio.Settings.new_full(schema, None, None)


panel = settings_for("org.gnome.shell.extensions.blur-my-shell.panel")
panel.set_boolean("blur", False)
panel.set_boolean("override-background", False)

overview = settings_for("org.gnome.shell.extensions.blur-my-shell.overview")
overview.set_boolean("blur", True)

applications = settings_for("org.gnome.shell.extensions.blur-my-shell.applications")
applications.set_boolean("blur", True)

lockscreen = settings_for("org.gnome.shell.extensions.blur-my-shell.lockscreen")
lockscreen.set_boolean("blur", True)

subprocess.run(["gnome-extensions", "disable", "blur-my-shell@aunetx"], check=False)
subprocess.run(["gnome-extensions", "enable", "blur-my-shell@aunetx"], check=False)

print("Blur my Shell configurado: painel transparente, blur no overview/gaveta/lockscreen.")
