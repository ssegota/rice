#!/usr/bin/env bash
#
# Restore the encrypted archive made by export-secrets.sh.
#
#   ./import-secrets.sh ~/rice-secrets-thinkpad-20260805.tar.gz.gpg
#
# Existing files are backed up to ~/.rice-secrets-backup-<timestamp>/ first.
# Permissions are re-tightened afterwards (0700 dirs, 0600 files).
#
set -euo pipefail

ARCHIVE="${1:-}"
B=$'\033[1m'; R=$'\033[0m'; YEL=$'\033[38;5;222m'; RED=$'\033[38;5;210m'; GRN=$'\033[38;5;150m'

[ -n "$ARCHIVE" ] || { echo "usage: $0 <archive.tar.gz.gpg>"; exit 1; }
[ -f "$ARCHIVE" ] || { echo "${RED}no such file: $ARCHIVE${R}"; exit 1; }
command -v gpg >/dev/null || { echo "${RED}gpg not found — sudo apt install gnupg${R}"; exit 1; }

umask 077
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "${B}Decrypting${R} $ARCHIVE"
gpg --batch --quiet --decrypt -o "$TMP/payload.tar.gz" "$ARCHIVE" 2>/dev/null \
  || gpg --decrypt -o "$TMP/payload.tar.gz" "$ARCHIVE"

echo
echo "${B}Archive contains:${R}"
tar -tzf "$TMP/payload.tar.gz" | sed 's/^/  /' | head -40
TOTAL=$(tar -tzf "$TMP/payload.tar.gz" | wc -l)
[ "$TOTAL" -gt 40 ] && echo "  … and $((TOTAL - 40)) more"

echo
read -r -p "${B}Extract into $HOME?${R} [y/N] " reply
[[ "$reply" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# back up anything we're about to shadow
BACKUP="$HOME/.rice-secrets-backup-$(date +%Y%m%d_%H%M%S)"
while read -r entry; do
  top="${entry%%/*}"
  if [ -e "$HOME/$top" ]; then
    mkdir -p "$BACKUP"
    [ -e "$BACKUP/$top" ] || cp -a "$HOME/$top" "$BACKUP/$top"
  fi
done < <(tar -tzf "$TMP/payload.tar.gz")
[ -d "$BACKUP" ] && echo "${YEL}Existing files backed up to $BACKUP${R}"

tar -xzf "$TMP/payload.tar.gz" -C "$HOME"

# re-tighten — tar preserves modes, but be certain
for d in "$HOME/.ssh" "$HOME/.gnupg" "$HOME/.aws"; do
  [ -d "$d" ] || continue
  chmod 700 "$d"
  find "$d" -type f -exec chmod 600 {} +
  find "$d" -type d -exec chmod 700 {} +
done
[ -f "$HOME/.wakatime.cfg" ] && chmod 600 "$HOME/.wakatime.cfg"
[ -f "$HOME/.config/gh/hosts.yml" ] && chmod 600 "$HOME/.config/gh/hosts.yml"

cat <<EOF

${GRN}${B}Restored.${R} Verify, then destroy the archive:

  gh auth status
  aws sts get-caller-identity --profile daignostics-main
  ssh-add -l 2>/dev/null || true
  gpg --list-secret-keys

  ${B}shred -u "$ARCHIVE"${R}

${YEL}Reminder:${R} those AWS keys now exist on two machines. If the old one is
being retired, rotate them in IAM and delete the old pair.
EOF
