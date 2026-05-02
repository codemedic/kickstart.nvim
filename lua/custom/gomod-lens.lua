-- gomod-lens: dependency update hints and vulnerability diagnostics for go.mod.
--
-- Both update hints and vulnerability errors are surfaced as vim.diagnostics so
-- that diagflow renders them consistently with no visual conflicts.
--
-- Update hints (HINT): run on open/save — show available version and carry an
--   OSC-8 diff URL in user_data for gx / Ctrl+click.
-- Vuln errors (ERROR): run on <leader>gv — govulncheck results mapped to the
--   affected require lines.
--
-- Keymaps (gomod buffers only):
--   <leader>gv    run govulncheck → vuln diagnostics
--   gx            open diff URL for module under cursor
--   <C-LeftMouse> open diff URL for clicked line
--   <leader>gmu   GoGet module under cursor to latest
--   <leader>gmU   GoGet ALL outdated modules in one call
--   <leader>gmr   refresh update hints

local M = {}

local update_ns = vim.api.nvim_create_namespace 'gomod_updates'
local vuln_ns   = vim.api.nvim_create_namespace 'gomod_vulncheck'

-- Per-buffer state — keyed by bufnr, valid only while go.mod is displayed.
-- buf_updates[buf] = { [mod_path] = { lnum, latest, level, url } }
-- buf_vulns[buf]   = { [mod_path] = { lnum, vulns = [{osv_id, fixed, summary}] } }
local buf_updates = {}
local buf_vulns   = {}

-- Background scan results keyed by absolute go.mod path.
-- Populated by scan_gomod_path() when triggered from a .go FileType event.
-- Applied (and cleared) in FileType gomod / BufWinEnter once go.mod has a window.
-- Diagnostics are NEVER set on a hidden buffer — tiny-inline-diagnostic requires
-- a window to render and will silently skip DiagnosticChanged on windowless bufs.
-- pending_gomod[path] = { updates?, vuln_mods? }
local pending_gomod = {}

-- ── JSON helpers ─────────────────────────────────────────────────────────────

