-- Custom options — kept here to avoid merge conflicts with upstream kickstart.nvim.

-- Nerd Font is available in all environments (terminal and GUI).
-- init.lua defaults this to false in GUI; override unconditionally here.
vim.g.have_nerd_font = true

-- mini.icons: provides filetype icons to mini.statusline (and others).
-- nvim-web-devicons is spec'd as `enabled = vim.g.have_nerd_font`, which is false
-- at Lazy load time, so it never loads. mini.icons is already part of mini.nvim.
require('mini.icons').setup()

-- Re-initialise mini.statusline now that have_nerd_font is correct.
local statusline = require('mini.statusline')
statusline.setup { use_icons = true }

---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function() return '%2l:%-2v' end

-- Branch name: git-flow prefix abbreviations (mirrors Claude Code statusline logic)
local _BRANCH_PREFIXES = {
  { 'feature/', 'f/' }, { 'bugfix/', 'b/' }, { 'hotfix/', 'h/' },
  { 'release/', 'r/' }, { 'support/', 's/' }, { 'fix/', 'x/' },
  { 'chore/',   'c/' }, { 'docs/',    'd/' },
}

-- Dynamic branch width: reuse mini's is_truncated() so laststatus=3 is handled correctly.
local function _branch_max_width()
  if     not statusline.is_truncated(220) then return 55
  elseif not statusline.is_truncated(180) then return 40
  elseif not statusline.is_truncated(120) then return 28
  elseif not statusline.is_truncated(80)  then return 18
  else                                         return 10
  end
end

local function _abbrev_branch(branch)
  for _, p in ipairs(_BRANCH_PREFIXES) do
    if vim.startswith(branch, p[1]) then
      branch = p[2] .. branch:sub(#p[1] + 1)
      break
    end
  end
  local max = _branch_max_width()
  if #branch > max then branch = branch:sub(1, max - 1) .. '…' end
  return branch
end

---@diagnostic disable-next-line: duplicate-set-field
statusline.section_git = function(args)
  if statusline.is_truncated(args.trunc_width) then return '' end
  local summary = vim.b.minigit_summary_string or vim.b.gitsigns_head
  if summary == nil then return '' end
  -- summary format: "branch_name [+N ~N -N]" — branch is the first whitespace-delimited token
  local branch, rest = summary:match('^(%S+)(.*)')
  if not branch then return '' end
  local short = _abbrev_branch(branch)
  local icon = args.icon or (vim.g.have_nerd_font and '' or 'Git')
  return icon .. ' ' .. short .. (rest or '')
end

-- File path relative to git repo root
local _git_root_cache = {}

local function _git_root(filepath)
  local dir = vim.fn.fnamemodify(filepath, ':h')
  if _git_root_cache[dir] ~= nil then return _git_root_cache[dir] end
  local git_dir = vim.fn.finddir('.git', dir .. ';')
  -- finddir returns '' when not found; otherwise get the parent of .git as the root
  local root = git_dir ~= '' and vim.fn.fnamemodify(git_dir, ':p:h:h') or false
  _git_root_cache[dir] = root
  return root
end

---@diagnostic disable-next-line: duplicate-set-field
statusline.section_filename = function(args)
  if vim.bo.buftype == 'terminal' then return '%t' end
  if statusline.is_truncated(args.trunc_width) then return '%f%m%r' end
  local abs = vim.fn.expand('%:p')
  if abs == '' then return '[No Name]' end
  local root = _git_root(abs)
  if root and vim.startswith(abs, root .. '/') then
    return abs:sub(#root + 2) .. '%m%r'
  end
  return '%F%m%r'
end

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
-- the cursor so the target line is immediately visible.
-- vim.schedule defers zv until after the FileType-scheduled treesitter
-- foldmethod reset has run; without it zv fires before folds exist.
vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    vim.schedule(function()
      vim.cmd('silent! normal! zv')
    end)
  end,
})
