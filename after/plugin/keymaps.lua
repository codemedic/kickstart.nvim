-- Custom keymaps — kept here to avoid merge conflicts with upstream kickstart.nvim.

-- Toggle comment — mirrors the VS Code / IntelliJ convention.
-- <C-/> is distinct on Ghostty (kitty keyboard protocol).
-- remap = true is required because gcc/gc are themselves keymaps, not <cmd> calls.
-- Normal mode also moves down one line so you can rapid-fire comment blocks.
vim.keymap.set('n', '<C-/>', 'gccj',     { remap = true, desc = 'Toggle line comment and move down' })
vim.keymap.set('v', '<C-/>', 'gc',       { remap = true, desc = 'Toggle comment on selection' })
vim.keymap.set('i', '<C-/>', '<C-o>gcc', { remap = true, desc = 'Toggle line comment' })

-- Diagnostic summary — one line per loaded buffer, sorted by severity.
vim.keymap.set('n', '<leader>xb', function()
  require('custom.diag-summary').open()
end, { desc = 'Diagnostics: summary by buffer' })

-- Buffer navigation — mirrors IDE/terminal tab switching.
-- Ctrl+PageUp/Down are freed in Ghostty (see ~/.config/ghostty/config).
vim.keymap.set('n', '<C-PageUp>',   '<Cmd>bprev<CR>', { desc = 'Previous buffer' })
vim.keymap.set('n', '<C-PageDown>', '<Cmd>bnext<CR>', { desc = 'Next buffer' })

-- Delete word backwards in insert mode.
-- <C-BS> and <M-BS> are distinct on Ghostty (kitty keyboard protocol).
-- Both map to <C-w> which is Neovim's built-in word-delete.
vim.keymap.set('i', '<C-BS>', '<C-w>', { desc = 'Delete word backwards' })
vim.keymap.set('i', '<M-BS>', '<C-w>', { desc = 'Delete word backwards' })
