#!/usr/bin/env bash
# Installs JetBrainsMono Nerd Font into ~/.local/share/fonts.
# The live machine had ~223 MB of these TTFs; downloading is smaller than
# shipping them, and you always get the current release.
set -euo pipefail

DEST="$HOME/.local/share/fonts"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"

echo "==> Downloading JetBrainsMono Nerd Font"
curl -fL "$URL" -o "$TMP/JetBrainsMono.zip"

echo "==> Installing to $DEST"
mkdir -p "$DEST"
unzip -oq "$TMP/JetBrainsMono.zip" -d "$DEST" -x 'README*' 'LICENSE*' 'OFL*'

echo "==> Rebuilding font cache"
fc-cache -f >/dev/null
fc-list | grep -ci jetbrains | xargs -I{} echo "    {} JetBrains faces registered"
echo "Done."
