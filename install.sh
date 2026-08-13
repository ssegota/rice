#!/usr/bin/env bash
#
#  ██▀███   ██▓ ▄████▄  ▓█████
# ▓██ ▒ ██▒▓██▒▒██▀ ▀█  ▓█   ▀
# ▓██ ░▄█ ▒▒██▒▒▓█    ▄ ▒███
# ▒██▀▀█▄  ░██░▒▓▓▄ ▄██▒▒▓█  ▄
# ░██▓ ▒██▒░██░▒ ▓███▀ ░░▒████▒
#
#  sbs' i3 + polybar + Tokyo Night setup — installer
#
#  Usage:
#    ./install.sh                 # everything, with prompts
#    ./install.sh --dotfiles      # just drop the configs in
#    ./install.sh --list          # show the stages and exit
#    ./install.sh --dry-run --all # print what would happen, touch nothing
#
#  Safe to re-run. Anything it would overwrite in $HOME is first copied to
#  ~/.rice-backup-<timestamp>/ with the same relative path.
#
set -uo pipefail

RICE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.rice-backup-$(date +%Y%m%d_%H%M%S)"
DRY_RUN=0
ASSUME_YES=0

# ── output helpers ───────────────────────────────────────────────────────────
if [ -t 1 ]; then
  B=$'\033[1m'; DIM=$'\033[2m'; R=$'\033[0m'
  BLU=$'\033[38;5;111m'; GRN=$'\033[38;5;150m'; YEL=$'\033[38;5;222m'; RED=$'\033[38;5;210m'
else
  B=""; DIM=""; R=""; BLU=""; GRN=""; YEL=""; RED=""
fi
step()  { printf '\n%s▸ %s%s\n' "$BLU$B" "$*" "$R"; }
ok()    { printf '  %s✓%s %s\n' "$GRN" "$R" "$*"; }
skip()  { printf '  %s·%s %s\n' "$DIM" "$R" "$*"; }
warn()  { printf '  %s!%s %s\n' "$YEL" "$R" "$*"; }
die()   { printf '\n%serror:%s %s\n' "$RED$B" "$R" "$*" >&2; exit 1; }

run() {
  if [ "$DRY_RUN" = 1 ]; then printf '  %s$ %s%s\n' "$DIM" "$*" "$R"; return 0; fi
  "$@"
}
confirm() {
  [ "$ASSUME_YES" = 1 ] && return 0
  [ "$DRY_RUN" = 1 ] && return 0
  local reply
  read -r -p "  ${B}$1${R} [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}
have() { command -v "$1" >/dev/null 2>&1; }

# ── backup-then-install a single path into $HOME ─────────────────────────────
# usage: place <source> <relative-dest-under-$HOME>
place() {
  local src="$1" rel="$2" dest="$HOME/$2"
  [ -e "$src" ] || { warn "missing in bundle: $src"; return 1; }
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ "$DRY_RUN" = 0 ]; then
      mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      cp -a "$dest" "$BACKUP_DIR/$rel"
    fi
    printf '  %s↻%s %-42s %s(backed up)%s\n' "$YEL" "$R" "~/$rel" "$DIM" "$R"
  else
    printf '  %s+%s %s\n' "$GRN" "$R" "~/$rel"
  fi
  if [ "$DRY_RUN" = 0 ]; then
    mkdir -p "$(dirname "$dest")"
    rm -rf "$dest"
    cp -a "$src" "$dest"
  fi
}

# ═════════════════════════════════════════════════════════════════════════════
#  STAGES
# ═════════════════════════════════════════════════════════════════════════════

stage_preflight() {
  step "Preflight"
  [ "$(id -u)" -ne 0 ] || die "don't run this as root — it installs into \$HOME. Use your normal user (it will sudo when needed)."
  have apt-get || die "this installer is Debian/Ubuntu-only (no apt-get found)."
  if [ -r /etc/os-release ]; then
    . /etc/os-release
    ok "${PRETTY_NAME:-unknown} (captured on Ubuntu 26.04 'resolute')"
    [ "${VERSION_CODENAME:-}" = "resolute" ] || \
      warn "different release than the source machine — a few package names may differ"
  fi
  for c in curl git unzip; do
    have "$c" || { warn "$c missing — installing"; run sudo apt-get install -y "$c"; }
  done
  ok "bundle: $RICE_DIR"
}

stage_sources() {
  step "Third-party apt repositories"
  if confirm "Add third-party repos (Chrome, Warp, Tailscale, NodeSource, Waydroid, PPAs)?"; then
    run bash "$RICE_DIR/scripts/apt-sources.sh"
  else
    skip "skipped — packages in packages/apt-thirdparty.txt will not resolve"
  fi
}

