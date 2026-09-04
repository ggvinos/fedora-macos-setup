#!/usr/bin/env python3
"""
Corrige a Dhruva: scroll sobre um icone de app com varias janelas abertas
deveria ciclar entre elas (toggle 'scroll-action-app'), mas a implementacao
original so funcionava em botoes especiais (pastas, lixeira), nao em apps
normais em execucao. PR com a correcao: github.com/NarkAgni/dhruva/pull/60

Se o PR ja tiver sido mergeado upstream, os textos originais nao vao mais
bater e o script simplesmente nao faz nada (sai com erro, o install.sh trata
isso como "ja corrigido, tudo bem").
"""
import sys
from pathlib import Path

install_path = Path(sys.argv[1])
scroll_manager = install_path / "src/core/ScrollManager.js"
dock_item_builder = install_path / "src/ui/dock/DockItemBuilder.js"

scroll_manager_content = scroll_manager.read_text()

OLD_SCROLL_MANAGER = """export default class ScrollManager {
    static setupDockScroll(dockActor, settings) {
        dockActor.connectObject('scroll-event', (actor, event) => {
            actor._lastIconClickTime = Date.now();

            if (!settings.get_boolean('scroll-action-dock')) return Clutter.EVENT_PROPAGATE;

            const dir = event.get_scroll_direction();
            const wm = global.workspace_manager;
            const activeIdx = wm.get_active_workspace_index();
            let nextIdx = activeIdx;

            if (dir === Clutter.ScrollDirection.UP) {
                nextIdx = Math.max(0, activeIdx - 1);
            } else if (dir === Clutter.ScrollDirection.DOWN) {
                nextIdx = Math.min(wm.get_n_workspaces() - 1, activeIdx + 1);
            }

            if (nextIdx !== activeIdx) {
                wm.get_workspace_by_index(nextIdx).activate(global.get_current_time());
                return Clutter.EVENT_STOP;
            }
            return Clutter.EVENT_PROPAGATE;
        }, dockActor);
    }

    static setupAppScroll(appButton, getWindowsFn, settings) {
        appButton.connectObject('scroll-event', (actor, event) => {
            const parent = actor.get_parent();
            const mainDockActor = parent ? parent.get_parent() : null;
            if (mainDockActor) mainDockActor._lastIconClickTime = Date.now();

            if (!settings.get_boolean('scroll-action-app')) return Clutter.EVENT_STOP;

            const dir = event.get_scroll_direction();
            const windows = getWindowsFn();

            if (!windows || windows.length === 0) return Clutter.EVENT_STOP;

            if (windows.length < 2) {
                const target = windows[0];
                target.unminimize();
                Main.activateWindow(target);
                return Clutter.EVENT_STOP;
            }

            const focusWin = global.display.get_focus_window();
            let idx = windows.indexOf(focusWin);
            if (idx === -1) idx = 0;

            let nextIdx = idx;
            if (dir === Clutter.ScrollDirection.UP) {
                nextIdx = (idx - 1 + windows.length) % windows.length;
            } else if (dir === Clutter.ScrollDirection.DOWN) {
                nextIdx = (idx + 1) % windows.length;
            }

            if (nextIdx !== idx) {
                const target = windows[nextIdx];
                target.unminimize();
                Main.activateWindow(target);
            }
            return Clutter.EVENT_STOP;
        }, appButton);
    }
}"""

