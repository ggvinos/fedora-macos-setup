#!/usr/bin/env bash
#
# fedora-macos-setup — deixa o Fedora + GNOME com cara de macOS (estilo Tahoe)
# Dock com magnificação real, tema MacTahoe, blur, cantos arredondados, launcher
# estilo Spotlight, painel transparente sem "cápsulas".
#
# Uso:
#   ./install.sh            roda a próxima etapa pendente
#   ./install.sh status     mostra o progresso
#   ./install.sh step N     roda uma etapa específica de novo
#   ./install.sh reset      zera o progresso (não desfaz nada já instalado)
#
# O script é dividido em etapas porque duas delas exigem logout/login pra
# funcionar (limitação real do GNOME Shell: extensões novas só são
# reconhecidas depois de reiniciar a sessão). Rode o script, siga a
# instrução que aparecer no final de cada etapa, e rode de novo depois.

set -euo pipefail

STATE_DIR="$HOME/.cache/fedora-macos-setup"
STATE_FILE="$STATE_DIR/state"
WORK_DIR="$HOME/.cache/fedora-macos-setup/src"
mkdir -p "$STATE_DIR" "$WORK_DIR"

# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------

c_reset='\033[0m'
c_bold='\033[1m'
c_green='\033[1;32m'
c_yellow='\033[1;33m'
c_red='\033[1;31m'
c_cyan='\033[1;36m'

log()  { echo -e "${c_cyan}==>${c_reset} $*"; }
ok()   { echo -e "${c_green}[ok]${c_reset} $*"; }
warn() { echo -e "${c_yellow}[atenção]${c_reset} $*"; }
err()  { echo -e "${c_red}[erro]${c_reset} $*" >&2; }
pause_for() {
    echo
    echo -e "${c_bold}${c_yellow}>>> $* <<<${c_reset}"
    echo "Depois de fazer isso, rode o script de novo: ./install.sh"
    echo
}

require_fedora() {
    if ! grep -qi fedora /etc/os-release 2>/dev/null; then
        err "Esse script foi feito pra Fedora + GNOME. Não continuar em outra distro."
        exit 1
    fi
}

get_last_step() {
    [ -f "$STATE_FILE" ] && cat "$STATE_FILE" || echo 0
}

set_last_step() {
    echo "$1" > "$STATE_FILE"
}

gnome_shell_version() {
    gnome-shell --version | grep -oP '\d+' | head -1
}

# Baixa e instala uma extensão publicada em extensions.gnome.org (EGO) direto
# via API, compatível com a versão do GNOME Shell instalada.
install_ego_extension() {
    local pk="$1" uuid="$2" name="$3"
    if gnome-extensions list | grep -qx "$uuid"; then
        ok "$name já está instalada."
        return 0
    fi
    log "Baixando $name (extensions.gnome.org, id $pk)..."
    local shell_ver
    shell_ver="$(gnome_shell_version)"
    local info_url="https://extensions.gnome.org/extension-info/?pk=${pk}&shell_version=${shell_ver}"
    local download_path
    download_path="$(curl -sL "$info_url" | python3 -c "import sys,json; print(json.load(sys.stdin)['download_url'])" 2>/dev/null || true)"
    if [ -z "$download_path" ]; then
        warn "Não achei uma versão de $name compatível com GNOME Shell $shell_ver via API."
        warn "Instala manualmente pelo Extension Manager ou https://extensions.gnome.org/extension/${pk}/"
        return 1
    fi
    local zip_path="$WORK_DIR/${uuid}.shell-extension.zip"
    curl -sL -o "$zip_path" "https://extensions.gnome.org${download_path}"
    gnome-extensions install -f "$zip_path"
    ok "$name instalada."
}

# ---------------------------------------------------------------------------
# Etapa 1 — dependências de sistema
# ---------------------------------------------------------------------------

step_1_dependencies() {
    log "Etapa 1: instalando dependências de sistema (pede senha de sudo)"
    sudo dnf install -y \
        git make gcc sassc glib2-devel optipng inkscape \
        npm nodejs \
        gnome-shell-extension-user-theme \
        ulauncher
    flatpak install -y flathub com.mattjakeman.ExtensionManager
    ok "Dependências instaladas."
}

# ---------------------------------------------------------------------------
# Etapa 2 — Dock (Dhruva)
# ---------------------------------------------------------------------------

