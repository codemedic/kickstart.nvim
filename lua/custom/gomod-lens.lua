-- gomod-lens: virtual-text annotations showing available dependency updates in go.mod.
--
-- On go.mod open and save, runs `go list -m -u -json all` async and injects
-- an EOL hint (e.g. "→ v1.21.0") next to each outdated require line.
-- The annotation is an OSC-8 hyperlink to the compare diff on GitHub/GitLab/Bitbucket.
-- <leader>gmu  update module under cursor
-- <leader>gmU  update ALL outdated modules
-- <leader>gmr  refresh annotations

local M = {}

local ns = vim.api.nvim_create_namespace 'gomod_lens'

-- go list outputs one JSON object per module (not an array), so split by brace depth.
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

-- Build a compare/diff URL for the given module path and versions.
-- Returns nil for unknown hosts.
local function compare_url(mod_path, current, latest)
  -- Strip /vN major-version suffix (v2+) before extracting repo segments.
  local path = mod_path:gsub('/v%d+$', '')

  -- Take at most host/owner/repo (first three slash-separated segments).
  local segs = {}
  for seg in path:gmatch '[^/]+' do
    segs[#segs + 1] = seg
    if #segs == 3 then break end
  end
  if #segs < 3 then return nil end

  local host      = segs[1]
  local repo_path = table.concat(segs, '/')

  if host == 'github.com' then
    return ('https://%s/compare/%s...%s'):format(repo_path, current, latest)
  elseif host == 'gitlab.com' then
    return ('https://%s/-/compare/%s...%s'):format(repo_path, current, latest)
  elseif host == 'bitbucket.org' then
    -- Bitbucket compare syntax reverses the order and uses two dots.
    return ('https://%s/branches/compare/%s..%s'):format(repo_path, latest, current)
  end

  return nil
end

-- Clear and re-draw virtual text for all outdated requires in the buffer.
local function annotate(buf, updates)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for i, line in ipairs(lines) do
    local mod = line:match '^%s+([%w%.%-%+_/]+)%s+v'
             or line:match '^require%s+([%w%.%-%+_/]+)%s+v'
    local info = mod and updates[mod]
    if info then
      local url = compare_url(mod, info.current, info.latest)
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
        virt_text     = { { '  → ' .. info.latest, 'DiagnosticHint' } },
        virt_text_pos = 'eol',
        hl_mode       = 'combine',
        url           = url,  -- OSC-8 hyperlink; nil is a no-op
      })
    end
  end
end

-- Run go list async in the module directory and annotate on completion.
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

-- Update every annotated module in the buffer in a single go get invocation.
local function update_all()
  local buf   = vim.api.nvim_get_current_buf()
  local marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
  if not marks or #marks == 0 then
    vim.notify('All modules are up to date', vim.log.levels.INFO)
    return
  end

  local args  = {}
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for _, mark in ipairs(marks) do
    local row    = mark[2]
    local line   = lines[row + 1] or ''
    local mod    = line:match '^%s+([%w%.%-%+_/]+)%s+v'
                or line:match '^require%s+([%w%.%-%+_/]+)%s+v'
    local virt   = mark[4].virt_text
    local latest = virt and virt[1] and virt[1][1]:match '→%s+(v[%w%.%-%+]+)'
    if mod and latest then
      args[#args + 1] = mod .. '@' .. latest
    end
  end

  if #args == 0 then return end
  vim.cmd('GoGet ' .. table.concat(args, ' '))
  vim.defer_fn(function() refresh(buf) end, 2000)
end

-- Update the module on the current line to the version shown in the annotation.
local function update_current()
  local buf  = vim.api.nvim_get_current_buf()
  local row  = vim.api.nvim_win_get_cursor(0)[1] - 1
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]

  local mod = line:match '^%s+([%w%.%-%+_/]+)%s+v'
           or line:match '^require%s+([%w%.%-%+_/]+)%s+v'
  if not mod then
    vim.notify('No module on this line', vim.log.levels.WARN)
    return
  end

  local marks = vim.api.nvim_buf_get_extmarks(buf, ns, { row, 0 }, { row, -1 }, { details = true })
  if not marks or #marks == 0 then
    vim.notify(mod .. ' is already up to date', vim.log.levels.INFO)
    return
  end

  local virt   = marks[1][4].virt_text
  local latest = virt and virt[1] and virt[1][1]:match '→%s+(v[%w%.%-%+]+)'
  if not latest then return end

  vim.cmd('GoGet ' .. mod .. '@' .. latest)
  vim.defer_fn(function() refresh(buf) end, 2000)
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

      vim.api.nvim_create_autocmd('BufWritePost', {
        buffer   = buf,
        callback = function() refresh(buf) end,
      })

      -- Open the compare URL from the annotation on the current line.
      local function open_url()
        local row   = vim.api.nvim_win_get_cursor(0)[1] - 1
        local marks = vim.api.nvim_buf_get_extmarks(buf, ns, { row, 0 }, { row, -1 }, { details = true })
        for _, mark in ipairs(marks) do
          local url = mark[4] and mark[4].url
          if url then vim.ui.open(url) return end
        end
        vim.notify('No diff link on this line', vim.log.levels.INFO)
      end

      -- <C-LeftMouse> defaults to a tag jump; override it for gomod buffers so
      -- clicking on an annotation opens the compare URL in the browser instead.
      vim.keymap.set('n', '<C-LeftMouse>', function()
        local pos   = vim.fn.getmousepos()
        local row   = pos.line - 1
        local marks = vim.api.nvim_buf_get_extmarks(buf, ns, { row, 0 }, { row, -1 }, { details = true })
        for _, mark in ipairs(marks) do
          local url = mark[4] and mark[4].url
          if url then vim.ui.open(url) return end
        end
        -- No annotation on this line — nothing useful to do in a go.mod file.
      end, { buffer = buf, desc = 'Go: open dependency diff URL' })

      vim.keymap.set('n', 'gx', open_url, {
        buffer = buf,
        desc   = 'Go: open dependency diff URL for module under cursor',
      })

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
        desc   = 'Go: refresh module update annotations',
      })
    end,
  })
end

return M
