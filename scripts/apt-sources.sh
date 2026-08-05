#!/usr/bin/env bash
# Adds the third-party apt repos this setup uses.
# Each block is independent — comment out anything you don't want.
set -uo pipefail

KEYRINGS=/usr/share/keyrings
sudo install -d -m 0755 "$KEYRINGS" /etc/apt/keyrings

add() { echo; echo "==> $1"; }

# ── Google Chrome ─────────────────────────────────────────────────────
add "Google Chrome"
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
  | sudo gpg --dearmor -o "$KEYRINGS/google-chrome.gpg"
echo "deb [arch=amd64 signed-by=$KEYRINGS/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
  | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null

# ── Warp terminal ─────────────────────────────────────────────────────
add "Warp"
curl -fsSL https://releases.warp.dev/linux/keys/warp.asc \
  | sudo gpg --dearmor -o "$KEYRINGS/warpdotdev.gpg"
echo "deb [arch=amd64 signed-by=$KEYRINGS/warpdotdev.gpg] https://releases.warp.dev/linux/deb stable main" \
  | sudo tee /etc/apt/sources.list.d/warpdotdev.list >/dev/null

# ── Tailscale ─────────────────────────────────────────────────────────
add "Tailscale"
. /etc/os-release
curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${VERSION_CODENAME}.noarmor.gpg" \
  | sudo tee "$KEYRINGS/tailscale-archive-keyring.gpg" >/dev/null
curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${VERSION_CODENAME}.tailscale-keyring.list" \
  | sudo tee /etc/apt/sources.list.d/tailscale.list >/dev/null

# ── NodeSource (Node 22) ──────────────────────────────────────────────
add "NodeSource Node 22"
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
  | sudo gpg --dearmor -o "$KEYRINGS/nodesource.gpg"
echo "deb [signed-by=$KEYRINGS/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" \
  | sudo tee /etc/apt/sources.list.d/nodesource.list >/dev/null

# ── Waydroid ──────────────────────────────────────────────────────────
add "Waydroid"
curl -fsSL https://repo.waydro.id/waydroid.gpg \
  | sudo tee "$KEYRINGS/waydroid.gpg" >/dev/null
. /etc/os-release
echo "deb [signed-by=$KEYRINGS/waydroid.gpg] https://repo.waydro.id/ ${VERSION_CODENAME} main" \
  | sudo tee /etc/apt/sources.list.d/waydroid.list >/dev/null

# ── PPAs ──────────────────────────────────────────────────────────────
add "PPAs (obs-studio, openshot)"
sudo add-apt-repository -y ppa:obsproject/obs-studio
sudo add-apt-repository -y ppa:openshot.developers/ppa

# ── Manual / account-gated, left as notes ─────────────────────────────
cat <<'NOTE'

Not scripted (grab the .deb or vendor installer yourself):
  * Cursor            https://cursor.com/downloads
  * Antigravity       (Google internal apt repo — was auto-added by its installer)
  * Obsidian          https://obsidian.md/download
  * Discord           https://discord.com/download
  * Viber             https://www.viber.com/download/
  * RustDesk          https://github.com/rustdesk/rustdesk/releases
  * VirtualBox 7.2    https://www.virtualbox.org/wiki/Linux_Downloads
  * FortiClient       (was configured here; add only if you still need the VPN)
NOTE

sudo apt-get update
