-- https://github.com/NeogitOrg/neogit
return {
  'NeogitOrg/neogit',
  lazy = true,
  dependencies = {
    'sindrets/diffview.nvim',
    'nvim-telescope/telescope.nvim',
  },
  cmd = 'Neogit',
  keys = {
    { '<leader>gg', '<cmd>Neogit<cr>', desc = 'Open Neogit (git status)' },
  },
  opts = {
    integrations = {
      diffview = true,
    },
  },
}
