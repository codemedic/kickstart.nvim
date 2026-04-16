-- Custom options — kept here to avoid merge conflicts with upstream kickstart.nvim.

vim.o.sidescrolloff = 8 -- Columns of context
vim.o.pumblend = 10 -- Popup blend
vim.o.relativenumber = true -- Relative line numbers
vim.o.tabstop = 4 -- Number of spaces tabs count for
vim.o.shiftwidth = 4 -- Size of an indent
vim.o.smartindent = true -- Insert indents automatically
vim.opt.spelllang = { 'en_gb' }

-- Cursor — per-mode shapes with slow-typewriter blink (long on, brief off)
vim.opt.guicursor = table.concat({
  'n-v-c-sm:block-blinkwait700-blinkoff200-blinkon800',
  'i-ci-ve:ver25-blinkwait700-blinkoff200-blinkon800',
  'r-cr-o:hor20-blinkwait700-blinkoff200-blinkon800',
}, ',')

-- Folding — treesitter-based, with modern open/close icons in the gutter
vim.o.foldmethod = 'expr'
vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.o.foldenable = true
vim.o.foldcolumn = '3'   -- wide enough to show fold tree without digit fallback
vim.o.foldlevel = 99      -- default: open everything (overridden per filetype)
vim.o.foldlevelstart = 99 -- same for new buffers
vim.opt.fillchars:append({
  foldopen  = vim.fn.nr2char(0xf078), -- nf-fa-chevron-down  (open fold)
  foldclose = vim.fn.nr2char(0xf054), -- nf-fa-chevron-right (closed fold)
  foldsep   = '│',
  fold      = ' ',
})

-- Per-filetype fold overrides. Filetypes with deep nesting need a wider
-- foldcolumn to avoid digit fallback; foldminlines avoids noisy short folds.
---@type table<string, { foldcolumn?: string, foldminlines?: integer }>
local fold_ft = {
  php        = { foldcolumn = '5' },
  typescript = { foldcolumn = '5' },
  javascript = { foldcolumn = '5' },
  lua        = { foldcolumn = '4' },
  sh         = { foldminlines = 10 },
  bash       = { foldminlines = 10 },
}
local fold_ft_defaults = { foldcolumn = '3', foldminlines = 10 }

-- Treesitter attaches asynchronously on FileType. vim.schedule defers until
-- after attachment, then resets foldmethod to force fold recomputation.
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local cfg = vim.tbl_extend('force', fold_ft_defaults, fold_ft[args.match] or {})
    vim.opt_local.foldcolumn  = cfg.foldcolumn
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
