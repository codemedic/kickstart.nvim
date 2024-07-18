return {
  {
    'mrjones2014/smart-splits.nvim',
    event = 'VeryLazy',
    version = '>=1.0.0',
    dependencies = {
      'kwkarlwang/bufresize.nvim',
    },

    keys = function()
      local splits = require 'smart-splits'
      return {
        -- resizing splits
        { '<A-h>', splits.resize_left, mode = { 'n' }, desc = 'Resize split left' },
        { '<A-j>', splits.resize_down, mode = { 'n' }, desc = 'Resize split down' },
        { '<A-k>', splits.resize_up, mode = { 'n' }, desc = 'Resize split up' },
        { '<A-l>', splits.resize_right, mode = { 'n' }, desc = 'Resize split right' },
        { '<A-S-Left>', splits.resize_left, mode = { 'n' }, desc = 'Resize split left' },
        { '<A-S-Down>', splits.resize_down, mode = { 'n' }, desc = 'Resize split down' },
        { '<A-S-Up>', splits.resize_up, mode = { 'n' }, desc = 'Resize split up' },
        { '<A-S-Right>', splits.resize_right, mode = { 'n' }, desc = 'Resize split right' },
        -- moving between splits
        { '<C-h>', splits.move_cursor_left, mode = { 'n' }, desc = 'Move to split on left' },
        { '<C-j>', splits.move_cursor_down, mode = { 'n' }, desc = 'Move to split below' },
        { '<C-k>', splits.move_cursor_up, mode = { 'n' }, desc = 'Move to split above' },
        { '<C-l>', splits.move_cursor_right, mode = { 'n' }, desc = 'Move to split on right' },
        { '<C-S-Left>', splits.move_cursor_left, mode = { 'n' }, desc = 'Move to split on left' },
        { '<C-S-Down>', splits.move_cursor_down, mode = { 'n' }, desc = 'Move to split below' },
        { '<C-S-Up>', splits.move_cursor_up, mode = { 'n' }, desc = 'Move to split above' },
        { '<C-S-Right>', splits.move_cursor_right, mode = { 'n' }, desc = 'Move to split on right' },
        { '<C-\\>', splits.move_cursor_previous, mode = { 'n' }, desc = 'Move to previous split' },
        -- swapping buffers between windows
        { '<leader>ssh', splits.swap_buf_left, mode = { 'n' }, desc = 'Swap buffer to left' },
        { '<leader>ssj', splits.swap_buf_down, mode = { 'n' }, desc = 'Swap buffer to below' },
        { '<leader>ssk', splits.swap_buf_up, mode = { 'n' }, desc = 'Swap buffer to above' },
        { '<leader>ssl', splits.swap_buf_right, mode = { 'n' }, desc = 'Swap buffer to right' },
      }
    end,
    config = function()
      require('smart-splits').setup {
        resize_mode = {
          hooks = {
            on_leave = require('bufresize').register,
          },
        },
      }
    end,
  },
}
