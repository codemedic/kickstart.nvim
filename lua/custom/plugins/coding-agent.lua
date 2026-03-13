-- Wires up auto-reload and yank-with-path for coding agent (e.g. Claude Code) compatibility.
-- See: https://xata.io/blog/configuring-neovim-coding-agents

local function start_watcher()
  require('custom.directory-watcher').setup { path = vim.fn.getcwd() }
end

vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    require('custom.hotreload').setup()
    start_watcher()
  end,
})

vim.api.nvim_create_autocmd('DirChanged', {
  callback = start_watcher,
})

local yank = require 'custom.yank'

vim.keymap.set('n', '<leader>ya', function()
  yank.yank_path(yank.get_buffer_absolute(), 'absolute')
end, { desc = '[Y]ank [A]bsolute path to clipboard' })

vim.keymap.set('n', '<leader>yr', function()
  yank.yank_path(yank.get_buffer_cwd_relative(), 'relative')
end, { desc = '[Y]ank [R]elative path to clipboard' })

vim.keymap.set('v', '<leader>ya', function()
  yank.yank_visual_with_path(yank.get_buffer_absolute(), 'absolute')
end, { desc = '[Y]ank selection with [A]bsolute path' })

vim.keymap.set('v', '<leader>yr', function()
  yank.yank_visual_with_path(yank.get_buffer_cwd_relative(), 'relative')
end, { desc = '[Y]ank selection with [R]elative path' })

return {}