step_2_dhruva_dock() {
    log "Etapa 2: instalando a dock Dhruva"
    local uuid="dhruva@narkagni"
    local install_path="$HOME/.local/share/gnome-shell/extensions/$uuid"
    local src="$WORK_DIR/dhruva"

    if [ -d "$install_path" ]; then
        ok "Dhruva já está instalada."
    else
        rm -rf "$src"
        git clone --depth 1 https://github.com/NarkAgni/dhruva.git "$src"
        (
            cd "$src"
            glib-compile-schemas schemas
        )
        rm -rf "$install_path"
        mkdir -p "$install_path"
        cp "$src"/extension.js "$src"/prefs.js "$src"/stylesheet.css "$src"/metadata.json "$install_path"/
        cp -r "$src"/icons "$install_path"/
        cp -r "$src"/schemas "$install_path"/
        mkdir -p "$install_path/src"
        cp -r "$src"/src/core "$src"/src/prefs "$src"/src/ui "$install_path/src/"
        ok "Dhruva copiada pra pasta de extensões."

        log "Aplicando correção de scroll (cicla janelas do app em execução ao rolar sobre o ícone)"
        log "Isso é um bug conhecido da extensão original, corrigido em https://github.com/NarkAgni/dhruva/pull/60"
        python3 "$(dirname "$0")/patches/dhruva_scroll_fix.py" "$install_path" || \
            warn "Patch de scroll não aplicado (provavelmente o PR já foi mergeado upstream, tudo bem)."
    fi

    if gnome-extensions list | grep -qx "$uuid"; then
        gnome-extensions disable dash-to-dock@micxgx.gmail.com 2>/dev/null || true
        gnome-extensions enable "$uuid"
        ok "Dhruva ativada, Dash to Dock desativada."
    else
        set_last_step 2
        pause_for "Faça logout e login (extensão nova só é reconhecida depois disso)"
        exit 0
    fi
}

# ---------------------------------------------------------------------------
# Etapa 3 — Tema visual MacTahoe (ícones, cursor, GTK/Shell)
# ---------------------------------------------------------------------------

step_3_theme() {
    log "Etapa 3: instalando tema visual MacTahoe (ícones, cursor, GTK/Shell)"

    if [ ! -d "$HOME/.local/share/icons/WhiteSur-cursors" ]; then
        git clone --depth 1 https://github.com/vinceliuice/WhiteSur-cursors.git "$WORK_DIR/WhiteSur-cursors"
        (cd "$WORK_DIR/WhiteSur-cursors" && ./install.sh)
    fi

    git clone --depth 1 https://github.com/vinceliuice/MacTahoe-icon-theme.git "$WORK_DIR/MacTahoe-icon-theme" 2>/dev/null || true
    if [ ! -d "$HOME/.local/share/icons/MacTahoe" ]; then
        (cd "$WORK_DIR/MacTahoe-icon-theme" && ./install.sh)
    fi

    git clone --depth 1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git "$WORK_DIR/MacTahoe-gtk-theme" 2>/dev/null || true
    if [ ! -d "$HOME/.themes/MacTahoe-Dark-solid" ]; then
        (
            cd "$WORK_DIR/MacTahoe-gtk-theme"
            # -o solid é importante: a variante "-b" (blur) deixa barras laterais
            # de apps (Nautilus, Configurações) transparentes contando com um
            # blur-atrás-da-janela que o Mutter não faz pra apps comuns no
            # Wayland. Resultado: conteúdo de outras janelas vazando através
            # da barra lateral. "solid" evita isso.
            ./install.sh -l -o solid -c dark --round
        )
    fi

    gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme 'MacTahoe'
    gsettings set org.gnome.desktop.interface cursor-theme 'WhiteSur-cursors'
    gsettings set org.gnome.desktop.interface gtk-theme 'MacTahoe-Dark-solid'
    gsettings set org.gnome.shell.extensions.user-theme name 'MacTahoe-Dark-solid'

    log "Corrigindo barra lateral transparente demais no Nautilus/Configurações"
    python3 "$(dirname "$0")/patches/mactahoe_sidebar_fix.py" || true

    log "Deixando o painel superior 100% transparente, sem 'cápsulas' atrás dos ícones"
    python3 "$(dirname "$0")/patches/mactahoe_panel_fix.py" "$HOME/.themes/MacTahoe-Dark-solid/gnome-shell/gnome-shell.css" || true

    gsettings set org.gnome.shell.extensions.user-theme name ''
    gsettings set org.gnome.shell.extensions.user-theme name 'MacTahoe-Dark-solid'

    ok "Tema aplicado. Feche e reabra apps GTK4 abertos (Nautilus, Configurações) pra pegar o CSS novo."

    pause_for "Rode com sudo (pede senha, precisa ser feito manualmente): cd $WORK_DIR/MacTahoe-gtk-theme && sudo bash tweaks.sh -g   (aplica o tema na tela de login/bloqueio)"
}

