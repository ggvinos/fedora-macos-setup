# fedora-macos-setup

Deixa o Fedora + GNOME com cara de macOS (estilo Tahoe): dock com magnificação
real, tema visual completo, blur, cantos arredondados, launcher estilo
Spotlight e um painel superior transparente sem aquelas "cápsulas" atrás dos
ícones.

Testado em **Fedora 43, GNOME Shell 49, sessão Wayland**. Deve funcionar em
versões próximas, mas sem garantia.

## O que isso instala

- **[Dhruva](https://github.com/NarkAgni/dhruva)** — dock com magnificação em
  onda, animações de abrir/fechar, no lugar da Dash to Dock
- **[MacTahoe](https://github.com/vinceliuice/MacTahoe-gtk-theme)** — tema
  visual completo (ícones, GTK/Shell, tela de login), do mesmo autor do
  WhiteSur
- **[Blur my Shell](https://extensions.gnome.org/extension/3193/blur-my-shell/)**
  — blur no overview, gaveta de apps e tela de bloqueio
- **[Rounded Window Corners Reborn](https://github.com/flexagoon/rounded-window-corners)**
  — cantos arredondados em qualquer janela, mesmo maximizada
- **[Extension Manager](https://flathub.org/apps/com.mattjakeman.ExtensionManager)**
  — app gráfico pra gerenciar extensões depois
- **[ULauncher](https://ulauncher.io/)** — launcher estilo Spotlight
  (`Super+Espaço`), com tema translúcido
- Fonte **Inter** (clone livre da SF Pro) como fonte do sistema

Além da instalação em si, o script já aplica um punhado de correções que só
se descobrem testando de verdade (ver seção "Por que os patches" abaixo).

## Como usar

```bash
git clone https://github.com/ggvinos/fedora-macos-setup.git
cd fedora-macos-setup
chmod +x install.sh
./install.sh
```

O script é dividido em **7 etapas**. Rode `./install.sh`, ele executa a
próxima etapa pendente e para. Duas das etapas (dock e extensões) exigem
**logout/login** no meio do caminho — isso é uma limitação real do GNOME
Shell: uma extensão recém-instalada só é reconhecida depois de reiniciar a
sessão, não tem como contornar isso rodando comandos. Quando o script pedir,
faça logout, entre de novo, e rode `./install.sh` de novo pra continuar de
onde parou.

Outros comandos:

```bash
./install.sh status     # mostra em qual etapa você está
./install.sh step 3     # roda uma etapa específica de novo
./install.sh reset      # zera o progresso salvo (não desinstala nada)
```

## Depois de rodar tudo

Algumas coisas ficam com um toque final melhor pela interface gráfica:

- **Dhruva**: botão direito no ícone da dock → Preferências, pra ajustar
  tamanho, posição, tema.
- **ULauncher**: já sai com `Super+Espaço` e tema translúcido, mas as
  preferências (ícone de engrenagem na busca) têm mais opções.
- Se você usa **Spotify via Flatpak**, ele pode aparecer com uma barra de
  título azul feia em vez de integrar com o GNOME. Corrige com:
  ```bash
  flatpak override --user --unset-env=XDG_SESSION_TYPE --socket=x11 --nosocket=wayland com.spotify.Client
  ```
- Se você usa **Notion**, não existe cliente oficial Linux. O wrapper mais
  comum via snap vem com ícone feio e não dá pra corrigir (pacote snap é
  somente leitura). Alternativa mais integrada:
  [Cohesion](https://flathub.org/apps/io.github.brunofin.Cohesion)
  (`flatpak install flathub io.github.brunofin.Cohesion`).

## Extensões extras e restauração de configurações

Esse script cobre só a base. No uso real, mais extensões foram entrando
(tiling, clipboard, volume por app, etc.) e os atalhos/favoritos/config fina
de cada uma foram ajustados na mão. Tudo isso está documentado e versionado:

- **[EXTENSOES-EXTRAS.md](EXTENSOES-EXTRAS.md)** — lista completa das
  extensões além das 3 instaladas pelo script, com link de origem e comando
  de instalação de cada uma.
- **`dconf/restore.sh`** — depois de instalar as extensões extras, roda esse
  script pra recolocar tema, atalhos, favoritos do dock e configuração
  específica de cada extensão (raio dos cantos, blur por área, posição da
  dock, etc.), tudo de uma vez via `dconf load`.

Ordem recomendada numa instalação nova: `./install.sh` (até o fim) →
extensões extras do `EXTENSOES-EXTRAS.md` → `dconf/restore.sh` → logout/login.

## Por que os patches (`patches/`)

Esse projeto não é só "clona e roda o install.sh de cada tema". Ao usar tudo
junto, apareceram alguns problemas reais que só um passa por eles depois de
testar de verdade:

- **`dhruva_scroll_fix.py`**: a Dhruva tem uma opção "ciclar janelas com
  scroll sobre o ícone" que só funcionava em pastas especiais (Lixeira, Pasta
  Pessoal), não em apps normais em execução (Chrome, Discord etc). Corrigido
  e [enviado como PR](https://github.com/NarkAgni/dhruva/pull/60) — se já
  tiver sido aceito upstream, o script detecta e pula o patch sozinho.
- **`mactahoe_sidebar_fix.py`**: a variante "solid" do MacTahoe ainda deixa a
  barra lateral do Nautilus/Configurações com uma regra CSS genérica
  transparente demais, que faz o conteúdo de outras janelas vazar através
  dela.
- **`mactahoe_panel_fix.py`**: por padrão o painel superior do MacTahoe tem
  "cápsulas" (fundo em pílula) atrás do relógio, do Activities e dos ícones
  da bandeja. Pra ficar igual ao menu bar do macOS (transparente, só texto e
  ícones brancos), essas regras precisam ser removidas.
- **`configure_rounded_corners.py`**: por padrão a extensão não mantém canto
  arredondado em janela maximizada, nem aplica em apps GTK4/libadwaita
  (Nautilus, Configurações) — as duas opções vêm desligadas.

Se algum desses upstreams corrigir o problema numa versão futura, o patch
correspondente simplesmente não encontra o texto original e é pulado (o
script avisa, mas continua).

## Não incluído de propósito

- **Driver de GPU** (NVIDIA/AMD): fora de escopo, é específico de cada
  hardware.
- **Atalhos de teclado estilo Mac** (Cmd em vez de Ctrl): mudança funcional
  grande, não só visual. Se quiser isso, dê uma olhada no
  [kinto.sh](https://kinto.sh/).
- **Remapear a fonte monoespaçada** (terminal/editor): fica no padrão do
  sistema, mexe nisso se quiser algo tipo JetBrains Mono ou Cascadia Code.

## Licença

MIT.
