-- Auto-install missing treesitter parsers on demand.
--
-- When a FileType is detected and its parser is not installed, the user is
-- prompted for confirmation. If accepted, the parser is installed and treesitter
-- is started on the buffer once ready — no restart required.
--
-- Design notes:
--   - Prompts are serialised via a queue so that opening multiple files with
--     missing parsers at once does not trigger simultaneous installs.
--   - Each language is prompted at most once per session (accepted or declined).
--   - Languages not known to nvim-treesitter (e.g. internal Telescope UI buffer
--     types like TelescopePrompt) are silently ignored.
--   - force=true bypasses stale state in parser-info/ and queries/ directories,
--     which would otherwise cause the install to silently no-op.

local queue = {} ---@type {language: string, buf: integer}[]
local busy = false
local prompted = {} ---@type table<string, boolean>

--- Poll every 500ms until the parser is loadable, then start treesitter on the
--- buffer. Gives up after ~15s (30 × 500ms) to avoid polling indefinitely on
--- install failure.
local function poll_until_ready(buf, language)
  local function attempt(n)
    if n > 30 then return end
    local ready = vim.api.nvim_buf_is_valid(buf)
      and pcall(vim.treesitter.language.add, language)
      and pcall(vim.treesitter.start, buf, language)
    if not ready then
      vim.defer_fn(function() attempt(n + 1) end, 500)
    end
  end
  attempt(0)
end

--- Process the next item in the queue. Prompts the user, then installs if
--- confirmed. Calls itself recursively to drain the queue.
local function process_queue()
  if busy or #queue == 0 then return end
  busy = true

  local item = table.remove(queue, 1)
  vim.ui.select(
    { 'Yes', 'No' },
    { prompt = ('Install treesitter parser for %s?'):format(item.language) },
    function(choice)
      prompted[item.language] = true
      if choice == 'Yes' then
        require('nvim-treesitter.install').install({ item.language }, { force = true })
        poll_until_ready(item.buf, item.language)
      end
      busy = false
      process_queue()
    end
  )
end

vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local language = vim.treesitter.language.get_lang(args.match)
    if not language then return end

    local ok, loaded = pcall(vim.treesitter.language.add, language)
    if not ok or not loaded then
      -- Ignore languages not known to nvim-treesitter (e.g. Telescope UI buffers)
      if not require('nvim-treesitter.parsers')[language] then return end
      -- Skip if already prompted this session or already in the queue
      if prompted[language] then return end
      for _, item in ipairs(queue) do
        if item.language == language then return end
      end
      table.insert(queue, { language = language, buf = args.buf })
      process_queue()
    end
  end,
})

---@module 'lazy'
---@type LazySpec
return {}
