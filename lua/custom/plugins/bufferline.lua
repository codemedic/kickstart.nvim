return {
  'akinsho/bufferline.nvim',
  event = 'VeryLazy',
  version = '*',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require('bufferline').setup {
      options = {
        right_mouse_command = nil,
        middle_mouse_command = 'bdelete! %d',
        offsets = {
          {
            filetype = 'neo-tree',
          },
        },
      },
    }
  end,
}
