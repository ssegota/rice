# sbs' rice

Everything needed to rebuild this desktop on a fresh Ubuntu box — and, since
it's been months, a written record of what the setup actually *is*.

Captured **2026-08-05** from Ubuntu 26.04 LTS (`resolute`), kernel 7.0.0-28,
X11 + i3 + LightDM, Croatian keyboard layout. Rethemed **2026-08-08** from
Tokyo Night to Gundam RX-78-2 — see [Theme](#theme--gundam-rx-78-2-federation-armor).

```
┌─ the look ──────────────────────────────────────────────────────────────┐
│  WM          i3 (gaps: 10 inner / 5 outer, smart_gaps, 3px borders)     │
│  Bar         polybar — main bar autohides, secondary bars per monitor   │
│  Compositor  picom                                                      │
│  Launcher    rofi — Gundam theme, plus a rofi power menu                │
│  Prompt      starship — Gundam palette, framed ╭─ … ╰─❯ bubble layout   │
│  Terminals   ghostty (primary) · warp · guake (F12) · kitty · terminator│
│  Font        JetBrainsMono Nerd Font, everywhere                        │
│  Colours     Gundam RX-78-2 "Federation Armor" — see Theme, below       │
│  GTK         Adwaita-dark + Adwaita icons (via nwg-look / lxappearance) │
│  Wallpaper   feh, set from ~/.fehbg at i3 startup                       │
│  Lock        i3lock-fancy — Super+Escape, rofi power menu, and xss-lock │
│  Notifs      dunst — Gundam theme; Super+n pops history                 │
│  Gestures    libinput-gestures — 3-finger swipe = workspace nav         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Install

On a fresh Ubuntu install, as your normal user (not root):

```bash
git clone <wherever-you-put-this> ~/rice    # or copy the directory over
cd ~/rice
./install.sh --dry-run --all                # read what it plans to do
./install.sh                                # then actually do it
```

It's staged and re-runnable. Anything it replaces in `$HOME` is copied to
`~/.rice-backup-<timestamp>/` first.

```bash
./install.sh --list         # show all stages
./install.sh --dotfiles     # just the configs
./install.sh --fonts --external
./install.sh -y --all       # unattended
```

| Stage | Does |
|---|---|
| `--sources` | adds third-party apt repos (Chrome, Warp, Tailscale, NodeSource, Waydroid, 2 PPAs) |
| `--packages` | ~120 apt packages from `packages/apt-rice.txt` |
| `--snaps` | snaps from `packages/snap-rice.txt` |
| `--external` | starship, uv, flyctl, libinput-gestures, vim-plug, `fd` symlink, greenclip |
| `--dotfiles` | configs into `$HOME`, with backups |
| `--wallpapers` | images into `~/Pictures/wallpapers` |
| `--fonts` | downloads JetBrainsMono Nerd Font |
| `--editors` | VS Code / Cursor `settings.json` + extensions |
| `--services` | enables `tlp`, prints session notes |

Then log out and pick **i3** at the LightDM session menu.

> `packages/apt-rice.txt` includes **`texlive-full`** (several GB). Comment it
> out first if you don't want to wait.

## Layout

```
rice/
├── install.sh                  the installer
├── dotfiles/
│   ├── home/                   → $HOME          .bashrc .profile .vimrc .gitconfig …
│   ├── config/                 → ~/.config      i3 polybar picom rofi ghostty starship …
│   │   └── gundam/palette.md   the eleven colours every config draws from
│   └── local-bin/              → ~/.local/bin   rofi-power rofi-wallpaper gundam-theme
├── wallpapers/                 32 images (~56 MB) → ~/Pictures/wallpapers
├── fonts/install-fonts.sh      JetBrainsMono Nerd Font
├── packages/
│   ├── apt-rice.txt            curated + commented — the one to read
│   ├── apt-manual-full.txt     raw `apt-mark showmanual` (161)
│   ├── apt-thirdparty.txt      needs repos added first
│   ├── snap-rice.txt           curated snaps
│   ├── dpkg-all.txt            every installed package, for archaeology
│   └── external-tools.md       what came from curl-pipe installers
├── editors/                    VS Code + Cursor settings, extension list
├── system/                     machine snapshot, apt source inventory, greeter conf
├── scripts/
│   ├── apt-sources.sh          adds the third-party repos
│   └── check-secrets.sh        run before publishing — scans for credentials
└── secrets/                    NO credentials here — read its README
```

## Keybinds

`$mod` = **Super**. Focus/move is vim-standard `h j k l` 🆕 (it used to be
i3's shifted `j k l č` — the `č` sat where `;` is on a US layout). Horizontal
split moved to `Super+b` ("beside") to free up the `h`.

| | |
|---|---|
| 🆕 `Super+F1` | **this table, live** — searchable rofi cheat sheet parsed from the i3 config; Enter runs the selected bind |
| `Super+Return` | ghostty |
| `Super+Shift+Return` | warp-terminal |
| `F12` | guake dropdown |
| `Super+d` | rofi (drun) |
| `Super+Tab` | rofi window switcher |
| `Super+Shift+e` | rofi power menu |
| `Super+Escape` | lock (i3lock-fancy) |
| `Print` | flameshot |
| `Super+Shift+q` | kill window |
| `Super+f` | fullscreen |
| 🆕 `Super+b` / `Super+v` | split horizontal / vertical (was `h`/`v`) |
| `Super+s` / `Super+w` / `Super+e` | stacking / tabbed / toggle split |
| `Super+Shift+space` | floating toggle |
| `Super+r` | resize mode |
| `Super+minus` / `Super+Shift+minus` | scratchpad show / send |
| `Super+p` | attach HDMI-1 to the left |
| `Super+1…0` | workspace; add `Shift` to move the window there |
| `Super+Shift+c` / `Super+Shift+r` | reload / restart i3 |
| 3-finger swipe L/R | previous / next workspace |
| 3-finger swipe up | last workspace (`back_and_forth`) |
| 🆕 `Super+Shift+w` | wallpaper picker (rofi, with thumbnails) |
| 🆕 `Super+c` | clipboard history (greenclip → rofi) |
| 🆕 `Super+n` / `Super+Shift+n` | notification history / close all (dunst) |
| 🆕 `Super+<current ws number>` | jumps back to the previous workspace |
| 🆕 volume keys | 5% steps now, capped at 100% (was ±10%, uncapped) |
| 🆕 play / next / prev media keys | playerctl |
| 🆕 brightness keys | brightnessctl ±5% (was polybar-scroll only) |

🆕 = added in round 2 (see below) — try them out.

## Shell

`.bashrc` is where most of the quality-of-life lives:

- **History** 100k entries, deduped, timestamped, shared live across terminals
- **Arrow keys** do prefix history search
- **fzf** `Ctrl+R` history, `Ctrl+T` files, `Alt+C` cd — all with `bat` previews
- **zoxide** `z` / `zi` for frecency-based cd
- **`ls`→eza** (`--icons --group-directories-first`), `ll`, `lt` (tree)
- **`cat`→bat**, and `bat` colourises man pages via `MANPAGER`
- **`extract`** one function for any archive format
- `shopt` — `autocd`, `cdspell`, `dirspell`, `globstar`
- `cp`/`mv`/`mkdir` aliased to interactive+verbose
- `EDITOR=code`, conda init block, `~/.local/bin` and `~/.fly/bin` on `PATH`

## Theme — Gundam RX-78-2 "Federation Armor"

Added **2026-08-08**, replacing Tokyo Night everywhere. The palette is lifted
from the homelab dashboard's `:root` block (http://192.168.1.118/), so the
desktop and the dashboard read as one machine. Eleven colours, and nothing
outside them:

| Token | Hex | Role |
|---|---|---|
| `armor` | `#e6e7e2` | body background — the white armour panel |
| `armor-hi` | `#f8f9f6` | raised panel (cards, list rows) |
| `armor-lo` | `#d2d4ce` | recessed surface (meter tracks, inset fields) |
| `line` | `#b0b3ac` | panel seams / borders |
| `ink` | `#15181f` | primary text |
| `ink-dim` | `#545a66` | secondary text |
| `blue` | `#24408e` | Federation blue — focus, primary chrome |
| `blue-deep` | `#1a2f6b` | pressed / deeper blue |
| `red` | `#c0272d` | chest red — urgent, destructive, active accent |
| `yellow` | `#f0b929` | V-fin yellow — hazard stripes, warning fills |
| `eye` | `#3f9e56` | camera-eye green — "nominal" |

Rules carried over from the page: **no border radius** (square, or chamfered
top-right), hazard stripes at -45° between a header and its body, uppercase
letterspaced labels with tabular-mono values, and a 4px colour-coded left
border to state a row's status. **Yellow is a fill, never text** — `#f0b929`
is ~1.6:1 on armour white, so anywhere yellow *text* is needed the configs use
`#7d5a00` instead. Full rationale: [`dotfiles/config/gundam/palette.md`](dotfiles/config/gundam/palette.md).

### Chrome vs. terminals

The split is deliberate — the chrome is the outside of the machine and stays
armour white in every variant; only the terminals switch.

```
chrome (always armour white)      terminals (three variants, pick one)
├── polybar/config.ini            ├── ghostty/themes/gundam-{armor,panel,cockpit}.conf
├── rofi/themes/gundam.rasi       ├── kitty/themes/gundam-{armor,panel,cockpit}.conf
├── dunst/dunstrc                 ├── btop/themes/gundam-{armor,panel,cockpit}.theme
└── i3/config  (client.* block)   ├── starship.toml  (palette = …)
                                  └── ~/.claude/settings.json  (theme = …)
```

### Switching variants

```bash
gundam-theme            # print the active variant
gundam-theme armor      # light, ground #e6e7e2 — the dashboard's own colours
gundam-theme panel      # light, ground #d2d4ce — same hues, greyer, less glare
gundam-theme cockpit    # the previous dark theme, for night work
```

| Variant | Ground | Opacity | For |
|---|---|---|---|
| `armor` | `#e6e7e2` | 0.97 | daylight; matches the dashboard exactly |
| `panel` | `#d2d4ce` | **0.90** | dim rooms — recessed grey, and the most see-through |
| `cockpit` | `#12141a` | 0.95 | night work |

The ANSI palette is byte-identical across `armor` and `panel` — every colour
was picked to stay legible on both grounds, so switching changes only the
ground and the opacity.

`gundam-theme` repoints the `gundam-active.conf` symlink that ghostty and kitty
both include, rewrites btop's `color_theme` line, flips starship's
`palette =`, and sets Claude Code's `theme` in `~/.claude/settings.json`
(light for armor/panel, dark for cockpit — its TUI paints its own colours, and
its dark-theme blue is ~1.6:1 on armour white). Reloads are not all free:

- **ghostty** — `ctrl+shift+,` (no IPC reload), or just open a new window
- **kitty** — `ctrl+shift+f5`; the script also tries `kitty @ load-config`
- **btop** — reads its theme once at startup, so restart it
- **starship** — next prompt, or `exec bash`
- **claude** — live; it watches settings.json

Changing polybar/rofi/dunst/i3 colours means editing those files directly;
they're single-variant by design.

> The pre-gundam (all-dark) configs were saved to
> `~/gundam-dark-backup-2026-08-08/` on the live machine. That directory is
> **not** in this bundle — the pre-gundam state is in git history instead.

## Repairs made 2026-08-05

Seven inconsistencies surfaced while packaging this up. Five were fixed in both
the live machine and this bundle; two are intentional and documented so nobody
"fixes" them later.

### Fixed

1. **`fd` didn't exist.** `.bashrc` sets `FZF_DEFAULT_COMMAND='fd --type f …'`,
   but Ubuntu's `fd-find` installs the binary as **`fdfind`** — so `Ctrl+T` and
   `Alt+C` silently returned nothing. Now symlinked:
   `~/.local/bin/fd → /usr/bin/fdfind`. `install.sh --external` does this on a
   new machine.
2. **The rofi power menu's Lock entry did nothing.** `rofi-power` called
   `betterlockscreen`, which was never installed. It now calls
   **`i3lock-fancy -gp`** — the same locker `Super+Escape` and `xss-lock`
   already use, so all three lock paths are consistent and no extra package is
   needed.
3. **`rofi/config.rasi` pointed at `alacritty`**, which isn't installed → now
   **`ghostty`**. Its `icon-theme: "Papirus"` is kept, and
   `papirus-icon-theme` is now in `packages/apt-rice.txt` so the theme actually
   resolves instead of falling back.
4. **Removed the stale `~/.config/nitrogen/`.** Wallpapers are set by `feh` via
   `~/.fehbg`; nitrogen wasn't installed and the config was doing nothing.
5. **Wrote `~/.config/kitty/kitty.conf`.** kitty was running on stock config
   despite being installed. It's now a faithful port of the ghostty config —
   same JetBrainsMono Nerd Font at 13pt, byte-identical Tokyo Night palette,
   `0.95` opacity, `8 12` padding matching ghostty's `y=8 / x=12`, beam cursor
   with blink off, 100k scrollback, copy-on-select, and the same two split
   binds (`ctrl+shift+enter` vertical, `ctrl+shift+minus` horizontal) plus
   `ctrl+shift+h/j/k/l` to move between them. Validated against kitty 0.45's
   own parser — every option resolves, no unknown keys.

### Intentional — leave these alone

6. **`~/.fehbg` passes two images in one `feh` command**
   (`osselo-Ask_a_friend.jpg` and `v-eva.png`). feh assigns one per monitor in
   output order. This is deliberate: different wallpaper per screen.
7. **The conda block in `.bashrc` hard-codes `/home/sbs/anaconda3`.** Kept as-is.
   On a machine without Anaconda it prints an error on every shell start, so
   `install.sh` warns about it — install Anaconda, or delete the
   `>>> conda initialize >>>` block on that machine only.

## Round 2 — 2026-08-05, same day

A second pass fixed what the first packaging round missed and added a few
quality-of-life tools. Everything below is in both the bundle and the live
machine.

### Fixed

1. **`picom.conf` was two whole configs concatenated** — conflicting values
   (corner-radius 12 vs 8, inactive-opacity 0.9 vs 1.0), plus a typo
   (`cladd_g`) that killed the Guake slide-in animation, plus deprecated
   `:c`/`:a` type specifiers and `mark-*-focused` options. Merged into one
   config; typo fixed; picom v12.5 parses it warning-free.
2. **The rice wasn't actually Tokyo Night outside the terminals.** Polybar's
   palette was Nord, i3's window borders were arbitrary blues, rofi was a
   grey macOS-Spotlight clone. All three now use the exact palette from
   `starship.toml` (bg `#1a1b26`, fg `#c0caf5`, accent `#7aa2f7`,
   urgent `#f7768e`).
3. **rofi's theme asked for Montserrat**, which was never installed anywhere —
   silent fallback to a default sans. Now JetBrainsMono Nerd Font like
   everything else.
4. **i3's titlebar font was stock `monospace 8`** → JetBrainsMono Nerd Font 10.
5. **Hardware keys**: brightness keys now work (`brightnessctl`), media keys
   now work (`playerctl`), volume steps are 5% capped at 100% via `wpctl`
   (were 10% and could exceed 100%).
6. **`.fehbg` referenced `/usr/share/backgrounds/`** — a path that only exists
   on stock Ubuntu. Both images now live in `~/Pictures/wallpapers`, and the
   i3 config runs `~/.fehbg` instead of duplicating the feh command. The
   15 commented-out wallpaper lines in the i3 config are gone — use the
   `Super+Shift+w` picker instead.
7. **Screens never powered down** (`xset -dpms`). DPMS now blanks after
   10 idle minutes; the X screensaver stays off.

### Added

- **dunst is themed** (`config/dunst/dunstrc`) — Tokyo Night, rounded,
  Papirus icons. `Super+n` re-shows the last notification,
  `Super+Shift+n` clears all.
- **`rofi-keybinds`** (`Super+F1`) — searchable keybind cheat sheet, parsed
  live from the i3 config so it can't go stale; Enter executes the selected
  bind via i3-msg.
- **`rofi-wallpaper`** (`Super+Shift+w`) — thumbnail picker over
  `~/Pictures/wallpapers`; persists via `~/.fehbg`. Enter sets the image on
  the focused monitor only (the rest keep theirs); Alt+1 sets it everywhere.
- **greenclip** (`Super+c`) — clipboard history, daemon started by i3.
- **autotiling** — splits alternate h/v automatically by window shape.
- **autorandr** — current two-monitor layout saved as profile `home`.
  Save one per dock (`autorandr --save officedock`), then the hardcoded
  xrandr lines in the i3 config can go. Installed as a uv tool for now;
  `sudo apt install autorandr` adds hotplug udev rules.
- `workspace_auto_back_and_forth` — tapping the current workspace's number
  bounces back to the previous one.
- **Focus/move keys are now vim-standard `h j k l`** (also in resize mode);
  horizontal split relocated to `Super+b`. The `č` key is retired.

## Not captured

- **`~/anaconda3`** — reinstall from the Anaconda installer, then recreate envs
  from your own `environment.yml` files.
- **App data** for Obsidian vaults, OBS scenes, VirtualBox VMs, Steam/Lutris
  games, Thunderbird/Evolution profiles. Big, and mostly not "config".
- **AI CLI logins** (claude, cursor-agent, codex, copilot) — re-auth each.
- **Credentials** — deliberately, see below.
- **`texlive-full`** package selections beyond the metapackage.

## Secrets

You asked for AWS and GitHub logins to ride along in the install script. They
don't, and the root `.gitignore` blocks them from being added later.

Short version: a rice bundle is the most-copied and most-published directory a
Linux user owns, and `~/.aws/credentials` holds **long-lived static keys** for
four profiles. Static IAM keys don't expire and aren't device-bound, so one
leaked copy is usable by anyone, from anywhere, indefinitely — and a `git push`
can't be undone.

(Your GitHub token is *not* at risk here — `gh` keeps it in the system keyring,
so `~/.config/gh/hosts.yml` holds no credential at all.)

Instead:

- **Recommended** — `gh auth login` and `aws configure sso` on the new machine.
  Faster than moving files, and nothing sensitive is ever in transit.
- **If you want the lot moved as-is** — `secrets/export-secrets.sh` builds one
  GPG/AES-256 encrypted archive *outside* this directory, and
  `secrets/import-secrets.sh` restores it and fixes permissions.

Full reasoning and the leak-response steps: **[`secrets/README.md`](secrets/README.md)**.

Also: `~/.wakatime.cfg` contained a live API key, so the bundled copy is
`.wakatime.cfg.template` with the key stripped.

Before you ever push this anywhere:

```bash
./scripts/check-secrets.sh      # exit 0 = clean; works as a pre-commit hook
```
