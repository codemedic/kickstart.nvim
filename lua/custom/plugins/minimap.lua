return {
  'echasnovski/mini.map',
  event = 'VeryLazy',
  main = 'mini.map',
  opts = function()
    local minimap = require 'mini.map'
    return {
      symbols = {
        -- encode = minimap.gen_encode_symbols.dot '4x2',
        encode = minimap.gen_encode_symbols.shade '2x1',
        scroll_line = '',
        scroll_view = '▒',
      },
      integrations = {
        minimap.gen_integration.diagnostic {
          error = 'DiagnosticFloatingError',
          warn = 'DiagnosticFloatingWarn',
          info = 'DiagnosticFloatingInfo',
          hint = 'DiagnosticFloatingHint',
        },
        minimap.gen_integration.builtin_search(),
        minimap.gen_integration.gitsigns(),
      },
      window = {
        winblend = 50,
        -- focusable = true,
      },
    }
  end,
  config = function(_, opts)
    require('mini.map').setup(opts)
    local minimap_augroup = vim.api.nvim_create_augroup('minimap', {})
    vim.api.nvim_create_autocmd({ 'VimEnter' }, {
      group = minimap_augroup,
      callback = function()
        require('mini.map').open()
      end,
    })
  end,
  keys = {
    { '<Leader>um', '<cmd>lua MiniMap.toggle()<CR>', desc = 'Toggle Mini map' },
  },
}
