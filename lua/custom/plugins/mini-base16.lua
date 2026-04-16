---@module 'lazy'
---@type LazySpec[]
return {
  -- mini.nvim is already in the stack; this just configures mini.base16
  -- with the p1-sage Ghostty palette mapped to base16 slots.
  --
  -- Base16 slot mapping:
  --   base00-07  background → foreground gradient (darkest to lightest)
  --   base08-0F  accent colours (red, orange, yellow, green, cyan, blue, magenta, special)
  --
  -- Accent mixing formula (all derived from p1-sage source values):
  --   Muted normals  — p1-sage normal ANSI: S reduced ~30%, L reduced ~8%
  --   Semi-vivid     — midpoint(normal, bright) for slots with no direct normal equivalent
  {
    'echasnovski/mini.nvim',
    priority = 1000,
    config = function()
      require('mini.base16').setup {
        palette = {
          -- Surfaces — tube black → mint flare (unchanged from p1-sage spec)
          base00 = '#040503', -- tube black (bg)
          base01 = '#1A2010', -- ANSI 0  — lighter bg, status bars, line nr
          base02 = '#1A3318', -- selection bg — ghostty selection-background
          base03 = '#323D24', -- ANSI 8  — comments, invisibles
          base04 = '#76A676', -- electric sage — dark fg for inactive UI
          base05 = '#A8C4A8', -- ANSI 7  — default fg, delimiters, operators
          base06 = '#D0F0C8', -- selection fg — light fg
          base07 = '#D8F2D8', -- ANSI 15 — lightest (headings, highlights)

          -- Accents — all derived from p1-sage; see mixing formula above
          -- source: red    #D14D4D → muted (S-30%, L-8%)
          base08 = '#A35858', -- muted red      : variables, errors, diff del
          -- source: midpoint(#D14D4D red, #FF6E6E bright-red) → semi-vivid warm
          base09 = '#BA6060', -- semi-vivid warm: integers, booleans (orange sub)
          -- source: yellow #C9A31E → muted (S-30%, L-8%)
          base0A = '#A88820', -- muted gold     : classes, search bg
          -- source: green  #22CC22 → muted (S-30%, L-8%)
          base0B = '#259A25', -- muted P1 green : strings, diff add
          -- source: cyan   #22AAAA → muted (S-30%, L-8%)
          base0C = '#228080', -- muted teal     : support, regex, escape chars
          -- source: blue   #4D8FD1 → muted (S-30%, L-8%)
          base0D = '#5580B0', -- muted steel    : functions, headings
          -- source: magenta#B35FB3 → muted (S-30%, L-8%)
          base0E = '#8A5A8A', -- muted orchid   : keywords, diff change
          -- source: midpoint(#C9A31E yellow, #FFD733 bright-yellow) → semi-vivid
          base0F = '#B89820', -- semi-vivid amber: deprecated, embedded tags
        },
        use_cterm = true, -- also populate cterm colour slots
      }
      vim.g.colors_name = 'p1-mini-base16'
    end,
  },
}
