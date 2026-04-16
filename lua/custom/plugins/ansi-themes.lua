---@module 'lazy'
---@type LazySpec[]
return {
  -- Disable the upstream default colorscheme
  { 'folke/tokyonight.nvim', enabled = false },

  -- Truly ANSI-only: disables termguicolors and maps syntax to terminal color
  -- indices 0-15, so it inherits the p1-sage Ghostty palette automatically.
  {
    'bjarneo/pixel.nvim',
    enabled = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'pixel'
    end,
  },

  -- fansi2 adapted to p1-sage palette; loaded as a local colors/ file.
  -- The upstream plugin is kept disabled — no external dep needed.
  {
    'rombrom/fansi2',
    enabled = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'fansi2'
    end,
  },

  -- Activate the local p1fansi colorscheme (colors/p1fansi.lua)
  {
    dir = vim.fn.stdpath 'config',
    name = 'p1fansi',
    enabled = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'p1fansi'
    end,
  },
}