stage_apt() {
  step "apt packages"
  local list="$RICE_DIR/packages/apt-rice.txt"
  mapfile -t pkgs < <(grep -vE '^\s*(#|$)' "$list")
  ok "${#pkgs[@]} packages from packages/apt-rice.txt"
  warn "texlive-full is in that list and is several GB — edit the file first if you don't want it"
  if confirm "Install them now?"; then
    run sudo apt-get update
    # one-by-one so a single unavailable package doesn't abort the whole run
    local failed=()
    for p in "${pkgs[@]}"; do
      if [ "$DRY_RUN" = 1 ]; then printf '  %s$ sudo apt-get install -y %s%s\n' "$DIM" "$p" "$R"; continue; fi
      # recommends left ON deliberately: the source machine was built with them,
      # and stripping them breaks desktop packages in non-obvious ways.
      if sudo apt-get install -y "$p" >/dev/null 2>&1; then
        printf '  %s✓%s %s\n' "$GRN" "$R" "$p"
      else
        printf '  %s✗%s %s\n' "$RED" "$R" "$p"; failed+=("$p")
      fi
    done
    if [ "${#failed[@]}" -gt 0 ]; then
      warn "${#failed[@]} failed: ${failed[*]}"
      warn "retry individually — usually a renamed package on a newer release"
    fi
  else
    skip "skipped"
  fi

  step "Third-party apt packages"
  if confirm "Install packages/apt-thirdparty.txt (needs the repos above)?"; then
    mapfile -t tp < <(grep -vE '^\s*(#|$)' "$RICE_DIR/packages/apt-thirdparty.txt")
    for p in "${tp[@]}"; do
      if [ "$DRY_RUN" = 1 ]; then printf '  %s$ apt-get install -y %s%s\n' "$DIM" "$p" "$R"; continue; fi
      sudo apt-get install -y "$p" >/dev/null 2>&1 \
        && printf '  %s✓%s %s\n' "$GRN" "$R" "$p" \
        || printf '  %s✗%s %s %s(install manually — see scripts/apt-sources.sh)%s\n' "$RED" "$R" "$p" "$DIM" "$R"
    done
  else
    skip "skipped"
  fi
}

stage_snaps() {
  step "Snap packages"
  have snap || { warn "snapd not installed — skipping"; return 0; }
  if ! confirm "Install snaps from packages/snap-rice.txt?"; then skip "skipped"; return 0; fi
  while read -r name flag; do
    [ -z "${name:-}" ] && continue
    if [ "$DRY_RUN" = 1 ]; then printf '  %s$ snap install %s %s%s\n' "$DIM" "$name" "${flag:-}" "$R"; continue; fi
    if snap list "$name" >/dev/null 2>&1; then skip "$name (present)"; continue; fi
    # shellcheck disable=SC2086
    sudo snap install "$name" ${flag:-} >/dev/null 2>&1 \
      && ok "$name" \
      || printf '  %s✗%s %s\n' "$RED" "$R" "$name"
  done < <(grep -vE '^\s*(#|$)' "$RICE_DIR/packages/snap-rice.txt")
}

stage_external() {
  step "External tools (not in apt)"

  if have starship; then skip "starship $(starship --version 2>/dev/null | head -1 | awk '{print $2}')"
  else
    ok "installing starship → /usr/local/bin"
    run bash -c 'curl -sS https://starship.rs/install/sh | sh -s -- -y'
  fi

  if [ -x "$HOME/.local/bin/uv" ]; then skip "uv (present)"
  else
    ok "installing uv → ~/.local/bin"
    run bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
  fi

  if [ -x "$HOME/.fly/bin/flyctl" ]; then skip "flyctl (present)"
  else
    if confirm "Install flyctl (.bashrc references ~/.fly)?"; then
      run bash -c 'curl -L https://fly.io/install.sh | sh'
    fi
  fi

  # libinput-gestures — not packaged, but the i3 config calls it on every reload
  if have libinput-gestures; then skip "libinput-gestures (present)"
  else
    if confirm "Build libinput-gestures from source (i3 config depends on it)?"; then
      local tmp; tmp="$(mktemp -d)"
      run git clone -q --depth 1 https://github.com/bulletmark/libinput-gestures "$tmp"
      run sudo make -C "$tmp" install
      run sudo gpasswd -a "$USER" input
      run rm -rf "$tmp"
      warn "log out and back in for the 'input' group to take effect"
    fi
  fi

  # vim-plug, because .vimrc calls plug#begin()
  local plug="$HOME/.vim/autoload/plug.vim"
  if [ -f "$plug" ]; then skip "vim-plug (present)"
  else
    ok "installing vim-plug"
    run curl -fLo "$plug" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    warn "run :PlugInstall inside vim to fetch nerdtree/fugitive/airline/tokyonight"
  fi

  # .bashrc says `fd`, Ubuntu ships `fdfind`. Without this, Ctrl-T/Alt-C in fzf
  # silently return nothing. (This was already broken on the source machine.)
  if have fd; then skip "fd (present)"
  elif have fdfind; then
    ok "linking fdfind → ~/.local/bin/fd (FZF_DEFAULT_COMMAND expects 'fd')"
    run mkdir -p "$HOME/.local/bin"
    run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  else
    warn "neither fd nor fdfind found — fzf's file widgets won't work"
  fi

  # greenclip — clipboard history daemon, rofi front-end on Super+c
  if have greenclip; then skip "greenclip (present)"
  else
    ok "installing greenclip → ~/.local/bin (static binary)"
    run mkdir -p "$HOME/.local/bin"
    run curl -fsSL -o "$HOME/.local/bin/greenclip" \
      https://github.com/erebe/greenclip/releases/latest/download/greenclip
    run chmod +x "$HOME/.local/bin/greenclip"
  fi

  # autorandr profiles are per-machine: save one at each monitor setup with
  # `autorandr --save <name>` (the apt package provides hotplug udev rules).
  have autorandr && skip "autorandr present — remember to --save a profile per dock"
}

