return {
  {
    'github/copilot.vim',
    config = function()
      -- Accept next word (mirrors VS Code's Ctrl+Right progressive acceptance)
      vim.keymap.set('i', '<C-Right>', 'copilot#AcceptWord()', { expr = true, replace_keycodes = false })
    end,
  },

  -- {
  --   'zbirenbaum/copilot.lua',
  --   config = function()
  --     require('copilot').setup {
  --       filetypes = {
  --         markdown = true, -- overrides default
  --         terraform = false, -- disallow specific filetype
  --         sh = function()
  --           if string.match(vim.fs.basename(vim.api.nvim_buf_get_name(0)), '^%.env.*') then
  --             -- disable for .env files
  --             return false
  --           end
  --           return true
  --         end,
  --       },
  --     }
  --   end,
  -- },
}
