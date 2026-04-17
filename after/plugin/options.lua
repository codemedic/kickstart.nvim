-- Custom options — kept here to avoid merge conflicts with upstream kickstart.nvim.

-- Nerd Font is available in all environments (terminal and GUI).
-- init.lua defaults this to false in GUI; override unconditionally here.
vim.g.have_nerd_font = true

-- diagflow.nvim handles diagnostic display as a top-right float; suppress the
-- default inline virtual text to avoid duplicate/cluttered output.
vim.diagnostic.config({ virtual_text = false })

vim.o.sidescrolloff = 8 -- Columns of context
vim.o.pumblend = 10 -- Popup blend
vim.o.relativenumber = true -- Relative line numbers
vim.o.tabstop = 4 -- Number of spaces tabs count for
vim.o.shiftwidth = 4 -- Size of an indent
vim.o.smartindent = true -- Insert indents automatically
vim.opt.spelllang = { 'en_gb' }
vim.opt.fillchars = { eob = ' ' } -- hide end-of-buffer ~ markers

-- Cursor — per-mode shapes with slow-typewriter blink (long on, brief off)
vim.opt.guicursor = table.concat({
  'n-v-c-sm:block-blinkwait700-blinkoff200-blinkon800',
  'i-ci-ve:ver25-blinkwait700-blinkoff200-blinkon800',
  'r-cr-o:hor20-blinkwait700-blinkoff200-blinkon800',
}, ',')

-- Folding — treesitter-based, no gutter column
vim.o.foldmethod = 'expr'
vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.o.foldenable = true
vim.o.foldcolumn = '0'
vim.o.foldlevel = 99      -- default: open everything (overridden per filetype)
vim.o.foldlevelstart = 99 -- same for new buffers

-- Per-filetype fold overrides.
---@type table<string, { foldminlines?: integer }>
local fold_ft = {
  sh   = { foldminlines = 10 },
  bash = { foldminlines = 10 },
}
local fold_ft_defaults = { foldminlines = 1 }

-- Treesitter attaches asynchronously on FileType. vim.schedule defers until
-- after attachment, then resets foldmethod to force fold recomputation.
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local cfg = vim.tbl_extend('force', fold_ft_defaults, fold_ft[args.match] or {})
    vim.opt_local.foldminlines = cfg.foldminlines
    vim.schedule(function()
      if pcall(vim.treesitter.get_parser, 0) then
        vim.opt_local.foldmethod = 'expr'
      end
    end)
  end,
})

-- When nvim is invoked with +N (e.g. nvim file.txt +1234), open the fold at
-- the cursor so the target line is immediately visible. VimEnter fires after
-- the +line command has positioned the cursor, so zv ("view cursor line")
-- does the right thing. `once = true` limits this to startup only.
vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    vim.cmd('silent! normal! zv')
  end,
})
