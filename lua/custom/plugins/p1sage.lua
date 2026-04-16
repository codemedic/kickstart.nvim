---@module 'lazy'
---@type LazySpec[]
return {
  -- Dependencies for the custom p1sage colorscheme (colors/p1sage.lua)
  { 'rktjmp/lush.nvim', enabled = false },
  {
    'zenbones-theme/zenbones.nvim',
    dependencies = { 'rktjmp/lush.nvim' },
    enabled = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'p1sage'
    end,
  },
}
