-- GoLand-style "search everywhere" built on Telescope.
-- Opens as project file search by default. Typing a recognised prefix auto-switches:
--   >  →  Vim commands           (GoLand: Actions)
--   @  →  LSP workspace symbols  (GoLand: Symbols)
--   /  →  live grep              (GoLand: Text)
-- The text you've already typed is carried into the new picker (minus the prefix).
-- Alt+c / Alt+s are manual mode-switch keys that also carry the current text.

local M = {}

local prefixes = { ['>'] = 'commands', ['@'] = 'symbols', ['/'] = 'grep' }

local function open_mode(mode, text)
  local builtin = require('telescope.builtin')
  text = text or ''
  if mode == 'commands' then
    builtin.commands({ default_text = text, prompt_title = 'Commands   (Search Everywhere)' })
  elseif mode == 'symbols' then
    -- lsp_workspace_symbols with an empty query makes one-shot LSP call, gets no
    -- results and exits without opening a picker. Use the dynamic variant instead
    -- which is a live picker — it queries the LSP as you type.
    -- Wrap the default entry_maker to filter out non-project files (same rationale
    -- as references: gopls returns stdlib symbols alongside project ones).
    local cwd         = vim.fn.resolve(vim.uv.cwd()) .. '/'
    local make_entry  = require('telescope.make_entry')
    local opts        = { default_text = text, prompt_title = 'Symbols   (Search Everywhere)' }
    local base_maker  = make_entry.gen_from_lsp_symbols(opts)
    opts.entry_maker  = function(item)
      if not item.filename then return nil end
      if vim.fn.resolve(item.filename):sub(1, #cwd) ~= cwd then return nil end
      return base_maker(item)
    end
    builtin.lsp_dynamic_workspace_symbols(opts)
  elseif mode == 'grep' then
    builtin.live_grep({ default_text = text, prompt_title = 'Grep   (Search Everywhere)' })
  end
end

local function make_switch(mode)
  return function(prompt_bufnr)
    local actions      = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    local text = action_state.get_current_line()
    actions.close(prompt_bufnr)
    vim.schedule(function() vim.schedule(function() open_mode(mode, text) end) end)
  end
end

function M.open()
  local builtin      = require('telescope.builtin')
  local actions      = require('telescope.actions')
  local action_state = require('telescope.actions.state')

  builtin.find_files({
    prompt_title = 'Search Everywhere   > cmds · @ symbols · / grep',
    attach_mappings = function(prompt_bufnr, map)

      -- Manual switches carry current text into the new mode
      for _, mode_pair in ipairs({ { '<M-c>', 'commands' }, { '<M-s>', 'symbols' } }) do
        local key, mode = mode_pair[1], mode_pair[2]
        map('i', key, make_switch(mode))
        map('n', key, make_switch(mode))
      end

      -- Auto-switch when the prompt starts with a recognised prefix character.
      -- vim.schedule_wrap + buf_is_valid guard prevents double-firing: once we
      -- call actions.close the buffer becomes invalid so subsequent callbacks exit.
      vim.api.nvim_create_autocmd('TextChangedI', {
        buffer = prompt_bufnr,
        callback = vim.schedule_wrap(function()
          if not vim.api.nvim_buf_is_valid(prompt_bufnr) then return end
          local line  = action_state.get_current_line()
          local mode  = prefixes[line:sub(1, 1)]
          if mode then
            local text = line:sub(2):match('^%s*(.*)$') or ''
            actions.close(prompt_bufnr)
            -- Second schedule lets the close fully settle before the new picker opens.
            vim.schedule(function() open_mode(mode, text) end)
          end
        end),
      })

      return true
    end,
  })
end

return M
