# Nvim Notes

## Treesitter: Clean Slate Reset

To fully reset all installed parsers, remove all three state directories:

```bash
rm -rf ~/.local/share/nvim/site/parser/
rm -rf ~/.local/share/nvim/site/parser-info/
rm -rf ~/.local/share/nvim/site/queries/
```

Deleting only `parser/` leaves stale `parser-info/` and `queries/` entries, causing `TSInstall` to silently skip reinstallation (it considers the language already installed if queries exist).

Use `:TSInstall! <lang>` (with bang) to force reinstall without clearing directories.

---

## Colorscheme — P1-Sage Ghostty Sync

### Terminal Theme

The Ghostty terminal runs the **p1-sage** theme — a custom CRT phosphor design:

- **Philosophy:** P1 (525nm) phosphor tube, desaturated for ergonomic daily use
- **Background:** `#040503` — "tube black" (near-black, simulates lit vacuum)
- **Foreground:** `#76A676` — electric sage (primary reading colour)
- **ANSI palette:** warm-spectrum, green-dominant, no orange
- **Spec:** `~/.config/ghostty/p1-sage-spec.md`
- **Theme file:** `~/.config/ghostty/themes/p1-sage`

### Themes Tried (in order)

| Theme | Verdict |
|---|---|
| `folke/tokyonight.nvim` | Upstream default; too blue, not p1-sage aligned |
| `everviolet/nvim` (evergarden, winter) | Not as good as expected |
| `sainnhe/everforest` (hard dark) | Too milky — background `#272e33` too light vs tube black |
| `rebelot/kanagawa.nvim` (dragon) | Too warm/red-tinted |
| `rombrom/fansi2` | ANSI-originated but uses author's hardcoded Bluebox hex — not p1-sage aligned |
| `bjarneo/pixel.nvim` | Truly ANSI-only (disables termguicolors) but output disappointing |
| Custom **p1sage** (zenbones + lush) | Solid structure; palette mapped cleanly but shelved for now |
| Custom **p1fansi** (fansi2 adapted) | Good ANSI structure but plugin coverage limited |
| **`echasnovski/mini.base16`** ✅ | **Settled.** 30+ plugin integrations, palette fully derived from p1-sage |

### Settled: mini.base16 with p1-sage Palette

**Plugin:** `echasnovski/mini.base16` (part of `mini.nvim`, already in stack)
**Config:** `lua/custom/plugins/mini-base16.lua`

#### Palette Design

**Surfaces (base00–07)** — taken directly from p1-sage spec, dark → light:

| Slot | Hex | Source |
|---|---|---|
| base00 | `#040503` | tube black (bg) |
| base01 | `#1A2010` | ANSI 0 — status bars, line nr bg |
| base02 | `#1A3318` | Ghostty selection-background |
| base03 | `#506840` | ~40% lerp(ANSI 8, fg) — comments, gutter |
| base04 | `#76A676` | electric sage — inactive UI fg |
| base05 | `#A8C4A8` | ANSI 7 — default fg, delimiters |
| base06 | `#D0F0C8` | Ghostty selection-foreground |
| base07 | `#D8F2D8` | ANSI 15 — brightest highlights |

**Accents (base08–0F)** — derived from p1-sage ANSI normals using: S−30%, L−8%.
Slots with no direct normal equivalent use `midpoint(normal, bright)`:

| Slot | Hex | Source | Role |
|---|---|---|---|
| base08 | `#A35858` | muted ANSI 1 red | variables, errors |
| base09 | `#BA6060` | midpoint(red, bright-red) | integers, booleans |
| base0A | `#A88820` | muted ANSI 3 yellow | classes, search bg |
| base0B | `#259A25` | muted ANSI 2 green | strings, diff add |
| base0C | `#228080` | muted ANSI 6 cyan | support, regex |
| base0D | `#5580B0` | muted ANSI 4 blue | functions, headings |
| base0E | `#8A5A8A` | muted ANSI 5 magenta | keywords, diff change |
| base0F | `#B89820` | midpoint(yellow, bright-yellow) | deprecated, embedded |

#### Kept Alternatives

- `colors/p1sage.lua` — zenbones/lush variant; re-enable via `lua/custom/plugins/p1sage.lua`
- `colors/p1fansi.lua` — fansi2-structured variant; re-enable via `lua/custom/plugins/ansi-themes.lua`