stage_dotfiles() {
  step "Dotfiles → \$HOME"
  local d="$RICE_DIR/dotfiles"

  for f in "$d"/home/.*; do
    local base; base="$(basename "$f")"
    case "$base" in
      .|..|*.template) continue ;;
    esac
    place "$f" "$base"
  done

  for f in "$d"/config/*; do
    [ -e "$f" ] || continue
    place "$f" ".config/$(basename "$f")"
  done

  for f in "$d"/local-bin/*; do
    [ -e "$f" ] || continue
    place "$f" ".local/bin/$(basename "$f")"
    run chmod +x "$HOME/.local/bin/$(basename "$f")"
  done

  # i3 and polybar exec these directly; a lost +x bit means an empty bar.
  if [ "$DRY_RUN" = 1 ]; then
    printf '  %s$ chmod +x ~/.fehbg ~/.config/i3/scripts/*.sh ~/.config/polybar/*.sh ~/.config/polybar/scripts/*.sh%s\n' "$DIM" "$R"
  else
    chmod +x "$HOME/.fehbg" 2>/dev/null
    find "$HOME/.config/i3" "$HOME/.config/polybar" -name '*.sh' -type f \
      -exec chmod +x {} + 2>/dev/null
    ok "marked i3/polybar helper scripts executable"
  fi

  # wakatime is a template because the real file holds an API key
  if [ ! -f "$HOME/.wakatime.cfg" ] && [ -f "$d/home/.wakatime.cfg.template" ]; then
    place "$d/home/.wakatime.cfg.template" ".wakatime.cfg.template"
    warn "~/.wakatime.cfg.template — put your own key in it and rename (key was NOT copied)"
  fi

  # conda block in .bashrc points at ~/anaconda3 and errors noisily if absent
  if [ ! -d "$HOME/anaconda3" ]; then
    warn ".bashrc has a conda init block for ~/anaconda3, which isn't installed here."
    warn "Install Anaconda, or delete the '>>> conda initialize >>>' block from ~/.bashrc."
  fi

  [ -d "$BACKUP_DIR" ] && ok "replaced files backed up to $BACKUP_DIR"
  return 0
}

stage_wallpapers() {
  step "Wallpapers → ~/Pictures/wallpapers"
  run mkdir -p "$HOME/Pictures/wallpapers"
  if [ "$DRY_RUN" = 1 ]; then
    printf '  %s$ cp -an %s/wallpapers/. ~/Pictures/wallpapers/%s\n' "$DIM" "$RICE_DIR" "$R"
  else
    cp -an "$RICE_DIR"/wallpapers/. "$HOME/Pictures/wallpapers/" 2>/dev/null
    ok "$(find "$HOME/Pictures/wallpapers" -maxdepth 1 -type f | wc -l) files present"
  fi
}

stage_fonts() {
  step "Fonts"
  if fc-list 2>/dev/null | grep -qi 'JetBrainsMono.*Nerd'; then
    skip "JetBrainsMono Nerd Font already installed"
  else
    run bash "$RICE_DIR/fonts/install-fonts.sh"
  fi
}

stage_editors() {
  step "Editor settings"
  for app in Code Cursor; do
    local src="$RICE_DIR/editors/$app"
    [ -d "$src" ] || continue
    for f in "$src"/*; do
      [ -e "$f" ] || continue
      place "$f" ".config/$app/User/$(basename "$f")"
    done
  done
  if [ -s "$RICE_DIR/editors/vscode-extensions.txt" ] && have code; then
    if confirm "Reinstall VS Code extensions from editors/vscode-extensions.txt?"; then
      while read -r ext; do
        [ -z "$ext" ] && continue
        run code --install-extension "$ext" --force
      done < "$RICE_DIR/editors/vscode-extensions.txt"
    fi
  fi
}

stage_services() {
  step "Services & session"
  if have tlp; then
    if [ "$DRY_RUN" = 1 ]; then
      printf '  %s$ sudo systemctl enable --now tlp%s\n' "$DIM" "$R"
    elif sudo systemctl enable --now tlp >/dev/null 2>&1; then
      ok "tlp enabled (battery/thermal tuning)"
    else
      warn "could not enable tlp — check 'systemctl status tlp'"
    fi
  fi
  if have tailscale; then skip "tailscale installed — run 'sudo tailscale up' to join your tailnet"; fi
  if have lightdm; then
    ok "lightdm present — pick the 'i3' session at the login screen"
    skip "greeter theming reference: system/lightdm-gtk-greeter.conf"
  fi
}

stage_done() {
  cat <<EOF

${BLU}${B}────────────────────────────────────────────────────────────${R}
${B}Done.${R} What's left, in order:

  1. ${B}Log out and pick "i3"${R} at the LightDM session menu.
  2. ${B}exec bash${R} (or new terminal) to load the new prompt.
  3. Wallpaper: ${B}Super+Shift+w${R} picks one interactively; ${DIM}~/.fehbg${R}
     holds the choice (two images there = one per monitor).
  4. In vim: ${B}:PlugInstall${R}
  5. Fingerprint reader, if the hardware has one: ${B}fprintd-enroll${R}
  6. ${B}Secrets are deliberately not in this bundle.${R} See ${B}secrets/README.md${R}
     — the short version is: ${DIM}gh auth login${R} and re-issue AWS keys.

  Keybinds, in case months have passed: ${B}Super+F1 shows them all${R}
    Super+Return  ghostty          Super+d        rofi
    Super+Shift+Return  warp       Super+Tab      window switcher
    Super+Shift+q kill window      Super+Shift+e  power menu
    Super+Escape  lock             F12            guake dropdown
    Print         flameshot        Super+r        resize mode
    Super+c       clipboard hist   Super+n        notification history
    Super+Shift+w wallpaper picker Super+Shift+t  theme variant switcher
    Focus/move:   h / j / k / l    (vim-standard; split-h moved to Super+b)

  Backups of anything replaced: ${DIM}${BACKUP_DIR}${R}
${BLU}${B}────────────────────────────────────────────────────────────${R}
EOF
}

# ═════════════════════════════════════════════════════════════════════════════
#  ARG PARSING
# ═════════════════════════════════════════════════════════════════════════════
STAGES=()
while [ $# -gt 0 ]; do
  case "$1" in
    --all|-a)     STAGES=(sources apt snaps external dotfiles wallpapers fonts editors services) ;;
    --sources)    STAGES+=(sources) ;;
    --packages|--apt) STAGES+=(apt) ;;
    --snaps)      STAGES+=(snaps) ;;
    --external)   STAGES+=(external) ;;
    --dotfiles)   STAGES+=(dotfiles) ;;
    --wallpapers) STAGES+=(wallpapers) ;;
    --fonts)      STAGES+=(fonts) ;;
    --editors)    STAGES+=(editors) ;;
    --services)   STAGES+=(services) ;;
    --dry-run|-n) DRY_RUN=1 ;;
    --yes|-y)     ASSUME_YES=1 ;;
    --list|-l)
      cat <<'EOF'
Stages (default = all, in this order):
  --sources     add third-party apt repos (Chrome, Warp, Tailscale, Node, …)
  --packages    apt packages from packages/apt-rice.txt
  --snaps       snaps from packages/snap-rice.txt
  --external    starship, uv, flyctl, libinput-gestures, vim-plug, fd symlink,
                greenclip
  --dotfiles    configs into $HOME (backs up whatever it replaces)
  --wallpapers  images into ~/Pictures/wallpapers
  --fonts       JetBrainsMono Nerd Font
  --editors     VS Code / Cursor settings + extensions
  --services    enable tlp, session notes
Flags:
  -n, --dry-run   print actions, change nothing
  -y, --yes       don't prompt
EOF
      exit 0 ;;
    -h|--help) sed -n '2,26p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) die "unknown option: $1  (try --help)" ;;
  esac
  shift
done
[ "${#STAGES[@]}" -eq 0 ] && STAGES=(sources apt snaps external dotfiles wallpapers fonts editors services)

# ═════════════════════════════════════════════════════════════════════════════
printf '%s' "$BLU$B"
cat <<'BANNER'
   ┌──────────────────────────────────────────┐
   │   sbs' rice — i3 · polybar · Tokyo Night │
   └──────────────────────────────────────────┘
BANNER
printf '%s' "$R"
[ "$DRY_RUN" = 1 ] && warn "DRY RUN — nothing will be modified"

stage_preflight
for s in "${STAGES[@]}"; do "stage_$s"; done
stage_done
