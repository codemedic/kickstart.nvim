-- Tip of the Day: hand-curated keybinding tips, rotating daily.
--
-- Add entries to the `tips` table to extend coverage.
-- Tips are grouped thematically so related ones appear on consecutive days.
-- Exposes :KeyTip to recall the tip at any time.

local M = {}

--- Module config — override via M.setup({ position = 'bottom-right' })
---@type { position: 'top-right'|'bottom-right' }
local config = {
  position = 'top-right',
}

---@alias Tip { keys: string, desc: string, category: string }

---@type Tip[]
local tips = {
  -- ── Splits: navigation ────────────────────────────────────────────────
  { category = 'Splits', keys = '<C-h> / <C-l>',        desc = 'Move focus to the split on the left / right' },
  { category = 'Splits', keys = '<C-j> / <C-k>',        desc = 'Move focus to the split below / above' },
  { category = 'Splits', keys = '<C-\\>',               desc = 'Jump back to the previously focused split' },

  -- ── Splits: resizing ──────────────────────────────────────────────────
  { category = 'Splits', keys = '<A-h> / <A-l>',        desc = 'Shrink / grow the current split horizontally' },
  { category = 'Splits', keys = '<A-j> / <A-k>',        desc = 'Shrink / grow the current split vertically' },

  -- ── Splits: swapping ──────────────────────────────────────────────────
  { category = 'Splits', keys = '<leader>ssh / ssl',    desc = 'Swap current buffer with the split to the left / right' },
  { category = 'Splits', keys = '<leader>ssj / ssk',    desc = 'Swap current buffer with the split below / above' },

  -- ── Buffers ───────────────────────────────────────────────────────────
  { category = 'Buffers', keys = '<C-PageUp> / <C-PageDown>', desc = 'Switch to the previous / next buffer tab' },
  { category = 'Buffers', keys = '<leader><Space>',      desc = 'Fuzzy-pick from all open buffers' },

  -- ── Search (Telescope) ────────────────────────────────────────────────
  { category = 'Search', keys = '<leader>sf',            desc = 'Find files in the project' },
  { category = 'Search', keys = '<leader>sg',            desc = 'Live grep — search text across the whole project' },
  { category = 'Search', keys = '<leader>sw',            desc = 'Search for the word currently under the cursor' },
  { category = 'Search', keys = '<leader>s.',            desc = 'Browse recently opened files' },
  { category = 'Search', keys = '<leader>sr',            desc = 'Re-open the last Telescope search' },
  { category = 'Search', keys = '<leader>/',             desc = 'Fuzzy search inside the current buffer' },
  { category = 'Search', keys = '<leader>s/',            desc = 'Live grep scoped to currently open files only' },
  { category = 'Search', keys = '<leader>sd',            desc = 'Browse all current diagnostics in Telescope' },
  { category = 'Search', keys = '<leader>sh',            desc = 'Search Neovim help tags' },
  { category = 'Search', keys = '<leader>sk',            desc = 'Browse and search all active keymaps' },
  { category = 'Search', keys = '<leader>sc',            desc = 'Browse and run any Ex command via Telescope' },
  { category = 'Search', keys = '<leader>sn',            desc = 'Find files inside your Neovim config directory' },

  -- ── LSP: navigation ───────────────────────────────────────────────────
  { category = 'LSP', keys = 'grd  /  <C-g>',           desc = 'Jump to where the symbol under the cursor is defined' },
  { category = 'LSP', keys = 'grr  /  <C-S-g>',         desc = 'List all references to the symbol under the cursor' },
  { category = 'LSP', keys = '<M-Left> / <M-Right>',    desc = 'Navigate back / forward through the jump history (Eclipse-style)' },
  { category = 'LSP', keys = 'gri',                     desc = 'Jump to the implementation of the symbol (useful for interfaces)' },
  { category = 'LSP', keys = 'grt',                     desc = 'Jump to the type definition of the symbol (not where it\'s defined, but what type it is)' },
  { category = 'LSP', keys = 'grD',                     desc = 'Jump to the declaration — e.g. the header file in C' },
  { category = 'LSP', keys = 'grn',                     desc = 'Rename the symbol under the cursor across all files' },
  { category = 'LSP', keys = 'gra',                     desc = 'Open code actions — fixes, imports, refactors suggested by the LSP' },
  { category = 'LSP', keys = 'gO',                      desc = 'Browse all symbols (functions, types, vars) in the current file' },
  { category = 'LSP', keys = 'gW',                      desc = 'Browse all symbols across the entire workspace' },
  { category = 'LSP', keys = '<leader>th',              desc = 'Toggle inlay hints (inline type / parameter annotations)' },

  -- ── Completion (blink.cmp) ────────────────────────────────────────────
  { category = 'Completion', keys = '<Tab>',              desc = 'Accept the pre-selected (first) completion item — like JetBrains IDEs' },
  { category = 'Completion', keys = '<S-Tab>',            desc = 'Select the previous completion item' },
  { category = 'Completion', keys = '<C-n> / <C-p>',     desc = 'Move down / up through the completion list' },
  { category = 'Completion', keys = '<C-e>',              desc = 'Dismiss the completion menu' },
  { category = 'Completion', keys = '<C-k>',              desc = 'Toggle function signature help' },
  { category = 'Completion', keys = '<C-Space>',          desc = 'Open the completion menu (or show docs if already open)' },

  -- ── Formatting ────────────────────────────────────────────────────────
  { category = 'Editing', keys = '<leader>f',            desc = 'Format the current buffer using the configured formatter' },

  -- ── Refactoring ───────────────────────────────────────────────────────
  { category = 'Editing', keys = '<leader>rr',           desc = 'Open the refactoring menu for the current selection' },

  -- ── Surround (mini.surround) ──────────────────────────────────────────
  { category = 'Surround', keys = 'sa  (e.g. saiw))',   desc = 'Add a surrounding — saiw) wraps the inner word in parentheses' },
  { category = 'Surround', keys = 'sd  (e.g. sd\')',    desc = 'Delete a surrounding — sd\' removes the enclosing quotes' },
  { category = 'Surround', keys = 'sr  (e.g. sr)\')',   desc = 'Replace a surrounding — sr)\' changes ( ) to \' \'' },

  -- ── Git: hunks ────────────────────────────────────────────────────────
  { category = 'Git', keys = ']c / [c',                  desc = 'Jump to the next / previous changed block (hunk) in the file — navigate between your edits without scrolling' },
  { category = 'Git', keys = '<leader>hp',               desc = 'Pop up a diff preview showing exactly what changed in this block vs the last commit' },
  { category = 'Git', keys = '<leader>hi',               desc = 'Show the original lines inline inside the buffer — same info as hp but without a popup' },
  { category = 'Git', keys = '<leader>hs',               desc = 'Stage just this block for the next commit — like `git add -p` but without leaving the editor' },
  { category = 'Git', keys = '<leader>hr',               desc = 'Discard just this block of changes — undo local edits in this section only, leaving the rest untouched' },
  { category = 'Git', keys = '<leader>hS',               desc = 'Stage every change in the whole file at once — equivalent to `git add <file>`' },
  { category = 'Git', keys = '<leader>hR',               desc = 'Discard ALL local changes in this file and restore it to the last commit — irreversible!' },
  { category = 'Git', keys = '<leader>hb',               desc = 'Show who last changed this line, in which commit, and when — full git blame for the current line' },
  { category = 'Git', keys = '<leader>hd',               desc = 'Diff this file against the git index (what is staged) — shows changes you have not yet staged' },
  { category = 'Git', keys = '<leader>hD',               desc = 'Diff this file against HEAD — shows all local changes (staged and unstaged) vs the last commit' },
  { category = 'Git', keys = '<leader>hq / hQ',          desc = 'Collect all changed blocks into the quickfix list to step through with :cn / :cp (current file / all files)' },
  { category = 'Git', keys = '<leader>tb',               desc = 'Toggle inline git blame on every line — see author and commit summary at a glance without running git blame' },
  { category = 'Git', keys = '<leader>tw',               desc = 'Toggle word-level diff highlighting — highlights individual changed words within a line, not just the whole line' },
  { category = 'Git', keys = 'ih  (visual/operator)',    desc = 'Text object for the current changed block — use with operators, e.g. `dih` deletes the hunk, `yih` yanks it' },

  -- ── Diagnostics / Trouble ─────────────────────────────────────────────
  { category = 'Diagnostics', keys = '<leader>xb',       desc = 'Diagnostic summary — E/W/I/H counts per buffer; <C-r> to rescan all' },
  { category = 'Diagnostics', keys = '<leader>xx',       desc = 'Toggle the Trouble panel showing all project diagnostics' },
  { category = 'Diagnostics', keys = '<leader>xX',       desc = 'Toggle Trouble showing diagnostics for the current buffer only' },
  { category = 'Diagnostics', keys = '<leader>cs',       desc = 'Toggle the Trouble symbol outline for the current file' },
  { category = 'Diagnostics', keys = '<leader>cl',       desc = 'Toggle Trouble panel showing LSP definitions and references' },
  { category = 'Diagnostics', keys = '<leader>xQ',       desc = 'Toggle the quickfix list in Trouble' },
  { category = 'Diagnostics', keys = '<leader>q',        desc = 'Send current diagnostics to the native quickfix list' },

  -- ── Terminal ──────────────────────────────────────────────────────────
  { category = 'Terminal', keys = '<leader>tt',          desc = 'Toggle the floating terminal' },
  { category = 'Terminal', keys = '<Esc><Esc>',          desc = 'Exit terminal mode and return to normal mode' },

  -- ── Editing: commenting ───────────────────────────────────────────────
  { category = 'Editing', keys = '<C-/>',               desc = 'Toggle comment — line (normal/insert, moves down) or selection (visual)' },

  -- ── Editing: insert mode ──────────────────────────────────────────────
  { category = 'Editing', keys = '<C-BS> / <M-BS>',     desc = 'Delete word backwards in insert mode' },

  -- ── Folds ─────────────────────────────────────────────────────────────
  { category = 'Folds', keys = 'zo / zc',                desc = 'Open / close one fold under cursor' },
  { category = 'Folds', keys = 'zO / zC',                desc = 'Open / close all folds under cursor (recursive)' },
  { category = 'Folds', keys = 'za',                     desc = 'Toggle fold under cursor' },
  { category = 'Folds', keys = 'zr / zm',                desc = 'Open / close one more fold level globally' },
  { category = 'Folds', keys = 'zR / zM',                desc = 'Open / close ALL fold levels' },

  -- ── Go: dependency management (go.nvim) ──────────────────────────────
  { category = 'Go', keys = '<leader>gmt',               desc = 'Run go mod tidy — remove unused deps and update go.sum' },
  { category = 'Go', keys = '<leader>gmg',               desc = 'Run go get <pkg> — prompt for a package to add or update' },
  { category = 'Go', keys = '<leader>gmv',               desc = 'Run go mod vendor — sync the vendor/ directory' },
  { category = 'Go', keys = '<leader>gmi',               desc = 'Run go mod init — prompt for module name to initialise a new module' },
  { category = 'Go', keys = '<leader>gws',               desc = 'Run go work sync — sync go.work.sum with all workspace modules' },
  { category = 'Go', keys = '<leader>gwa',               desc = 'Run go work use <path> — prompt for a path to add to the workspace' },
  { category = 'Go', keys = '<leader>gv',                desc = 'Run govulncheck and show vulnerabilities as diagnostics on go.mod require lines (go.mod only)' },
  { category = 'Go', keys = '<leader>gmu',               desc = 'Update the module under the cursor in go.mod to the latest version (go.mod only)' },
  { category = 'Go', keys = '<leader>gmU',               desc = 'Bulk update go.mod modules — picker lets you choose patch only, patch+minor, or all (go.mod only)' },
  { category = 'Go', keys = '<leader>gmr',               desc = 'Refresh go.mod update diagnostics — re-runs go list to check for new releases' },

  -- ── Misc ──────────────────────────────────────────────────────────────
  { category = 'Misc', keys = '<Esc>',                   desc = 'Clear the search highlight without moving the cursor' },
}

