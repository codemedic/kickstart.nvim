-- P1-Sage: Zenbones-flavoured colorscheme derived from the p1-sage Ghostty theme.
-- Palette maps the phosphor CRT aesthetic onto zenbones semantic roles.

local colors_name = 'p1sage'
vim.g.colors_name = colors_name

local lush = require 'lush'
local hsluv = lush.hsluv
local util = require 'zenbones.util'

-- Only dark background makes sense for a tube-black CRT theme
local bg = 'dark'
vim.o.background = bg

local palette = util.palette_extend({
  bg       = hsluv '#040503', -- tube black
  fg       = hsluv '#76A676', -- electric sage (primary reading colour)
  rose     = hsluv '#D14D4D', -- warm red — errors, keywords
  leaf     = hsluv '#22CC22', -- active P1 phosphor green — strings
  wood     = hsluv '#C9A31E', -- vintage amber-gold — numbers, constants
  water    = hsluv '#4D8FD1', -- steel blue — identifiers, functions
  blossom  = hsluv '#B35FB3', -- muted orchid — types
  sky      = hsluv '#22AAAA', -- teal — specials, operators
}, bg)

local generator = require 'zenbones.specs'
local specs = generator.generate(palette, bg, generator.get_global_config(colors_name, bg))

lush(specs)

require('zenbones.term').apply_colors(palette)
