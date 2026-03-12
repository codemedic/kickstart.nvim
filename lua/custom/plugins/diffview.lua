vim.api.nvim_create_autocmd('FocusGained', {
  callback = function()
    pcall(function()
      local lib = require 'diffview.lib'
      local view = lib.get_current_view()
      if view then
        view:update_files()
      end
    end)
  end,
})

vim.api.nvim_create_autocmd('User', {
  pattern = 'DiffviewViewLeave',
  callback = function()
    vim.cmd ':DiffviewClose'
  end,
})

return {
  'sindrets/diffview.nvim',
  version = '*',
  config = function()
    require('diffview').setup {
      default_args = {
        DiffviewOpen = { '--imply-local' },
      },
      keymaps = {
        view = {
          { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } },
        },
        file_panel = {
          { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } },
        },
        file_history_panel = {
          { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } },
        },
      },
    }
  end,
}