-- Tracks the current tip index across calls; seeded from day-of-year on first show.
local current_index = nil
-- Counts how many times the popup has auto-advanced in the current startup sequence.
local advance_count = 0
-- Handle to the currently open tip window, so we can close it before opening another.
local current_win = nil
-- Close function of the currently open float, so toggle_manual can stop its timers.
local current_close = nil

--- Open a centered floating window listing all tips for a given category.
---@param category string
local function show_category(category)
  local matches = {}
  for _, t in ipairs(tips) do
    if t.category == category then
      matches[#matches + 1] = t
    end
  end

  local max_width = math.floor(vim.o.columns * 0.65)

  -- Build lines: header, then each tip as keys + wrapped desc
  local lines = { '  ' .. category .. ' — all tips', '' }
  local hl_keys = {}  -- line numbers (0-indexed) that contain keys

  for i, t in ipairs(matches) do
    local keys_line = string.format('  %d.  %s', i, t.keys)
    lines[#lines + 1] = keys_line
    hl_keys[#hl_keys + 1] = #lines - 1  -- 0-indexed

    local desc = t.desc
    while #desc > max_width - 6 do
      local break_at = desc:sub(1, max_width - 6):match '.*()%s' or (max_width - 6)
      lines[#lines + 1] = '      ' .. desc:sub(1, break_at - 1)
      desc = desc:sub(break_at + 1)
    end
    lines[#lines + 1] = '      ' .. desc
    lines[#lines + 1] = ''
  end

  lines[#lines + 1] = '  q / <Esc>  close'

  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l) + 2)
  end
  width = math.min(width, max_width)

  local height = math.min(#lines, math.floor(vim.o.lines * 0.75))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'

  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    row = row,
    col = col,
    width = width,
    height = height,
    style = 'minimal',
    border = 'rounded',
    noautocmd = true,
  })
  vim.wo[win].scrolloff = 2

  local ns = vim.api.nvim_create_namespace 'keytips_cat'
  vim.api.nvim_buf_add_highlight(buf, ns, 'Title', 0, 0, -1)
  for _, ln in ipairs(hl_keys) do
    vim.api.nvim_buf_add_highlight(buf, ns, 'Special', ln, 0, -1)
  end
  vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', #lines - 1, 0, -1)

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  for _, key in ipairs { 'q', '<Esc>' } do
    vim.keymap.set('n', key, close, { buffer = buf, silent = true, nowait = true })
  end
end

--- Open a floating window for the tip at `index`. Dismiss with q/<Esc>, next with n/<Tab>.
---@param index integer
---@param auto_advance boolean  When true, timers run and the popup auto-cycles (up to 2 times).
local function show_float(index, auto_advance)
  -- Close any existing tip window before opening a new one.
  if current_win and vim.api.nvim_win_is_valid(current_win) then
    vim.api.nvim_win_close(current_win, true)
    current_win = nil
  end

  local tip   = tips[index]
  local width = 44  -- fixed inner width

  local title  = ' 💡 Tip '
  local footer = string.format(' %s  %d/%d  ·  n·next  c·cat  q·close', tip.category, index, #tips)

  local has_leader = tip.keys:find '<[Ll]eader>' ~= nil
  local ldr_line   = nil
  if has_leader then
    local mapleader = vim.g.mapleader or '\\'
    local ldr_name  = mapleader == ' ' and 'Space' or mapleader
    ldr_line = string.format(' <leader> = %s', ldr_name)
  end

  local lines = { ' ' .. tip.keys, ' ' .. tip.desc, '' }
  if ldr_line then lines[#lines + 1] = ldr_line end
  lines[#lines + 1] = footer

  -- Height = sum of visual lines each buffer line occupies at the fixed width.
  local function vlines(text)
    return math.max(1, math.ceil(vim.fn.strdisplaywidth(text) / width))
  end
  local height = 0
  for _, l in ipairs(lines) do
    height = height + vlines(l)
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'

  -- Position: NE/SE anchor flush to the right edge of the screen.
  local anchor = config.position == 'top-right' and 'NE' or 'SE'
  local row    = config.position == 'top-right' and 1 or (vim.o.lines - 2)

  local win = vim.api.nvim_open_win(buf, false, {
    relative  = 'editor',
    anchor    = anchor,
    row       = row,
    col       = vim.o.columns,
    width     = width,
    height    = height,
    style     = 'minimal',
    border    = 'rounded',
    title     = title,
    title_pos = 'left',
    noautocmd = true,
  })
  vim.wo[win].winblend  = 25
  vim.wo[win].wrap      = true
  vim.wo[win].linebreak = true  -- wrap at word boundaries

  -- Resize to the true visual height now that wrap/linebreak are applied.
  local true_height = vim.api.nvim_win_text_height(win, {}).all
  if true_height ~= height then
    vim.api.nvim_win_set_config(win, { height = true_height })
  end

  current_win = win

  local ns          = vim.api.nvim_create_namespace 'keytips'
  local footer_line = #lines - 1  -- 0-indexed; last line is always the footer
  vim.api.nvim_buf_add_highlight(buf, ns, 'Special', 0,           0, -1)  -- keys
  vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', footer_line, 0, -1)  -- footer
  if ldr_line then
    vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', footer_line - 1, 0, -1)  -- leader info
  end

  -- Reposition flush to the right edge whenever the terminal resizes.
  local resize_augroup = vim.api.nvim_create_augroup('keytips_resize', { clear = true })
  vim.api.nvim_create_autocmd('VimResized', {
    group    = resize_augroup,
    callback = function()
      if not vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_del_augroup_by_id(resize_augroup)
        return
      end
      vim.api.nvim_win_set_config(win, {
        relative = 'editor',
        col      = vim.o.columns,
        row      = config.position == 'top-right' and 1 or (vim.o.lines - 2),
        height   = vim.api.nvim_win_text_height(win, {}).all,
      })
    end,
  })

  local ADVANCE_SECS      = 30
  local COUNTDOWN_SECS    = 5
  local MAX_AUTO_ADVANCES = 2

  local advance_timer = auto_advance and vim.uv.new_timer() or nil
  local tick_timer    = auto_advance and vim.uv.new_timer() or nil

  local function set_footer(text)
    if not vim.api.nvim_buf_is_valid(buf) then return end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, footer_line, footer_line + 1, false, { text })
    vim.bo[buf].modifiable = false
  end

  local function close()
    if advance_timer then advance_timer:stop() end
    if tick_timer    then tick_timer:stop()    end
    vim.api.nvim_del_augroup_by_id(resize_augroup)
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if current_win == win then current_win = nil end
    if current_close == close then current_close = nil end
  end

  current_close = close

  local function next_tip()
    close()
    current_index = (current_index % #tips) + 1
    show_float(current_index, auto_advance)
  end

  if auto_advance then
    -- Tick every second; update hint only during the final countdown
    local elapsed = 0
    tick_timer:start(1000, 1000, vim.schedule_wrap(function()
      elapsed = elapsed + 1
      local remaining = ADVANCE_SECS - elapsed
      if remaining <= COUNTDOWN_SECS and remaining > 0 then
        if advance_count < MAX_AUTO_ADVANCES then
          set_footer(string.format(' %s  %d/%d  ·  next in %ds  q·close', tip.category, index, #tips, remaining))
        end
      end
    end))

    advance_timer:start(ADVANCE_SECS * 1000, 0, vim.schedule_wrap(function()
      if advance_count < MAX_AUTO_ADVANCES then
        advance_count = advance_count + 1
        next_tip()
      else
        -- User isn't engaging — just hide silently
        close()
      end
    end))
  end

  for _, key in ipairs { 'q', '<Esc>' } do
    vim.keymap.set('n', key, close, { buffer = buf, silent = true, nowait = true })
  end
  for _, key in ipairs { 'n', '<Tab>' } do
    vim.keymap.set('n', key, next_tip, { buffer = buf, silent = true, nowait = true })
  end
  vim.keymap.set('n', 'c', function()
    close()
    show_category(tip.category)
  end, { buffer = buf, silent = true, nowait = true })
end

--- Show today's tip at startup. Resets the auto-advance counter and enables auto-cycling.
function M.show()
  if current_index == nil then
    local day = tonumber(os.date '%j') or 1
    current_index = ((day - 1) % #tips) + 1
  end
  advance_count = 0
  show_float(current_index, true)
end

--- Toggle the tip popup. If visible, close it; otherwise show current tip without auto-advance.
local function toggle_manual()
  if current_win and vim.api.nvim_win_is_valid(current_win) then
    if current_close then current_close() end
    return
  end
  if current_index == nil then
    local day = tonumber(os.date '%j') or 1
    current_index = ((day - 1) % #tips) + 1
  end
  show_float(current_index, false)
end

---@param opts? { position?: 'top-right'|'bottom-right' }
function M.setup(opts)
  if opts then
    config = vim.tbl_deep_extend('force', config, opts)
  end

  vim.api.nvim_create_autocmd('User', {
    pattern = 'LazyDone',
    once = true,
    callback = function()
      vim.defer_fn(M.show, 200)
    end,
  })

  vim.api.nvim_create_user_command('KeyTip', toggle_manual, { desc = 'Toggle keybinding tip of the day' })
end

return M
