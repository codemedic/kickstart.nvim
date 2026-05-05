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

-- Word-boundary navigation — mirrors JetBrains Ctrl+Left / Ctrl+Right.
-- Insert / replace mode: move cursor one word without leaving the mode.
vim.keymap.set('i', '<C-Right>', '<C-\\><C-O>w', { desc = 'Move cursor to next word' })
vim.keymap.set('i', '<C-Left>',  '<C-\\><C-O>b', { desc = 'Move cursor to previous word' })
vim.keymap.set('R', '<C-Right>', '<C-\\><C-O>w', { desc = 'Move cursor to next word' })
vim.keymap.set('R', '<C-Left>',  '<C-\\><C-O>b', { desc = 'Move cursor to previous word' })

-- Visual-mode word selection — mirrors JetBrains Ctrl+Left / Ctrl+Right.
-- w/b move the free end of the selection to the next/prev word boundary,
-- which naturally expands or contracts depending on cursor position vs anchor.
vim.keymap.set('v', '<C-Right>', 'w', { desc = 'Extend/contract selection to next word boundary' })
vim.keymap.set('v', '<C-Left>',  'b', { desc = 'Extend/contract selection to previous word boundary' })

-- Eclipse / IntelliJ navigation compatibility.
-- <C-g>   overrides Neovim's built-in "show file info" — intentional.
-- <C-S-g> requires kitty keyboard protocol (Ghostty).
vim.keymap.set('n', '<C-g>',   'grd',   { remap = true, desc = 'Go to definition (Eclipse Ctrl+G)' })
vim.keymap.set('n', '<C-S-g>', 'grr',   { remap = true, desc = 'Find references (Eclipse Ctrl+Shift+G)' })
vim.keymap.set('n', '<M-Left>',  '<C-o>', { desc = 'Navigate back (Eclipse Alt+Left)' })
vim.keymap.set('n', '<M-Right>', '<C-i>', { desc = 'Navigate forward (Eclipse Alt+Right)' })
