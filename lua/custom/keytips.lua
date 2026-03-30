-- Tip of the Day: hand-curated keybinding tips, rotating daily.
--
-- Add entries to the `tips` table to extend coverage.
-- Tips are grouped thematically so related ones appear on consecutive days.
-- Exposes :KeyTip to recall the tip at any time.

local M = {}

--- Module config — override via M.setup({ position = 'top-right' })
---@type { position: 'top-right'|'bottom-right' }
local config = {
  position = 'bottom-right',
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
  { category = 'LSP', keys = 'grd',                     desc = 'Jump to where the symbol under the cursor is defined' },
  { category = 'LSP', keys = 'grr',                     desc = 'List all references to the symbol under the cursor' },
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
  { category = 'Git', keys = ']c / [c',                  desc = 'Jump to the next / previous git change in the file' },
  { category = 'Git', keys = '<leader>hp',               desc = 'Preview the git diff for the hunk under the cursor' },
  { category = 'Git', keys = '<leader>hs',               desc = 'Stage the hunk under the cursor' },
  { category = 'Git', keys = '<leader>hr',               desc = 'Reset (discard) the hunk under the cursor back to HEAD' },
  { category = 'Git', keys = '<leader>hS',               desc = 'Stage every change in the current buffer at once' },
  { category = 'Git', keys = '<leader>hR',               desc = 'Reset every change in the current buffer back to HEAD' },
  { category = 'Git', keys = '<leader>hb',               desc = 'Show the git blame annotation for the current line' },
  { category = 'Git', keys = '<leader>hd',               desc = 'Open a diff view of the buffer against the git index' },
  { category = 'Git', keys = '<leader>hD',               desc = 'Open a diff view of the buffer against the last commit' },
  { category = 'Git', keys = '<leader>tb',               desc = 'Toggle inline git blame annotations on every line' },

  -- ── Diagnostics / Trouble ─────────────────────────────────────────────
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

  local tip = tips[index]
  local max_width = math.floor(vim.o.columns * 0.32)

  -- Word-wrap long desc to fit within max_width
  local desc = tip.desc
  local desc_lines = {}
  while #desc > max_width do
    local break_at = desc:sub(1, max_width):match '.*()%s' or max_width
    desc_lines[#desc_lines + 1] = ' ' .. desc:sub(1, break_at - 1)
    desc = desc:sub(break_at + 1)
  end
  desc_lines[#desc_lines + 1] = ' ' .. desc

  local leader = vim.g.mapleader == ' ' and '<Space>' or (vim.g.mapleader or '\\')
  local lines = {
    ' Tip of the Day',
    ' <leader> = ' .. leader,
    '',
    ' ' .. tip.keys,
    '',
  }
  for _, l in ipairs(desc_lines) do
    lines[#lines + 1] = l
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = ' ' .. tip.category .. '  ·  ' .. string.format('%d / %d', index, #tips)
  lines[#lines + 1] = ''
  lines[#lines + 1] = ' n·next  c·category  q·dismiss'

  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l) + 2)
  end
  width = math.min(width, max_width + 4)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'

  local ui = vim.api.nvim_list_uis()[1]
  local col = ui and (ui.width - width - 2) or 10

  -- Position: top-right anchors NE at row 1; bottom-right anchors SE near statusline.
  local anchor = config.position == 'top-right' and 'NE' or 'SE'
  local row    = config.position == 'top-right' and 1 or (vim.o.lines - 2)

  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    anchor = anchor,
    row = row,
    col = col,
    width = width,
    height = #lines,
    style = 'minimal',
    border = 'rounded',
    noautocmd = true,
  })
  vim.wo[win].winblend = 25
  current_win = win

  local ns = vim.api.nvim_create_namespace 'keytips'
  vim.api.nvim_buf_add_highlight(buf, ns, 'Title',   0,          0, -1)
  vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', 1,          0, -1)  -- leader reminder
  vim.api.nvim_buf_add_highlight(buf, ns, 'Special', 3,          0, -1)  -- keys
  vim.api.nvim_buf_add_highlight(buf, ns, 'Type',    #lines - 4, 0, -1)  -- category
  vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', #lines - 3, 0, -1)  -- counter
  vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', #lines - 1, 0, -1)  -- hint

  local ADVANCE_SECS   = 30
  local COUNTDOWN_SECS = 5
  local MAX_AUTO_ADVANCES = 2
  local hint_line = #lines - 1  -- 0-indexed; last line is the hint

  local advance_timer = auto_advance and vim.uv.new_timer() or nil
  local tick_timer    = auto_advance and vim.uv.new_timer() or nil

  local function set_hint(text)
    if not vim.api.nvim_buf_is_valid(buf) then return end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, hint_line, hint_line + 1, false, { text })
    vim.bo[buf].modifiable = false
  end

  local function close()
    if advance_timer then advance_timer:stop() end
    if tick_timer    then tick_timer:stop()    end
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
          set_hint(string.format(' advancing in %ds…  c·category  q·dismiss', remaining))
        end
        -- On the final timeout the popup just disappears — no hint needed
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
