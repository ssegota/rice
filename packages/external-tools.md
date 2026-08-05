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
| autotiling | `uv tool install autotiling` → `~/.local/bin` | i3 config `exec_always`'s it; alternates split direction |
| greenclip | static binary from <https://github.com/erebe/greenclip/releases> → `~/.local/bin` | clipboard history daemon; rofi front-end on `Super+c` |
| autorandr (this machine only) | `uv tool install autorandr` | stopgap until `sudo apt install autorandr` (apt adds hotplug udev rules — then `uv tool uninstall autorandr`); profiles live in `~/.config/autorandr` |