# ---------------------------------------------------------------------------
# Etapa 4 — Fonte Inter
# ---------------------------------------------------------------------------

step_4_font() {
    log "Etapa 4: instalando a fonte Inter (clone livre da SF Pro)"
    if [ ! -f "$HOME/.local/share/fonts/Inter/InterVariable.ttf" ]; then
        curl -sL -o "$WORK_DIR/Inter.zip" "https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip"
        mkdir -p "$WORK_DIR/Inter-extract"
        unzip -o -q "$WORK_DIR/Inter.zip" -d "$WORK_DIR/Inter-extract"
        mkdir -p "$HOME/.local/share/fonts/Inter"
        cp "$WORK_DIR/Inter-extract/InterVariable.ttf" "$WORK_DIR/Inter-extract/InterVariable-Italic.ttf" "$HOME/.local/share/fonts/Inter/"
        fc-cache -f "$HOME/.local/share/fonts/Inter"
    fi
    gsettings set org.gnome.desktop.interface font-name 'Inter Variable 11'
    gsettings set org.gnome.desktop.interface document-font-name 'Inter Variable 11'
    gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Inter Variable Bold 11'
    ok "Fonte Inter aplicada."
}

# ---------------------------------------------------------------------------
# Etapa 5 — Blur my Shell + Rounded Window Corners (instalação dos arquivos)
# ---------------------------------------------------------------------------

