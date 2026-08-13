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

## Layout

    chrome (always armour white)     terminals (three variants, pick one)
    ├── polybar/config.ini           ├── ghostty/themes/gundam-armor.conf
    ├── rofi/themes/gundam.rasi      ├── ghostty/themes/gundam-panel.conf
    ├── dunst/dunstrc                ├── ghostty/themes/gundam-cockpit.conf
    └── i3/config  (client.* block)  ├── kitty/themes/*.conf
                                     ├── btop/themes/gundam-{armor,panel,cockpit}.theme
                                     ├── starship.toml (palette = ...)
                                     ├── ~/.claude/settings.json (theme = ...)
                                     └── fastfetch (ANSI-only — follows every variant untouched)

Claude Code is in that column because it paints its own TUI rather than using
the terminal's sixteen colours: left on `dark`, its blue sits at about 1.6:1 on
armour white. `gundam-theme` flips it to `light` for ARMOR and PANEL.

Switch the terminal variant with `gundam-theme armor|panel|cockpit`, or
`Super+t` for the rofi picker (`rofi-gundam`). `cockpit` is the previous
dark theme, kept for night work.

Previous (all-dark) configs: `~/gundam-dark-backup-2026-08-08/`