NEW_SCROLL_MANAGER = """function cycleAppWindows(windows, dir) {
    if (!windows || windows.length === 0) return;

    if (windows.length < 2) {
        const target = windows[0];
        target.unminimize();
        Main.activateWindow(target);
        return;
    }

    const focusWin = global.display.get_focus_window();
    let idx = windows.indexOf(focusWin);
    if (idx === -1) idx = 0;

    let nextIdx = idx;
    if (dir === Clutter.ScrollDirection.UP) {
        nextIdx = (idx - 1 + windows.length) % windows.length;
    } else if (dir === Clutter.ScrollDirection.DOWN) {
        nextIdx = (idx + 1) % windows.length;
    }

    if (nextIdx !== idx) {
        const target = windows[nextIdx];
        target.unminimize();
        Main.activateWindow(target);
    }
}

export default class ScrollManager {
    static setupDockScroll(dockActor, settings) {
        dockActor.connectObject('scroll-event', (actor, event) => {
            actor._lastIconClickTime = Date.now();

            const dockUI = actor._dockUI;
            const hoveredBtn = dockUI ? dockUI._hoveredAppButton : null;
            const hoveredApp = hoveredBtn && hoveredBtn._delegate ? hoveredBtn._delegate.app : null;

            if (hoveredApp && settings.get_boolean('scroll-action-app')) {
                const windows = hoveredApp.get_windows();
                cycleAppWindows(windows, event.get_scroll_direction());
                return Clutter.EVENT_STOP;
            }

            if (!settings.get_boolean('scroll-action-dock')) return Clutter.EVENT_PROPAGATE;

            const dir = event.get_scroll_direction();
            const wm = global.workspace_manager;
            const activeIdx = wm.get_active_workspace_index();
            let nextIdx = activeIdx;

            if (dir === Clutter.ScrollDirection.UP) {
                nextIdx = Math.max(0, activeIdx - 1);
            } else if (dir === Clutter.ScrollDirection.DOWN) {
                nextIdx = Math.min(wm.get_n_workspaces() - 1, activeIdx + 1);
            }

            if (nextIdx !== activeIdx) {
                wm.get_workspace_by_index(nextIdx).activate(global.get_current_time());
                return Clutter.EVENT_STOP;
            }
            return Clutter.EVENT_PROPAGATE;
        }, dockActor);
    }

    static setupAppScroll(appButton, getWindowsFn, settings) {
        appButton.connectObject('scroll-event', (actor, event) => {
            const parent = actor.get_parent();
            const mainDockActor = parent ? parent.get_parent() : null;
            if (mainDockActor) mainDockActor._lastIconClickTime = Date.now();

            if (!settings.get_boolean('scroll-action-app')) return Clutter.EVENT_STOP;

            cycleAppWindows(getWindowsFn(), event.get_scroll_direction());
            return Clutter.EVENT_STOP;
        }, appButton);
    }
}"""

if OLD_SCROLL_MANAGER not in scroll_manager_content:
    print("Padrão original não encontrado em ScrollManager.js (já corrigido upstream?)", file=sys.stderr)
    sys.exit(1)

scroll_manager.write_text(scroll_manager_content.replace(OLD_SCROLL_MANAGER, NEW_SCROLL_MANAGER))

dock_item_builder_content = dock_item_builder.read_text()

if "import ScrollManager from '../../core/ScrollManager.js';" not in dock_item_builder_content:
    dock_item_builder_content = dock_item_builder_content.replace(
        "import { animateMinimize, animateRestore } from '../effects/WindowEffects.js';",
        "import { animateMinimize, animateRestore } from '../effects/WindowEffects.js';\n"
        "import ScrollManager from '../../core/ScrollManager.js';",
    )

OLD_HOVER = """    btn.connectObject('notify::hover', () => {
        if (dockUI.settings.get_boolean('hover-zoom')) return;

        const expanded = (isRunning && showIndicators) || btn.hover;"""
NEW_HOVER = """    btn.connectObject('notify::hover', () => {
        if (btn.hover) dockUI._hoveredAppButton = btn;
        else if (dockUI._hoveredAppButton === btn) dockUI._hoveredAppButton = null;

        if (dockUI.settings.get_boolean('hover-zoom')) return;

        const expanded = (isRunning && showIndicators) || btn.hover;"""

if OLD_HOVER not in dock_item_builder_content:
    print("Padrão original não encontrado em DockItemBuilder.js (já corrigido upstream?)", file=sys.stderr)
    sys.exit(1)

dock_item_builder_content = dock_item_builder_content.replace(OLD_HOVER, NEW_HOVER)

if "ScrollManager.setupAppScroll(btn, () => app.get_windows(), dockUI.settings);" not in dock_item_builder_content:
    dock_item_builder_content = dock_item_builder_content.replace(
        "    btn._activateCallback = (buttonNum, state = 0) => {",
        "    ScrollManager.setupAppScroll(btn, () => app.get_windows(), dockUI.settings);\n\n"
        "    btn._activateCallback = (buttonNum, state = 0) => {",
        1,
    )

dock_item_builder.write_text(dock_item_builder_content)

print("Patch de scroll aplicado com sucesso.")