step_5_extensions_install() {
    log "Etapa 5: instalando Blur my Shell e Rounded Window Corners Reborn"

    install_ego_extension 3193 "blur-my-shell@aunetx" "Blur my Shell" || true

    local rwc_uuid="rounded-window-corners@fxgn"
    local rwc_path="$HOME/.local/share/gnome-shell/extensions/$rwc_uuid"
    if [ ! -d "$rwc_path" ]; then
        local src="$WORK_DIR/rounded-window-corners"
        rm -rf "$src"
        git clone https://github.com/flexagoon/rounded-window-corners.git "$src"
        (
            cd "$src"
            # O branch main mais recente parou de declarar suporte ao GNOME 49
            # (só declara 50) porque removeram código legado de X11 — isso não
            # afeta quem usa só Wayland. Uso o último commit que ainda
            # declarava suporte aos dois.
            local shell_major
            shell_major="$(gnome_shell_version)"
            if [ "$shell_major" = "49" ]; then
                git checkout 0543f16 -- .
            fi
            npm install
            npx tsc --outDir ./_build
            # Em alguns commits o tsc gera a saída dentro de _build/src/ em
            # vez de _build/ direto. Achata se necessário.
            if [ -d "./_build/src" ]; then
                cp -r ./_build/src/* ./_build/
                rm -rf ./_build/src
            fi
            cp -r ./resources/* ./_build/
            find src -type f ! -name "*.ts" | while read -r file; do
                rel="${file#src/}"
                mkdir -p "./_build/$(dirname "$rel")"
                cp "$file" "./_build/$rel"
            done
            glib-compile-schemas ./_build/schemas
        )
        rm -rf "$rwc_path"
        cp -r "$src/_build" "$rwc_path"
    fi
    ok "Arquivos instalados."

    if gnome-extensions list | grep -qx "blur-my-shell@aunetx" && gnome-extensions list | grep -qx "rounded-window-corners@fxgn"; then
        gnome-extensions enable blur-my-shell@aunetx
        gnome-extensions enable rounded-window-corners@fxgn
        ok "Extensões ativadas."
    else
        set_last_step 5
        pause_for "Faça logout e login (extensões novas só são reconhecidas depois disso)"
        exit 0
    fi
}

# ---------------------------------------------------------------------------
# Etapa 6 — configuração fina do Blur my Shell e Rounded Window Corners
# ---------------------------------------------------------------------------

step_6_configure_extensions() {
    log "Etapa 6: configurando Blur my Shell e Rounded Window Corners"

    python3 "$(dirname "$0")/patches/configure_blur_my_shell.py" || \
        warn "Não consegui configurar o Blur my Shell automaticamente, ajusta pela UI dele."

    python3 "$(dirname "$0")/patches/configure_rounded_corners.py" || \
        warn "Não consegui configurar o Rounded Window Corners automaticamente, ajusta pela UI dele."

    ok "Configuração aplicada. Maximiza uma janela pra conferir os cantos arredondados."
}

# ---------------------------------------------------------------------------
# Etapa 7 — ULauncher (launcher estilo Spotlight)
# ---------------------------------------------------------------------------

step_7_ulauncher() {
    log "Etapa 7: configurando o ULauncher (estilo Spotlight)"

    mkdir -p "$HOME/.config/autostart"
    cp /usr/share/applications/ulauncher.desktop "$HOME/.config/autostart/ulauncher.desktop"
    # Sem forçar GDK_BACKEND=x11: com X11 forçado a transparência do tema não
    # funciona (fica um fundo branco sólido, sem erro nenhum).
    sed -i 's/^Exec=.*/Exec=\/usr\/bin\/ulauncher --hide-window/' "$HOME/.config/autostart/ulauncher.desktop"
    echo "X-GNOME-Autostart-enabled=true" >> "$HOME/.config/autostart/ulauncher.desktop"

    mkdir -p "$HOME/.config/ulauncher/user-themes"
    if [ ! -d "$HOME/.config/ulauncher/user-themes/ulauncher-theme-trans-dark" ]; then
        git clone --depth 1 https://github.com/oriewancu/ulauncher-theme-trans.git "$WORK_DIR/ulauncher-theme-trans"
        bash "$WORK_DIR/ulauncher-theme-trans/install.sh"
    fi

    pkill -f "ulauncher --hide-window" 2>/dev/null || true
    sleep 1
    # Roda uma vez pra gerar o settings.json antes de editar.
    nohup /usr/bin/ulauncher --hide-window > /dev/null 2>&1 &
    disown
    sleep 2
    pkill -f "python3.*ulauncher" 2>/dev/null || true
    sleep 1

    python3 - "$HOME/.config/ulauncher/settings.json" <<'PYEOF'
import json, sys
path = sys.argv[1]
with open(path) as f:
    data = json.load(f)
data['hotkey-show-app'] = '<Super>space'
data['theme-name'] = 'ulauncher-theme-trans-dark'
with open(path, 'w') as f:
    json.dump(data, f, indent=4)
PYEOF

    # Super+Espaço já é usado pelo GNOME pra trocar layout de teclado.
    gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['XF86Keyboard']"

    nohup /usr/bin/ulauncher --hide-window > /dev/null 2>&1 &
    disown

    ok "ULauncher configurado. Testa com Super+Espaço."
}

# ---------------------------------------------------------------------------
# Orquestração
# ---------------------------------------------------------------------------

STEPS=(
    step_1_dependencies
    step_2_dhruva_dock
    step_3_theme
    step_4_font
    step_5_extensions_install
    step_6_configure_extensions
    step_7_ulauncher
)

cmd="${1:-run}"

case "$cmd" in
    status)
        echo "Última etapa concluída: $(get_last_step) de ${#STEPS[@]}"
        ;;
    reset)
        rm -f "$STATE_FILE"
        echo "Progresso zerado (nada foi desinstalado)."
        ;;
    step)
        n="${2:?informe o número da etapa}"
        require_fedora
        "${STEPS[$((n-1))]}"
        [ "$n" -gt "$(get_last_step)" ] && set_last_step "$n"
        ;;
    run|"")
        require_fedora
        last="$(get_last_step)"
        next=$((last + 1))
        if [ "$next" -gt "${#STEPS[@]}" ]; then
            echo -e "${c_green}${c_bold}Tudo pronto! Todas as ${#STEPS[@]} etapas já foram concluídas.${c_reset}"
            exit 0
        fi
        log "Rodando etapa $next de ${#STEPS[@]}"
        "${STEPS[$((next-1))]}"
        set_last_step "$next"
        echo
        ok "Etapa $next concluída."
        if [ "$next" -lt "${#STEPS[@]}" ]; then
            echo "Rode ./install.sh de novo pra continuar com a próxima etapa."
        else
            echo -e "${c_green}${c_bold}Tudo pronto!${c_reset}"
        fi
        ;;
    *)
        err "Comando desconhecido: $cmd"
        echo "Uso: ./install.sh [run|status|reset|step N]"
        exit 1
        ;;
esac
