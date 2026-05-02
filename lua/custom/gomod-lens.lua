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

-- Per-buffer state shared between the update and vuln scans so that whichever
-- finishes last can incorporate the other's data into the rendered diagnostics.
-- buf_updates[buf] = { [mod_path] = { lnum, latest, level, url } }
-- buf_vulns[buf]   = { [mod_path] = { lnum, vulns = [{osv_id, fixed, summary}] } }
local buf_updates = {}
local buf_vulns   = {}

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

-- Returns map of module path → { current, latest } for modules with updates only.
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

-- Parse a semver string (e.g. "v1.2.3") into {major, minor, patch} integers.
local function parse_semver(v)
  local maj, min, pat = v:match '^v?(%d+)%.(%d+)%.(%d+)'
  if maj then
    return { major = tonumber(maj), minor = tonumber(min), patch = tonumber(pat) }
  end
  -- Fallback for non-standard versions (pre-release, pseudo-versions, etc.)
  local maj2 = v:match '^v?(%d+)'
  return { major = tonumber(maj2) or 0, minor = 0, patch = 0 }
end

-- Classify the bump level between two semver strings.
-- Returns 'major', 'minor', or 'patch'.
local function semver_level(current, latest)
  local c = parse_semver(current)
  local l = parse_semver(latest)
  if l.major ~= c.major then return 'major' end
  if l.minor ~= c.minor then return 'minor' end
  return 'patch'
end

-- Build a compare/diff URL for the given module path and versions.
-- Handles monorepos where tags are prefixed with the sub-module path:
--   github.com/aws/aws-sdk-go-v2/aws/protocol/eventstream
--   → repo: github.com/aws/aws-sdk-go-v2
--   → tags: aws/protocol/eventstream/v1.6.9...aws/protocol/eventstream/v1.7.10
local function compare_url(mod_path, current, latest)
  -- Strip /vN major-version suffix before splitting.
  local path = mod_path:gsub('/v%d+$', '')
  local segs  = {}
  for seg in path:gmatch '[^/]+' do segs[#segs + 1] = seg end
  if #segs < 3 then return nil end

  local host      = segs[1]
  local repo_path = table.concat(segs, '/', 1, 3)
  -- For monorepo sub-modules, tags are prefixed with the path inside the repo.
  local sub       = #segs > 3 and (table.concat(segs, '/', 4) .. '/') or ''
  local cur_tag   = sub .. current
  local new_tag   = sub .. latest

  if host == 'github.com' then
    return ('https://%s/compare/%s...%s'):format(repo_path, cur_tag, new_tag)
  elseif host == 'gitlab.com' then
    return ('https://%s/-/compare/%s...%s'):format(repo_path, cur_tag, new_tag)
  elseif host == 'bitbucket.org' then
    return ('https://%s/branches/compare/%s..%s'):format(repo_path, new_tag, cur_tag)
  end
  return nil
end

-- Re-render vuln diagnostics, merging latest version from buf_updates when available.
-- Called by both annotate() and run_vulncheck() so whichever finishes last wins.
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
        lnum     = vdata.lnum,
        col      = 0,
        severity = vim.diagnostic.severity.ERROR,
        source   = 'govulncheck',
        message  = msg,
      }
    end
  end
  vim.diagnostic.set(vuln_ns, buf, diags)
end

-- Emit HINT diagnostics for outdated modules. Each diagnostic carries the
-- target version and diff URL in user_data for use by update keymaps and gx.
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
        lnum      = i - 1,
        col       = 0,
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

-- Run go list async and refresh update diagnostics on completion.
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

-- Return the update diagnostic on the given row, if any.
local function update_diag_at(buf, row)
  for _, d in ipairs(vim.diagnostic.get(buf, { namespace = update_ns })) do
    if d.lnum == row then return d end
  end
end

-- Open the diff URL for the module on the current line.
local function open_url()
  local buf = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local d   = update_diag_at(buf, row)
  local url = d and d.user_data and d.user_data.url
  if url then
    vim.ui.open(url)
  else
    vim.notify('No diff link on this line', vim.log.levels.INFO)
  end
end

-- Update the module on the current line to the version in its update diagnostic.
local function update_current()
  local buf = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
  local mod  = line:match '^%s+([%w%.%-%+_/]+)%s+v'
            or line:match '^require%s+([%w%.%-%+_/]+)%s+v'
  if not mod then
    vim.notify('No module on this line', vim.log.levels.WARN)
    return
  end
  local d = update_diag_at(buf, row)
  if not d then
    vim.notify(mod .. ' is already up to date', vim.log.levels.INFO)
    return
  end
  vim.cmd('GoGet ' .. mod .. '@' .. d.user_data.latest)
  vim.defer_fn(function() refresh(buf) end, 2000)
end

