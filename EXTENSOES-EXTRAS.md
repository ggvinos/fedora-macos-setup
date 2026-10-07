# Extensões extras (fora do install.sh)

O `install.sh` cobre só a base visual (dock, tema, fonte, blur, cantos
arredondados, ULauncher). No dia a dia acabei instalando mais extensões,
pela [Extension Manager](https://flathub.org/apps/com.mattjakeman.ExtensionManager)
ou direto do GitHub. Nenhuma delas é essencial pro visual "macOS", mas sem
elas a experiência fica incompleta. Lista com o que cada uma faz e como
reinstalar:

## Pelo GNOME Extensions / Extension Manager (buscar pelo nome)

| Extensão | Pra que serve |
|---|---|
| **Burn My Windows** | animação de "queimar" ao fechar janelas |
| **Boost Volume** | permite subir o volume acima de 100% |
| **Volume Mixer** | mixer de volume por aplicativo na bandeja |
| **Tiling Assistant** | encaixar janelas lado a lado arrastando (tipo Snap do Windows/macOS) |
| **Spotify Controls + Track Info** | controles do Spotify na barra superior |
| **PiP on top** | mantém janelas picture-in-picture sempre por cima |
| **Clipboard Indicator** | histórico de área de transferência (`Super+V`) |

Repositórios de origem, caso a Extension Manager não encontre:
- https://github.com/Schneegans/Burn-My-Windows
- https://github.com/shaquibimdad/gnome_ext_volume_boost
- https://github.com/aleho/gnome-shell-volume-mixer
- https://github.com/ubuntu/Tiling-Assistant
- https://github.com/Sonath21/spotify-controls
- https://github.com/Rafostar/gnome-shell-extension-pip-on-top
- https://github.com/Tudmotu/gnome-shell-extension-clipboard-indicator

## Via dnf (pacotes do próprio Fedora)

```bash
sudo dnf install gnome-shell-extension-background-logo \
                  gnome-shell-extension-launch-new-instance \
                  gnome-shell-extension-user-theme
```

- **background-logo**: logo da distro atrás dos ícones do desktop (cosmético, pode pular se não fizer diferença)
- **launch-new-instance**: clique no ícone da dock sempre abre nova instância
- **user-theme**: necessária pro MacTahoe funcionar como tema do Shell (o install.sh já deve cobrir essa dependência, mas fica registrado aqui também)

## Clone manual (sem publicação na extensions.gnome.org)

```bash
git clone https://github.com/tiagoporsch/restartto.git ~/.local/share/gnome-shell/extensions/restartto@tiagoporsch.github.io
git clone https://github.com/gilson-fonsaca/magnific_launcher.git ~/.local/share/gnome-shell/extensions/magnific-launcher@gilsonf
```

- **restartto**: reiniciar direto pro Windows a partir do menu de desligar (útil pro dual boot)
- **magnific-launcher**: não está habilitada atualmente (ficou de teste, substituída pelo ULauncher) — só reclone se quiser testar de novo

## Habilitar tudo de uma vez

```bash
gnome-extensions enable burn-my-windows@schneegans.github.com
gnome-extensions enable boostvolume@shaquib.dev
gnome-extensions enable shell-volume-mixer@derhofbauer.at
gnome-extensions enable tiling-assistant@leleat-on-github
gnome-extensions enable spotify-controls@Sonath21
gnome-extensions enable pip-on-top@rafostar.github.com
gnome-extensions enable clipboard-indicator@tudmotu.com
gnome-extensions enable restartto@tiagoporsch.github.io
gnome-extensions enable background-logo@fedorahosted.org
gnome-extensions enable launch-new-instance@gnome-shell-extensions.gcampax.github.com
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
```

(as do install.sh — dhruva, blur-my-shell, rounded-window-corners — já são habilitadas pelo script principal)

## Restaurar atalhos, favoritos do dock e config fina de cada extensão

Depois de instalar e habilitar todas as extensões acima (e rodar o
`install.sh` completo), restaure as configurações salvas:

```bash
cd ~/fedora-macos-setup/dconf
./restore.sh
```

Isso recoloca: tema escuro + MacTahoe + WhiteSur cursors, fonte Inter,
botões da janela no estilo macOS (`appmenu:minimize,maximize,close`),
favoritos e ordem dos ícones na gaveta de apps, e a configuração específica
de cada extensão (raio dos cantos arredondados, blur por área, atalho do
clipboard, posição do dock da Dhruva, etc).

Extensões que ficaram **desabilitadas de propósito** (testes antigos, não
precisa reinstalar): `dash-to-dock`, `clipboard-history`, `compiz-windows-effect`,
`custom-window-controls`, `window-list`.
