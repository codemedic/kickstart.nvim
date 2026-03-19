return {
  'ThePrimeagen/refactoring.nvim',
  event = 'VeryLazy',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    require('refactoring').setup()
    require('telescope').load_extension 'refactoring'

    vim.keymap.set({ 'n', 'x' }, '<leader>rr', function()
      require('telescope').extensions.refactoring.refactors()
    end, { desc = '[R]efactor — open refactoring menu' })
  end,
}