-- go list outputs pretty-printed JSON objects; split by brace depth.
local function split_json_objects(s)
  local objects, depth, start = {}, 0, nil
  for i = 1, #s do
    local c = s:sub(i, i)
    if c == '{' then
      depth = depth + 1
      if depth == 1 then start = i end
    elseif c == '}' then
      depth = depth - 1
      if depth == 0 and start then
        objects[#objects + 1] = s:sub(start, i)
        start = nil
      end
    end
  end
  return objects
end

-- ── Parsing ───────────────────────────────────────────────────────────────────

-- Returns { [mod_path] = {current, latest} } for modules that have updates.
local function parse_updates(output)
  local updates = {}
  for _, obj in ipairs(split_json_objects(output)) do
    local ok, mod = pcall(vim.json.decode, obj)
    if ok and mod and mod.Path and mod.Version and mod.Update and mod.Update.Version then
      updates[mod.Path] = { current = mod.Version, latest = mod.Update.Version }
    end
  end
  return updates
end

local function parse_semver(v)
  local maj, min, pat = v:match '^v?(%d+)%.(%d+)%.(%d+)'
  if maj then
    return { major = tonumber(maj), minor = tonumber(min), patch = tonumber(pat) }
  end
  local maj2 = v:match '^v?(%d+)'
  return { major = tonumber(maj2) or 0, minor = 0, patch = 0 }
end

local function semver_level(current, latest)
  local c = parse_semver(current)
  local l = parse_semver(latest)
  if l.major ~= c.major then return 'major' end
  if l.minor ~= c.minor then return 'minor' end
  return 'patch'
end

-- { [mod_path] = line_number_1based } from a list of go.mod lines.
local function parse_gomod_mods(lines)
  local mods = {}
  for i, line in ipairs(lines) do
    local mod = line:match '^%s+([%w%.%-%+_/]+)%s+v'
             or line:match '^require%s+([%w%.%-%+_/]+)%s+v'
    if mod then mods[mod] = i end
  end
  return mods
end

-- Parse govulncheck JSON stdout into { [mod_path] = [{osv_id, fixed, summary}] }.
-- gomod_mods is used for package→module prefix matching.
local function parse_vuln_output(stdout, gomod_mods)
  local osvs     = {}
  local findings = {}

  for _, json_str in ipairs(split_json_objects(stdout)) do
    local ok, obj = pcall(vim.json.decode, json_str)
    if ok and obj then
      if obj.osv then
        local pkgs = {}
        for _, aff in ipairs(obj.osv.affected or {}) do
          if aff.package and aff.package.name then pkgs[#pkgs + 1] = aff.package.name end
        end
        osvs[obj.osv.id] = { summary = obj.osv.summary or obj.osv.id, packages = pkgs }
      elseif obj.finding and obj.finding.osv then
        local f = obj.finding
        if not findings[f.osv] then findings[f.osv] = f.fixed_version or '' end
      end
    end
  end

  local vuln_mods = {}
  for osv_id, fixed in pairs(findings) do
    local osv = osvs[osv_id]
    if osv then
      for _, pkg in ipairs(osv.packages) do
        local best_mod, best_len = nil, 0
        for mod in pairs(gomod_mods) do
          if (pkg == mod or pkg:sub(1, #mod + 1) == mod .. '/') and #mod > best_len then
            best_mod, best_len = mod, #mod
          end
        end
        if best_mod then
          if not vuln_mods[best_mod] then vuln_mods[best_mod] = {} end
          local seen = false
          for _, v in ipairs(vuln_mods[best_mod]) do
            if v.osv_id == osv_id then seen = true; break end
          end
          if not seen then
            vuln_mods[best_mod][#vuln_mods[best_mod] + 1] = {
              osv_id = osv_id, fixed = fixed, summary = osv.summary,
            }
          end
        end
      end
    end
  end
  return vuln_mods
end

-- ── URL helpers ───────────────────────────────────────────────────────────────

local function compare_url(mod_path, current, latest)
  local path = mod_path:gsub('/v%d+$', '')
  local segs  = {}
  for seg in path:gmatch '[^/]+' do segs[#segs + 1] = seg end
  if #segs < 3 then return nil end
  local host      = segs[1]
  local repo_path = table.concat(segs, '/', 1, 3)
  local sub       = #segs > 3 and (table.concat(segs, '/', 4) .. '/') or ''
  local cur_tag, new_tag = sub .. current, sub .. latest
  if host == 'github.com' then
    return ('https://%s/compare/%s...%s'):format(repo_path, cur_tag, new_tag)
  elseif host == 'gitlab.com' then
    return ('https://%s/-/compare/%s...%s'):format(repo_path, cur_tag, new_tag)
  elseif host == 'bitbucket.org' then
    return ('https://%s/branches/compare/%s..%s'):format(repo_path, new_tag, cur_tag)
  end
  return nil
end

-- ── Diagnostic application ────────────────────────────────────────────────────

-- Re-render vuln diagnostics merging latest-version data from buf_updates.
local function render_vuln_diags(buf)
  local vulns = buf_vulns[buf]
  if not vulns then return end
  local updates = buf_updates[buf] or {}
  local diags   = {}
  for mod_path, vdata in pairs(vulns) do
    local upd = updates[mod_path]
    for _, v in ipairs(vdata.vulns) do
      local msg = v.osv_id .. ': ' .. v.summary
      if v.fixed and v.fixed ~= '' then msg = msg .. ' — fixed in ' .. v.fixed end
      if upd then msg = msg .. ', latest: ' .. upd.latest end
      diags[#diags + 1] = {
        lnum = vdata.lnum, col = 0,
        severity = vim.diagnostic.severity.ERROR,
        source   = 'govulncheck',
        message  = msg,
      }
    end
  end
  vim.diagnostic.set(vuln_ns, buf, diags)
end

-- Set HINT diagnostics for outdated modules. buf must be loaded and in a window.
local function annotate(buf, updates)
  local stored = {}
  local diags  = {}
  local lines  = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for i, line in ipairs(lines) do
    local mod  = line:match '^%s+([%w%.%-%+_/]+)%s+v'
              or line:match '^require%s+([%w%.%-%+_/]+)%s+v'
    local info = mod and updates[mod]
    if info then
      local url   = compare_url(mod, info.current, info.latest)
      local level = semver_level(info.current, info.latest)
      stored[mod] = { lnum = i - 1, latest = info.latest, level = level, url = url }
      diags[#diags + 1] = {
        lnum      = i - 1, col = 0,
        severity  = vim.diagnostic.severity.HINT,
        source    = 'go-updates',
        message   = level .. ' update: ' .. mod .. ' → ' .. info.latest,
        user_data = { latest = info.latest, level = level, url = url },
      }
    end
  end
  buf_updates[buf] = stored
  vim.diagnostic.set(update_ns, buf, diags)
  render_vuln_diags(buf)
end

-- Apply pre-parsed vuln_mods_raw to buf (buf must be loaded and in a window).
local function apply_vuln_mods(buf, vuln_mods_raw)
  local lines    = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local mods_map = parse_gomod_mods(lines)
  local stored   = {}
  for mod_path, vulns in pairs(vuln_mods_raw) do
    stored[mod_path] = { lnum = (mods_map[mod_path] or 1) - 1, vulns = vulns }
  end
  buf_vulns[buf] = stored
  render_vuln_diags(buf)
end

-- ── Buffer-scoped scan functions (require loaded buf in a window) ─────────────

local function refresh(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  local dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':h')
  vim.system(
    { 'go', 'list', '-m', '-u', '-json', 'all' },
    { cwd = dir, text = true },
    vim.schedule_wrap(function(result)
      if not vim.api.nvim_buf_is_valid(buf) then return end
      if result.code ~= 0 or not result.stdout or result.stdout == '' then return end
      annotate(buf, parse_updates(result.stdout))
    end)
  )
end

local function run_vulncheck(buf, silent)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  if vim.fn.executable('govulncheck') ~= 1 then
    vim.notify('govulncheck not found — run: go install golang.org/x/vuln/cmd/govulncheck@latest', vim.log.levels.WARN)
    return
  end
  local dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':h')
  if not silent then vim.notify('govulncheck: scanning…', vim.log.levels.INFO) end
  vim.system(
    { 'govulncheck', '-json', './...' },
    { cwd = dir, text = true },
    vim.schedule_wrap(function(result)
      if not vim.api.nvim_buf_is_valid(buf) then return end
      if not result.stdout or result.stdout == '' then
        vim.notify('govulncheck: no output (exit ' .. result.code .. ')', vim.log.levels.WARN)
        return
      end
      local lines     = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local gomod_mods = parse_gomod_mods(lines)
      local vuln_mods  = parse_vuln_output(result.stdout, gomod_mods)
      local total      = 0
      for _, v in pairs(vuln_mods) do total = total + #v end
      apply_vuln_mods(buf, vuln_mods)
      if total == 0 then
        vim.notify('govulncheck: no vulnerabilities found', vim.log.levels.INFO)
      else
        vim.notify(('govulncheck: %d vulnerability(s) — see go.mod diagnostics'):format(total), vim.log.levels.WARN)
      end
    end)
  )
end

-- ── Background path-based scan (no buffer required) ──────────────────────────

-- Scans go.mod at gomod_path without loading it as a buffer. Results are stored
-- in pending_gomod[path] and applied when go.mod is opened in a window.
local function scan_gomod_path(gomod_path)
  if pending_gomod[gomod_path] then return end
  pending_gomod[gomod_path] = {}

  local dir = vim.fn.fnamemodify(gomod_path, ':h')

  local function buf_in_window(path)
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_get_name(b) == path
          and vim.api.nvim_buf_is_loaded(b)
          and #vim.fn.win_findbuf(b) > 0 then
        return b
      end
    end
  end

  vim.system(
    { 'go', 'list', '-m', '-u', '-json', 'all' },
    { cwd = dir, text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 or not result.stdout or result.stdout == '' then return end
      local updates = parse_updates(result.stdout)
      -- Store for FileType/BufWinEnter if go.mod isn't open yet.
      if pending_gomod[gomod_path] then pending_gomod[gomod_path].updates = updates end
      -- Apply immediately if go.mod is already displayed.
      local buf = buf_in_window(gomod_path)
      if buf then annotate(buf, updates) end
    end)
  )

  if vim.fn.executable('govulncheck') ~= 1 then return end
  vim.system(
    { 'govulncheck', '-json', './...' },
    { cwd = dir, text = true },
    vim.schedule_wrap(function(result)
      if not result.stdout or result.stdout == '' then return end
      local ok, lines = pcall(vim.fn.readfile, gomod_path)
      if not ok then return end
      local vuln_mods = parse_vuln_output(result.stdout, parse_gomod_mods(lines))
      if pending_gomod[gomod_path] then pending_gomod[gomod_path].vuln_mods = vuln_mods end
      local buf = buf_in_window(gomod_path)
      if buf then apply_vuln_mods(buf, vuln_mods) end
    end)
  )
end

local function scan_gomod_for_go_buf(go_buf)
  local dir  = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(go_buf), ':h')
  local rel  = vim.fn.findfile('go.mod', dir .. ';')
  if rel == '' then return end
  scan_gomod_path(vim.fn.fnamemodify(rel, ':p'))
end

-- ── Keymap helpers (gomod buffer) ────────────────────────────────────────────

local function update_diag_at(buf, row)
  for _, d in ipairs(vim.diagnostic.get(buf, { namespace = update_ns })) do
    if d.lnum == row then return d end
  end
end

local function open_url()
  local buf = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local d   = update_diag_at(buf, row)
  local url = d and d.user_data and d.user_data.url
  if url then vim.ui.open(url) else vim.notify('No diff link on this line', vim.log.levels.INFO) end
end

local function update_current()
  local buf  = vim.api.nvim_get_current_buf()
  local row  = vim.api.nvim_win_get_cursor(0)[1] - 1
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
  local mod  = line:match '^%s+([%w%.%-%+_/]+)%s+v'
            or line:match '^require%s+([%w%.%-%+_/]+)%s+v'
  if not mod then vim.notify('No module on this line', vim.log.levels.WARN); return end
  local d = update_diag_at(buf, row)
  if not d then vim.notify(mod .. ' is already up to date', vim.log.levels.INFO); return end
  vim.cmd('GoGet ' .. mod .. '@' .. d.user_data.latest)
  vim.defer_fn(function() refresh(buf) end, 2000)
end

local function do_update_all(buf, allowed)
  local diags = vim.diagnostic.get(buf, { namespace = update_ns })
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local args  = {}
  for _, d in ipairs(diags) do
    local level = d.user_data and d.user_data.level
    if level and allowed[level] then
      local line = lines[d.lnum + 1] or ''
      local mod  = line:match '^%s+([%w%.%-%+_/]+)%s+v'
                or line:match '^require%s+([%w%.%-%+_/]+)%s+v'
      if mod and d.user_data.latest then args[#args + 1] = mod .. '@' .. d.user_data.latest end
    end
  end
  if #args == 0 then vim.notify('No updates at the selected level(s)', vim.log.levels.INFO); return end
  vim.cmd('GoGet ' .. table.concat(args, ' '))
  vim.defer_fn(function() refresh(buf) end, 2000)
end

local function update_all()
  local buf   = vim.api.nvim_get_current_buf()
  local diags = vim.diagnostic.get(buf, { namespace = update_ns })
  if #diags == 0 then vim.notify('All modules are up to date', vim.log.levels.INFO); return end
  local counts = { patch = 0, minor = 0, major = 0 }
  for _, d in ipairs(diags) do
    local l = d.user_data and d.user_data.level
    if l then counts[l] = counts[l] + 1 end
  end
  vim.ui.select({
    { label = ('Patch only  (%d)'):format(counts.patch),                              allowed = { patch = true } },
    { label = ('Patch + Minor  (%d)'):format(counts.patch + counts.minor),            allowed = { patch = true, minor = true } },
    { label = ('All  (%d)'):format(counts.patch + counts.minor + counts.major),       allowed = { patch = true, minor = true, major = true } },
  }, {
    prompt = 'Update go.mod dependencies:',
    format_item = function(c) return c.label end,
  }, function(choice)
    if choice then do_update_all(buf, choice.allowed) end
  end)
end

-- ── Setup ─────────────────────────────────────────────────────────────────────

function M.setup()
  local _notify = vim.notify
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.notify = function(msg, level, opts)
    if type(msg) == 'string' and msg:find('workspace/didChangeWatchedFiles', 1, true) then return end
    return _notify(msg, level, opts)
  end

  -- Opening a .go file triggers a background path-based scan of its go.mod.
  -- Results are held in pending_gomod[path] until go.mod has a window.
  vim.api.nvim_create_autocmd('FileType', {
    pattern  = 'go',
    callback = function(args) scan_gomod_for_go_buf(args.buf) end,
  })

  -- When go.mod enters a window, apply any pending background results immediately
  -- (before FileType gomod, as a fallback for re-displayed hidden buffers).
  vim.api.nvim_create_autocmd('BufWinEnter', {
    callback = function(args)
      local buf  = args.buf
      local path = vim.api.nvim_buf_get_name(buf)
      local p    = path ~= '' and pending_gomod[path]
      if not p then return end
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then return end
        if p.updates   then annotate(buf, p.updates) end
        if p.vuln_mods then apply_vuln_mods(buf, p.vuln_mods) end
        pending_gomod[path] = nil
      end)
    end,
  })

  vim.api.nvim_create_autocmd('FileType', {
    pattern  = 'gomod',
    callback = function(args)
      local buf        = args.buf
      local gomod_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':p')

      -- Apply pending background results synchronously now that go.mod has a window.
      local p = pending_gomod[gomod_path]
      if p then
        if p.updates   then annotate(buf, p.updates) end
        if p.vuln_mods then apply_vuln_mods(buf, p.vuln_mods) end
        pending_gomod[gomod_path] = nil
      end

      -- Fresh scans always run on explicit open / BufWritePost.
      refresh(buf)
      run_vulncheck(buf, true)

      vim.api.nvim_create_autocmd('BufWritePost', {
        buffer   = buf,
        callback = function() refresh(buf) end,
      })
      vim.api.nvim_create_autocmd('BufDelete', {
        buffer   = buf,
        callback = function()
          buf_updates[buf]        = nil
          buf_vulns[buf]          = nil
          pending_gomod[gomod_path] = nil
        end,
      })

      vim.keymap.set('n', '<leader>gv',       function() run_vulncheck(buf) end,  { buffer = buf, desc = 'Go: run govulncheck and show vulnerabilities as diagnostics' })
      vim.keymap.set('n', 'gx',               open_url,                           { buffer = buf, desc = 'Go: open dependency diff URL for module under cursor' })
      vim.keymap.set('n', '<C-LeftMouse>',    function()
        local pos = vim.fn.getmousepos()
        local d   = update_diag_at(buf, pos.line - 1)
        if d and d.user_data and d.user_data.url then vim.ui.open(d.user_data.url) end
      end, { buffer = buf, desc = 'Go: open dependency diff URL' })
      vim.keymap.set('n', '<leader>gmU',      update_all,                         { buffer = buf, desc = 'Go: update ALL outdated modules to latest' })
      vim.keymap.set('n', '<leader>gmu',      update_current,                     { buffer = buf, desc = 'Go: update module under cursor to latest' })
      vim.keymap.set('n', '<leader>gmr',      function() refresh(buf) end,        { buffer = buf, desc = 'Go: refresh module update diagnostics' })
    end,
  })
end

return M
