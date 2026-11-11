# Tools NOT installed from apt/snap — install.sh handles these

| Tool | How it got here | Notes |
|---|---|---|
| starship | `curl -sS https://starship.rs/install/sh \| sh` → `/usr/local/bin/starship` | v1.26.0 at capture time |
| uv / uvx | `curl -LsSf https://astral.sh/uv/install.sh \| sh` → `~/.local/bin` | also writes `~/.local/bin/env`, sourced by .bashrc/.profile/.zshrc |
| flyctl | `curl -L https://fly.io/install.sh \| sh` → `~/.fly` | `FLYCTL_INSTALL` in .bashrc |
| libinput-gestures | git clone + `sudo make install` from <https://github.com/bulletmark/libinput-gestures> | NOT a deb; i3 config runs `libinput-gestures-setup restart` |
| JetBrainsMono Nerd Font | Nerd Fonts release zip → `~/.local/share/fonts` | `fonts/install-fonts.sh` |
| vim-plug + plugins | `.vimrc` uses `call plug#begin()` | install.sh bootstraps plug, then run `:PlugInstall` |
| claude / cursor-agent / codex / copilot CLIs | vendor installers into `~/.local/bin` | re-auth each one manually |
| conda (anaconda3) | Anaconda installer → `~/anaconda3` | `.bashrc` has a conda init block that breaks the prompt if missing |
| greenclip | static binary from <https://github.com/erebe/greenclip/releases> → `~/.local/bin` | clipboard history daemon; rofi front-end on `Super+c` |
| autorandr | apt (`packages/apt-rice.txt`) | was a `uv tool` stopgap, now the apt package (hotplug udev rules). Profiles for this laptop's monitors in `dotfiles/config/autorandr` |
| Dropbox | official tarball → `~/.dropbox-dist`; CLI at `~/.local/bin/dropbox` | `cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" \| tar xzf -`; started by the `dropbox.service` user unit (install.sh enables it once `dropboxd` exists) |
| aws-vault, gitleaks, act | GitHub release binaries → `~/.local/bin` | from `~/Documents/daignostics/setup-dev-env.sh` — the work dev-env script, which also installs docker, granted, AWS CLI, ollama and the gitleaks pre-commit template |
| ollama | vendor installer, system `ollama.service` | also from `setup-dev-env.sh` |
| netlify-cli, mermaid-cli (`mmdc`) | `npm i -g` (user prefix `~/.local`) | symlinked into `~/.local/bin` |
| CoppeliaSim | tarball → `~/.local/opt/coppeliasim` | `coppelia` / `coppeliasim` symlinks in `~/.local/bin` |
| OrcaSlicer | AppImage → `~/Applications/OrcaSlicer.AppImage` | `orcaslicer` symlink in `~/.local/bin` |
