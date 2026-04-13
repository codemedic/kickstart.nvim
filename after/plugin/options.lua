-- Custom options — kept here to avoid merge conflicts with upstream kickstart.nvim.

vim.o.sidescrolloff = 8 -- Columns of context
vim.o.pumblend = 10 -- Popup blend
vim.o.relativenumber = true -- Relative line numbers
vim.o.tabstop = 4 -- Number of spaces tabs count for
vim.o.shiftwidth = 4 -- Size of an indent
vim.o.smartindent = true -- Insert indents automatically
vim.opt.spelllang = { 'en_gb' }

-- Folding — treesitter-based, with mouse-clickable gutter
vim.o.foldmethod = 'expr'
vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.o.foldenable = true
vim.o.foldcolumn = 'auto'
vim.o.foldlevel = 99     -- default: open everything (overridden per filetype)
vim.o.foldlevelstart = 99 -- same for new buffers
