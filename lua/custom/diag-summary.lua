-- Diagnostic summary picker — one entry per listed buffer, sorted by severity.
-- All listed buffers appear; unvisited ones show no counts (LSP hasn't run on them).
-- <C-r> inside the picker rescans all loaded buffers and refreshes results.

local M = {}

local S = vim.diagnostic.severity

-- Nerd Font diagnostic icons (same set used by most Neovim LSP configs).
local icons = { e = ' ', w = ' ', i = ' ', h = '󰌶 ' }

local function counts(bufnr)
  local diags = vim.diagnostic.get(bufnr)
  local e, w, i, h = 0, 0, 0, 0
  for _, d in ipairs(diags) do
    if     d.severity == S.ERROR then e = e + 1
    elseif d.severity == S.WARN  then w = w + 1
    elseif d.severity == S.INFO  then i = i + 1
    elseif d.severity == S.HINT  then h = h + 1
    end
  end
  return e, w, i, h
end

local function severity_rank(e, w)
  if e > 0 then return 0 end
  if w > 0 then return 1 end
  return 2
end

local function diag_segment(buf, offset)
  local seg  = ''
  local hls  = {}
  local spec = {
    { buf.e, icons.e, 'DiagnosticError' },
    { buf.w, icons.w, 'DiagnosticWarn'  },
    { buf.i, icons.i, 'DiagnosticInfo'  },
    { buf.h, icons.h, 'DiagnosticHint'  },
  }
  for _, p in ipairs(spec) do
    local n, icon, hl = p[1], p[2], p[3]
    if n > 0 then
      local chunk = icon .. n .. '  '
      local s = offset + #seg
      hls[#hls + 1] = { { s, s + #chunk - 2 }, hl }
      seg = seg .. chunk
    end
  end
  return seg, hls
end

local function collect_bufs()
  local bufs = {}
  for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if info.name ~= '' then
      local e, w, i, h = counts(info.bufnr)
      bufs[#bufs + 1] = {
        bufnr = info.bufnr,
        name  = info.name,
        e = e, w = w, i = i, h = h,
        rank  = severity_rank(e, w),
      }
    end
  end
  table.sort(bufs, function(a, b)
    if a.rank ~= b.rank then return a.rank < b.rank end
    return a.name < b.name
  end)
  return bufs
end

local function make_entry(buf)
  local fname     = vim.fn.fnamemodify(buf.name, ':t')
  local dir       = vim.fn.fnamemodify(buf.name, ':~:h')
  local changed   = vim.fn.getbufvar(buf.bufnr, '&modified') == 1 and ' ●' or ''
  local fname_col = string.format('%-38s', fname .. changed)

  local diag_seg, diag_hls = diag_segment(buf, #fname_col)
  local diag_col  = string.format('%-20s', diag_seg)
  local line      = fname_col .. diag_col .. dir

  local fname_hl = buf.e > 0 and 'DiagnosticError'
                or buf.w > 0 and 'DiagnosticWarn'
                or 'TelescopeResultsNormal'

  local hls = { { { 0, #fname_col }, fname_hl } }
  for _, h in ipairs(diag_hls) do hls[#hls + 1] = h end
  hls[#hls + 1] = { { #fname_col + #diag_col, #line }, 'Comment' }

  return {
    value   = buf,
    bufnr   = buf.bufnr,
    ordinal = buf.name,
    display = function() return line, hls end,
  }
end

local function make_finder()
  local finders = require 'telescope.finders'
  return finders.new_table {
    results     = collect_bufs(),
    entry_maker = make_entry,
  }
end

-- Trigger nvim-lint and LSP diagnostics on every listed buffer — loading
-- unvisited ones first so LSP can attach and lint can run.
local function rescan(prompt_bufnr)
  local ok_lint, lint = pcall(require, 'lint')

  for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    local bufnr = info.bufnr
    if info.name == '' then goto continue end

    -- Load unvisited buffers and fire autocmds so LSP attaches.
    -- nvim_buf_call sets bufnr as the current buffer so any autocmd handler
    -- that uses implicit buf 0 (e.g. treesitter ftplugins) targets the right buf.
    if info.loaded == 0 then
      vim.fn.bufload(bufnr)
      vim.api.nvim_buf_call(bufnr, function()
        vim.api.nvim_exec_autocmds('BufReadPost', { buffer = bufnr })
        vim.api.nvim_exec_autocmds('FileType',    { buffer = bufnr })
      end)
    end

    vim.api.nvim_buf_call(bufnr, function()
      if ok_lint then pcall(lint.try_lint) end
      for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        if client:supports_method('textDocument/diagnostic') then
          pcall(vim.lsp.buf_request, bufnr, 'textDocument/diagnostic',
            { textDocument = { uri = vim.uri_from_bufnr(bufnr) } },
            function() end)
        end
      end
    end)

    ::continue::
  end

  -- Freshly loaded buffers need more time for LSP to attach and respond.
  vim.defer_fn(function()
    local action_state = require 'telescope.actions.state'
    local picker = action_state.get_current_picker(prompt_bufnr)
    if picker then
      picker:refresh(make_finder(), { reset_prompt = false })
    end
  end, 1500)
end

function M.open()
  local pickers      = require 'telescope.pickers'
  local conf         = require('telescope.config').values
  local actions      = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  pickers.new({}, {
    prompt_title = 'Diagnostics by Buffer  · <C-r> rescan',
    finder       = make_finder(),
    sorter       = conf.generic_sorter {},
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local sel = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        vim.api.nvim_set_current_buf(sel.bufnr)
      end)
      map({ 'i', 'n' }, '<C-r>', function()
        rescan(prompt_bufnr)
      end)
      return true
    end,
  }):find()
end

return M
