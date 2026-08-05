#!/usr/bin/env bash
#
# Export credentials as a SINGLE ENCRYPTED ARCHIVE, written outside the rice
# bundle so it can never be committed or synced along with the dotfiles.
#
#   ./export-secrets.sh              # writes ~/rice-secrets-<host>-<date>.tar.gz.gpg
#   ./export-secrets.sh /media/usb   # writes it there instead
#
# You will be asked for a passphrase. Nothing is written in plaintext.
# Transfer the .gpg file by USB stick or scp, then run import-secrets.sh
# on the new machine and DELETE the archive.
#
set -euo pipefail

OUT_DIR="${1:-$HOME}"
HOST="$(hostname -s 2>/dev/null || echo host)"
STAMP="$(date +%Y%m%d)"
OUT="$OUT_DIR/rice-secrets-$HOST-$STAMP.tar.gz.gpg"

RICE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

B=$'\033[1m'; R=$'\033[0m'; YEL=$'\033[38;5;222m'; RED=$'\033[38;5;210m'; GRN=$'\033[38;5;150m'

command -v gpg >/dev/null || { echo "${RED}gpg not found — sudo apt install gnupg${R}"; exit 1; }

# Refuse to write anywhere inside the rice bundle.
OUT_ABS="$(cd "$OUT_DIR" && pwd)"
case "$OUT_ABS/" in
  "$RICE_DIR"/*|"$RICE_DIR/") echo "${RED}Refusing to write secrets inside the rice bundle ($RICE_DIR).${R}"; exit 1 ;;
esac

# What we collect. Paths are relative to $HOME.
CANDIDATES=(
  .aws                       # profiles + long-lived static access keys
  .ssh                       # private keys, config, known_hosts
  .wakatime.cfg              # WakaTime API key
  .gnupg                     # GPG secret keyring
)
# Deliberately NOT included: ~/.config/gh/hosts.yml. On this machine gh keeps the
# token in the system keyring, so that file holds only a username — copying it
# transfers no access. Run `gh auth login` on the new machine instead.

INCLUDE=()
echo "${B}Collecting:${R}"
for p in "${CANDIDATES[@]}"; do
  if [ -e "$HOME/$p" ]; then
    INCLUDE+=("$p"); printf '  %s+%s ~/%s\n' "$GRN" "$R" "$p"
  else
    printf '  · ~/%s (absent)\n' "$p"
  fi
done
[ "${#INCLUDE[@]}" -gt 0 ] || { echo "Nothing to export."; exit 0; }

cat <<EOF

${YEL}${B}Before you do this, read this bit.${R}
Copying long-lived credentials to a second machine doubles the number of
places they can leak from, and the copy outlives any memory you have of
making it. The cleaner path for most of the list above:

  ${B}GitHub${R}   run ${B}gh auth login${R} on the new box — mandatory, not optional:
           your token lives in the system keyring, not in any file here.
  ${B}AWS${R}      your ~/.aws/credentials holds ${B}long-lived static keys${R} for 4
           profiles. Prefer ${B}aws configure sso${R}, or mint fresh
           keys on the new machine and delete the old ones in IAM. Static
           keys that exist in two places, one of which is a machine you may
           later sell or reimage, are the classic way an account gets owned.
  ${B}SSH${R}      generating a new keypair and adding the pubkey to GitHub /
           servers is usually less work than moving the private key safely.
  ${B}GPG${R}      genuinely worth migrating — identity, not access. Use
           ${B}gpg --export-secret-keys${R} if you'd rather do it surgically.

Use this script when you actually want the whole set moved as-is.

EOF

read -r -p "${B}Continue and create the encrypted archive?${R} [y/N] " reply
[[ "$reply" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

umask 077
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

tar -czf "$TMP/payload.tar.gz" -C "$HOME" "${INCLUDE[@]}"

echo
echo "${B}Passphrase for the archive${R} (long, and not one you've used elsewhere):"
gpg --batch --yes --symmetric --cipher-algo AES256 \
    --s2k-mode 3 --s2k-count 65011712 --s2k-digest-algo SHA512 \
    -o "$OUT" "$TMP/payload.tar.gz"

chmod 600 "$OUT"

cat <<EOF

${GRN}${B}Written:${R} $OUT
  size        $(du -h "$OUT" | cut -f1)
  perms       $(stat -c '%A' "$OUT")
  sha256      $(sha256sum "$OUT" | cut -c1-32)…

${B}Now:${R}
  1. Move it by USB or ${B}scp${R} — not email, not Slack, not a git repo,
     not the same directory as your dotfiles.
  2. On the new machine: ${B}./import-secrets.sh <archive>${R}
  3. ${B}shred -u "$OUT"${R} on both ends when you're done.
  4. If this archive ever goes somewhere you didn't intend: rotate the AWS
     keys in IAM and run ${B}gh auth logout${R}. The passphrase is the only
     thing standing between the file and your accounts.
EOF
