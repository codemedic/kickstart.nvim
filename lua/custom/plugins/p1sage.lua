---@module 'lazy'
---@type LazySpec[]
return {
  -- Disable the upstream default colorscheme
  { 'folke/tokyonight.nvim', enabled = false },

  -- Dependencies for the custom p1sage colorscheme (colors/p1sage.lua)
  { 'rktjmp/lush.nvim' },
  {
    'zenbones-theme/zenbones.nvim',
    dependencies = { 'rktjmp/lush.nvim' },
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'p1sage'
    end,
  },
}
