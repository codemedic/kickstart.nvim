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
-- 'i' covers both insert and replace mode.
vim.keymap.set('i', '<C-Right>', '<C-\\><C-O>w', { desc = 'Move cursor to next word' })
vim.keymap.set('i', '<C-Left>',  '<C-\\><C-O>b', { desc = 'Move cursor to previous word' })

-- Visual-mode word selection — mirrors JetBrains Ctrl+Left / Ctrl+Right.
-- w/b move the free end of the selection to the next/prev word boundary,
-- which naturally expands or contracts depending on cursor position vs anchor.
vim.keymap.set('v', '<C-Right>', 'w', { desc = 'Extend/contract selection to next word boundary' })
vim.keymap.set('v', '<C-Left>',  'b', { desc = 'Extend/contract selection to previous word boundary' })

-- Fold open / close — single-key shortcuts for the most common fold actions.
-- - and + are free by default (line-navigation defaults are not useful in practice).
vim.keymap.set('n', '-', 'zc', { desc = 'Close fold under cursor' })
vim.keymap.set('n', '+', 'zo', { desc = 'Open fold under cursor' })

-- Eclipse / IntelliJ navigation compatibility.
-- <C-g>   overrides Neovim's built-in "show file info" — intentional.
-- <C-S-g> requires kitty keyboard protocol (Ghostty).
vim.keymap.set('n', '<C-g>',   'grd',   { remap = true, desc = 'Go to definition (Eclipse Ctrl+G)' })
vim.keymap.set('n', '<C-S-g>', 'grr',   { remap = true, desc = 'Find references (Eclipse Ctrl+Shift+G)' })
vim.keymap.set('n', '<M-Left>',  '<C-o>', { desc = 'Navigate back (Eclipse Alt+Left)' })
vim.keymap.set('n', '<M-Right>', '<C-i>', { desc = 'Navigate forward (Eclipse Alt+Right)' })

-- Smart LSP navigation (JetBrains-style):
--   on a usage      → jump to definition
--   on a declaration → jump directly if one project reference, or open Trouble qflist
--
-- Issues the textDocument/references request from a loaded project buffer so that
-- gopls searches the project workspace even when the cursor is in a stdlib file
-- (gopls scopes references to the module of the requesting buffer, not the params URI).
local function smart_lsp_navigate()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].buftype ~= '' then return end
  if vim.tbl_isempty(vim.lsp.get_clients({ bufnr = bufnr })) then return end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1  -- 0-indexed for LSP protocol
  local col = cursor[2]

  local td_params = {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    position     = { line = row, character = col },
  }

  vim.lsp.buf_request(bufnr, 'textDocument/definition', td_params, function(_, result)
    if not result or vim.tbl_isempty(result) then return end
    local defs      = vim.islist(result) and result or { result }
    local def       = defs[1]
    local def_uri   = def.uri or def.targetUri
    local def_range = def.range or def.targetSelectionRange or def.targetRange

    if def_uri == vim.uri_from_bufnr(bufnr) and def_range.start.line == row then
      local cwd        = vim.fn.resolve(vim.uv.cwd()) .. '/'
      local request_buf = bufnr
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buftype == '' then
          local bname = vim.fn.resolve(vim.api.nvim_buf_get_name(b))
          if bname:sub(1, #cwd) == cwd
              and not vim.tbl_isempty(vim.lsp.get_clients({ bufnr = b })) then
            request_buf = b
            break
          end
        end
      end
      local ref_params = {
        textDocument = td_params.textDocument,
        position     = td_params.position,
        context      = { includeDeclaration = false },
      }
      vim.lsp.buf_request(request_buf, 'textDocument/references', ref_params, function(_, refs)
        if not refs or #refs == 0 then
          vim.notify('No references found', vim.log.levels.INFO)
          return
        end
        local project_refs = vim.tbl_filter(function(ref)
          return vim.fn.resolve(vim.uri_to_fname(ref.uri)):sub(1, #cwd) == cwd
        end, refs)
        if #project_refs == 0 then
          vim.notify('No project references found', vim.log.levels.INFO)
        elseif #project_refs == 1 then
          vim.lsp.util.show_document(project_refs[1], 'utf-8', { focus = true })
        else
          local items = vim.lsp.util.locations_to_items(project_refs, 'utf-8')
          vim.fn.setqflist({}, 'r', { title = 'References (project)', items = items })
          vim.cmd('Trouble qflist focus=true')
        end
      end)
    else
      vim.lsp.util.show_document(def, 'utf-8', { focus = true })
    end
  end)
end

vim.keymap.set('n', '<C-LeftMouse>', smart_lsp_navigate,
  { desc = 'Smart navigate: jump to definition, or show project references when on declaration' })
vim.keymap.set('n', '<C-g>', smart_lsp_navigate,
  { desc = 'Smart navigate: jump to definition, or show project references when on declaration' })

-- Search everywhere (GoLand double-shift equivalent).
-- Opens as file search; type > for commands, @ for symbols, / for grep.
vim.keymap.set('n', '<C-p>', function() require('custom.search-everywhere').open() end,
  { desc = 'Search everywhere: files (> cmds, @ symbols, / grep)' })

-- Camel-hump word motions (nvim-spider). Off by default; <leader>tc to toggle.
-- When on, w/b/e/ge stop at camelCase and snake_case boundaries in addition to
-- the usual word boundaries.
local camel_hump_enabled = false

local function camel_hump_set(enabled)
  camel_hump_enabled = enabled
  -- w/b/e/ge in normal, operator-pending, and visual modes
  for _, mode in ipairs({ 'n', 'o', 'x' }) do
    for _, key in ipairs({ 'w', 'b', 'e', 'ge' }) do
      if enabled then
        vim.keymap.set(mode, key, function() require('spider').motion(key) end,
          { desc = 'Spider ' .. key .. ' (camel-hump)' })
      else
        pcall(vim.keymap.del, mode, key)
      end
    end
  end
  -- <C-Right>/<C-Left> in normal mode are built-in motions that bypass the w/b keymaps,
  -- so they need explicit remapping. Insert and visual modes already go through w/b.
  if enabled then
    vim.keymap.set('n', '<C-Right>', function() require('spider').motion('w') end,
      { desc = 'Spider w (camel-hump)' })
    vim.keymap.set('n', '<C-Left>',  function() require('spider').motion('b') end,
      { desc = 'Spider b (camel-hump)' })
  else
    pcall(vim.keymap.del, 'n', '<C-Right>')
    pcall(vim.keymap.del, 'n', '<C-Left>')
  end
  vim.notify('Camel-hump motions ' .. (enabled and 'on' or 'off'), vim.log.levels.INFO)
end

vim.keymap.set('n', '<leader>tc', function()
  camel_hump_set(not camel_hump_enabled)
end, { desc = 'Toggle camel-hump word motions (w/b/e/ge)' })
