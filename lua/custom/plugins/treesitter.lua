-- Auto-install missing treesitter parsers on demand.
--
-- When a FileType is detected and its parser is not installed, this autocmd
-- triggers installation and then polls until the parser is ready, at which
-- point treesitter is started on the buffer without requiring a restart.
--
-- force=true is required to bypass stale state in parser-info/ and queries/
-- directories, which would otherwise cause the install to silently no-op.
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local language = vim.treesitter.language.get_lang(args.match)
    if not language then return end

    local ok, loaded = pcall(vim.treesitter.language.add, language)
    if not ok or not loaded then
      require('nvim-treesitter.install').install({ language }, { force = true })

      -- Install is async; poll until the parser is loadable, then start
      -- treesitter on the buffer. Gives up after ~15s (30 × 500ms).
      local buf = args.buf
      local function reload_when_ready(attempts)
        if attempts > 30 then return end
        local ready = vim.api.nvim_buf_is_valid(buf)
          and pcall(vim.treesitter.language.add, language)
          and pcall(vim.treesitter.start, buf, language)
        if not ready then
          vim.defer_fn(function() reload_when_ready(attempts + 1) end, 500)
        end
      end
      reload_when_ready(0)
    end
  end,
})

---@module 'lazy'
---@type LazySpec
return {}
