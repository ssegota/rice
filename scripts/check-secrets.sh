#!/usr/bin/env bash
#
# Scan the rice bundle for anything credential-shaped before you publish or
# copy it. Run this before `git push`, every time.
#
#   ./scripts/check-secrets.sh
#
# Exit 0 = clean, 1 = something found. Suitable as a pre-commit hook:
#   ln -sf ../../scripts/check-secrets.sh .git/hooks/pre-commit
#
set -uo pipefail

RICE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
B=$'\033[1m'; R=$'\033[0m'; RED=$'\033[38;5;210m'; GRN=$'\033[38;5;150m'; YEL=$'\033[38;5;222m'
FOUND=0

hit() { printf '%s✗ %s%s\n    %s\n' "$RED$B" "$1" "$R" "$2"; FOUND=1; }

echo "${B}Scanning $RICE_DIR${R}"

# ── 1. Filenames that shouldn't exist here at all ────────────────────────────
while IFS= read -r f; do
  hit "credential file present" "${f#$RICE_DIR/}"
done < <(find "$RICE_DIR" \( \
      -name 'credentials' -o -name 'hosts.yml' -o -name '.wakatime.cfg' \
      -o -name 'id_rsa*' -o -name 'id_ed25519*' -o -name 'id_ecdsa*' \
      -o -name '*.pem' -o -name '*.ppk' -o -name '.netrc' -o -name '.npmrc' \
      -o -name 'rice-secrets-*' -o -name '*.tar.gz.gpg' \
    \) -not -path '*/.git/*' 2>/dev/null)

# ── 2. Directories that shouldn't exist here at all ──────────────────────────
for d in .aws .ssh .gnupg; do
  while IFS= read -r p; do
    hit "credential directory present" "${p#$RICE_DIR/}"
  done < <(find "$RICE_DIR" -type d -name "$d" -not -path '*/.git/*' 2>/dev/null)
done

# ── 3. High-confidence secret patterns in file contents ──────────────────────
# Deliberately narrow: real key formats, not the word "password" in a comment.
PATTERNS=(
  'AKIA[0-9A-Z]{16}'                       # AWS access key id
  'ASIA[0-9A-Z]{16}'                       # AWS temporary key id
  'aws_secret_access_key[[:space:]]*=[[:space:]]*[A-Za-z0-9/+=]{40}'
  'gh[pousr]_[A-Za-z0-9]{36,}'             # GitHub tokens
  'github_pat_[A-Za-z0-9_]{20,}'
  'oauth_token:[[:space:]]*[A-Za-z0-9_-]{20,}'
  'sk-[A-Za-z0-9]{32,}'                    # OpenAI-style
  'sk-ant-[A-Za-z0-9_-]{20,}'              # Anthropic
  'waka_[0-9a-f]{8}-[0-9a-f]{4}'           # WakaTime
  'xox[baprs]-[A-Za-z0-9-]{10,}'           # Slack
  'AIza[0-9A-Za-z_-]{35}'                  # Google API
  'BEGIN (RSA|OPENSSH|PGP|EC|DSA) PRIVATE KEY'
  'glpat-[A-Za-z0-9_-]{20,}'               # GitLab
)
for pat in "${PATTERNS[@]}"; do
  while IFS= read -r line; do
    hit "secret pattern in file contents" "$line"
  done < <(grep -rIEn --exclude-dir=.git \
             --exclude='check-secrets.sh' --exclude='.gitignore' \
             --exclude-dir=secrets \
             "$pat" "$RICE_DIR" 2>/dev/null | cut -c1-160)
done

# ── 4. Loose reminders ───────────────────────────────────────────────────────
if [ -d "$RICE_DIR/.git" ]; then
  # Probe with real file paths: '.aws/' is a directory-only pattern, so a bare
  # '.aws' never matches and would report a false gap.
  for probe in .aws/credentials .ssh/id_ed25519 .config/gh/hosts.yml .env; do
    if ! git -C "$RICE_DIR" check-ignore -q "$probe" 2>/dev/null; then
      printf '%s! .gitignore is not blocking %s — is the root .gitignore intact?%s\n' "$YEL" "$probe" "$R"
    fi
  done
  if git -C "$RICE_DIR" remote -v 2>/dev/null | grep -q .; then
    printf '%s! this bundle has a git remote configured:%s\n' "$YEL" "$R"
    git -C "$RICE_DIR" remote -v | sed 's/^/    /'
    printf '  %swallpapers/ is ~56 MB — consider excluding it before pushing%s\n' "$YEL" "$R"
  fi
fi

echo
if [ "$FOUND" = 0 ]; then
  printf '%s✓ clean — no credentials found in the bundle%s\n' "$GRN$B" "$R"
  exit 0
else
  printf '%sDo not publish or copy this bundle until the above are removed.%s\n' "$RED$B" "$R"
  printf 'If any of it was already committed, the git history still has it —\n'
  printf 'rotate the credential rather than just deleting the file.\n'
  exit 1
fi
