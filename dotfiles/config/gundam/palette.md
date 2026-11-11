# Gundam RX-78-2 "Federation Armor" — palette

Lifted from the homelab dashboard at http://192.168.1.118/ (its `:root` block).
Every config in this rice draws from these eleven values and nothing else.

| Token       | Hex       | Role                                              |
|-------------|-----------|---------------------------------------------------|
| `armor`     | `#e6e7e2` | body background — the white armour panel          |
| `armor-hi`  | `#f8f9f6` | raised panel (cards, list rows)                   |
| `armor-lo`  | `#d2d4ce` | recessed surface (meter tracks, inset fields)     |
| `line`      | `#b0b3ac` | panel seams / borders                             |
| `ink`       | `#15181f` | primary text                                      |
| `ink-dim`   | `#545a66` | secondary text                                    |
| `blue`      | `#24408e` | Federation blue — focus, primary chrome           |
| `blue-deep` | `#1a2f6b` | pressed / deeper blue                             |
| `red`       | `#c0272d` | chest red — urgent, destructive, active accent    |
| `yellow`    | `#f0b929` | V-fin yellow — hazard stripes, warning fills      |
| `eye`       | `#3f9e56` | camera-eye green — "nominal"                      |

## Rules the page follows, which this rice follows too

- **No border radius.** Corners are square, or chamfered (cut) at the top-right.
- **Hazard stripes** (`yellow`/`ink` at -45°) separate a header from its body.
- **Labels are uppercase with wide letterspacing**; values are tabular mono.
- **Yellow is a fill, never text.** On a light ground `#f0b929` is ~1.6:1 contrast.
  Where the page needs yellow *text* it uses `#7d5a00` — so does this rice.
- **Left border, 4px, colour-coded** is how a row states its status:
  blue = normal, red = attention, green = up/writable, grey = unknown.

## The three variants

Every one of the eleven roles is filled in all three; only the values move.

| Role        | ARMOR     | PANEL     | COCKPIT   |
|-------------|-----------|-----------|-----------|
| `armor`     | `#e6e7e2` | `#d2d4ce` | `#12141a` |
| `armor-hi`  | `#f8f9f6` | `#e6e7e2` | `#1b1f28` |
| `armor-lo`  | `#d2d4ce` | `#bec1ba` | `#0c0e13` |
| `line`      | `#b0b3ac` | `#9ca098` | `#2f3646` |
| `ink`       | `#15181f` | `#15181f` | `#e8eaf2` |
| `ink-dim`   | `#545a66` | `#545a66` | `#8b93a7` |
| `blue`      | `#24408e` | `#24408e` | `#5b83d6` |
| `blue-deep` | `#1a2f6b` | `#1a2f6b` | `#2b3a5e` |
| `red`       | `#c0272d` | `#c0272d` | `#e63946` |
| `yellow`    | `#f0b929` | `#f0b929` | `#f6c14e` |
| `yellow-ink`| `#7d5a00` | `#7d5a00` | `#f0b929` |
| `eye`       | `#3f9e56` | `#3f9e56` | `#7fc76c` |

**ARMOR** is the dashboard, unaltered.

**PANEL** drops the ground to `--armor-lo` and steps every surface below it down
by the same `(-20, -19, -20)` the dashboard puts between `--armor` and
`--armor-lo`. Accents do not move: they were chosen to hold on both grounds.

**COCKPIT** takes its ground and ink from the cockpit terminal theme, so the bar,
the notification card and ghostty all sit on one black. The accents are the
Federation hues lifted until they clear 4.5:1 on it — `#24408e` unchanged would
land at 1.4:1. Two of the light-theme rules invert here:

- **Yellow becomes text.** `#f0b929` reads at 10.2:1 on this ground, so
  `yellow-ink` is finally the real V-fin yellow rather than the `#7d5a00`
  substitute the light variants need.
- **The slab splits from the blue you read.** `blue` is used two ways: as text
  on the ground, and as a filled block with text on top (focused workspace,
  rofi's gate-head, the selected row). One value serves both on a light ground.
  On this one they pull apart — white on the lifted `#5b83d6` is only 3.7:1 —
  so a filled slab uses `blue-deep` `#2b3a5e`, which is also the cockpit
  terminal's selection colour, and `#5b83d6` stays the blue you read. Consumers
  name which they mean: `slab`, `on-slab`, `on-red`.

## Layout

Everything follows the variant — chrome included.

    chrome                              terminals
    ├── polybar/themes/gundam-*.ini     ├── ghostty/themes/gundam-*.conf
    ├── rofi/themes/gundam-colors-*     ├── kitty/themes/gundam-*.conf
    ├── dunst/themes/gundam-*.conf      ├── btop/themes/gundam-*.theme
    └── i3/themes/gundam-*.conf         ├── starship.toml (palette = ...)
                                        ├── ~/.claude/settings.json (theme = ...)
    wallpaper                           └── fastfetch (ANSI-only — follows
    └── gundam/wallpapers.conf                 every variant untouched)

Each app keeps one file per variant plus a `gundam-active` symlink that
`gundam-theme` repoints; the host config includes or imports the symlink and
never names a colour itself. Two exceptions:

- **rofi** — `@import` in rofi 2.0 does not merge properties across files, so
  `gundam-active.rasi` is *generated* by concatenating
  `gundam-colors-<variant>.rasi` with `gundam-body.rasi`. Edit those two; never
  the generated file. `highlight` also refuses a token reference, so that one
  rule carries a literal and lives in the colours file.
- **dunst** — has no include either, but does read `dunstrc.d/*.conf` drop-ins,
  which outrank `dunstrc`. `50-gundam-active.conf` is the symlink; `dunstrc`
  itself holds shape only, and a colour set there would silently do nothing.

Claude Code is in the terminals column because it paints its own TUI rather than
using the terminal's sixteen colours: left on `dark`, its blue sits at about
1.6:1 on armour white. `gundam-theme` flips it to `light` for ARMOR and PANEL.

## Wallpaper

`~/.config/gundam/wallpapers.conf` maps each variant to one image per monitor,
sorted by measured mean luminance (`identify -format '%[fx:mean*100]'`) — bright
for ARMOR, mid for PANEL, dark for COCKPIT. `gundam-theme` applies them with
feh, which rewrites `~/.fehbg`, so the choice survives a login. Delete a
variant's line to have the wallpaper left alone; `gundam-theme <v> -k` skips it
once. Picking by hand afterwards (`Super+Shift+w`) wins until the next switch.

## Switching

`gundam-theme armor|panel|cockpit`, or `Super+Shift+t` for the rofi picker
(`rofi-gundam`). Only ghostty and btop need a manual nudge afterwards; the bar,
borders, notifications, rofi, kitty, starship, Claude Code and the wallpaper all
reload themselves.

Previous (pre-rice, all-dark) configs: `~/gundam-dark-backup-2026-08-08/`.
Configs as they were before chrome learned to follow the variant:
`~/gundam-chrome-backup-2026-09-01/`.