-- Update all modules whose bump level is included in `allowed` (set of strings).
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
      if mod and d.user_data.latest then
        args[#args + 1] = mod .. '@' .. d.user_data.latest
      end
    end
  end
  if #args == 0 then
    vim.notify('No updates at the selected level(s)', vim.log.levels.INFO)
    return
  end
  vim.cmd('GoGet ' .. table.concat(args, ' '))
  vim.defer_fn(function() refresh(buf) end, 2000)
end

-- Prompt the user for which update level to apply, then run the bulk update.
local function update_all()
  local buf   = vim.api.nvim_get_current_buf()
  local diags = vim.diagnostic.get(buf, { namespace = update_ns })
  if #diags == 0 then
    vim.notify('All modules are up to date', vim.log.levels.INFO)
    return
  end

  -- Count by level so the picker shows meaningful context.
  local counts = { patch = 0, minor = 0, major = 0 }
  for _, d in ipairs(diags) do
    local l = d.user_data and d.user_data.level
    if l then counts[l] = counts[l] + 1 end
  end

  local choices = {
    { label = ('Patch only  (%d)'):format(counts.patch),
      allowed = { patch = true } },
    { label = ('Patch + Minor  (%d)'):format(counts.patch + counts.minor),
      allowed = { patch = true, minor = true } },
    { label = ('All  (%d)'):format(counts.patch + counts.minor + counts.major),
      allowed = { patch = true, minor = true, major = true } },
  }

  vim.ui.select(choices, {
    prompt  = 'Update go.mod dependencies:',
    format_item = function(c) return c.label end,
  }, function(choice)
    if choice then do_update_all(buf, choice.allowed) end
  end)
end

-- Run govulncheck -json and surface results as ERROR diagnostics on go.mod lines.
-- Pass silent=true for background auto-runs to suppress the "scanning…" notice.
local function run_vulncheck(buf, silent)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  if not vim.fn.executable 'govulncheck' then
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

      local osvs    = {}   -- id → { summary, packages }
      local findings = {}  -- id → fixed_version

      for _, json_str in ipairs(split_json_objects(result.stdout)) do
        local ok, obj = pcall(vim.json.decode, json_str)
        if ok and obj then
          if obj.osv then
            local pkgs = {}
            for _, aff in ipairs(obj.osv.affected or {}) do
              if aff.package and aff.package.name then
                pkgs[#pkgs + 1] = aff.package.name
              end
            end
            osvs[obj.osv.id] = { summary = obj.osv.summary or obj.osv.id, packages = pkgs }
          elseif obj.finding and obj.finding.osv then
            local f = obj.finding
            if not findings[f.osv] then findings[f.osv] = f.fixed_version or '' end
          end
        end
      end

      -- Index go.mod module paths → line number (1-based).
      local gomod_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local gomod_mods  = {}
      for i, line in ipairs(gomod_lines) do
        local mod = line:match '^%s+([%w%.%-%+_/]+)%s+v'
                 or line:match '^require%s+([%w%.%-%+_/]+)%s+v'
        if mod then gomod_mods[mod] = i end
      end

      -- Map each finding to its go.mod module via OSV package prefix matching.
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
                  osv_id  = osv_id,
                  fixed   = fixed,
                  summary = osv.summary,
                }
              end
            end
          end
        end
      end

      local stored_vulns = {}
      local total_vulns  = 0
      for mod_path, vulns in pairs(vuln_mods) do
        stored_vulns[mod_path] = {
          lnum  = (gomod_mods[mod_path] or 1) - 1,
          vulns = vulns,
        }
        total_vulns = total_vulns + #vulns
      end
      buf_vulns[buf] = stored_vulns
      render_vuln_diags(buf)

      if total_vulns == 0 then
        vim.notify('govulncheck: no vulnerabilities found', vim.log.levels.INFO)
      else
        vim.notify(('govulncheck: %d vulnerability(s) — see go.mod diagnostics'):format(total_vulns), vim.log.levels.WARN)
      end
    end)
  )
end

function M.setup()
  -- go.nvim sends workspace/didChangeWatchedFiles after GoGet rewrites go.mod,
  -- but gopls is not attached to gomod buffers (kickstart only registers it for
  -- go filetype). Filter the resulting noise out of the message area.
  local _notify = vim.notify
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.notify = function(msg, level, opts)
    if type(msg) == 'string' and msg:find('workspace/didChangeWatchedFiles', 1, true) then
      return
    end
    return _notify(msg, level, opts)
  end

  vim.api.nvim_create_autocmd('FileType', {
    pattern  = 'gomod',
    callback = function(args)
      local buf = args.buf

      refresh(buf)
      run_vulncheck(buf, true)

      vim.api.nvim_create_autocmd('BufWritePost', {
        buffer   = buf,
        callback = function() refresh(buf) end,
      })

      vim.api.nvim_create_autocmd('BufDelete', {
        buffer   = buf,
        callback = function()
          buf_updates[buf] = nil
          buf_vulns[buf]   = nil
        end,
      })

      vim.keymap.set('n', '<leader>gv', function() run_vulncheck(buf) end, {
        buffer = buf,
        desc   = 'Go: run govulncheck and show vulnerabilities as diagnostics',
      })
      vim.keymap.set('n', 'gx', open_url, {
        buffer = buf,
        desc   = 'Go: open dependency diff URL for module under cursor',
      })
      vim.keymap.set('n', '<C-LeftMouse>', function()
        local pos = vim.fn.getmousepos()
        local row = pos.line - 1
        local d   = update_diag_at(buf, row)
        local url = d and d.user_data and d.user_data.url
        if url then vim.ui.open(url) end
      end, { buffer = buf, desc = 'Go: open dependency diff URL' })
      vim.keymap.set('n', '<leader>gmU', update_all, {
        buffer = buf,
        desc   = 'Go: update ALL outdated modules to latest',
      })
      vim.keymap.set('n', '<leader>gmu', update_current, {
        buffer = buf,
        desc   = 'Go: update module under cursor to latest',
      })
      vim.keymap.set('n', '<leader>gmr', function() refresh(buf) end, {
        buffer = buf,
        desc   = 'Go: refresh module update diagnostics',
      })
    end,
  })
end

return M
