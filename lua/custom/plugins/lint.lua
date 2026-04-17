-- Override the lint autocmd from kickstart's lint plugin.
-- For filetypes listed in ft_config_guards, linting only runs when at least
-- one of the specified config files is found anywhere up the directory tree.
-- Filetypes not in the map are linted unconditionally (upstream behaviour).
return {
  'mfussenegger/nvim-lint',
  config = function()
    -- Re-create the augroup (clear = true replaces the upstream callback).
    local lint = require 'lint'
    local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })

    -- Map of filetype → config file names that must exist in the repo.
    ---@type table<string, string[]>
    local ft_config_guards = {
      markdown = {
        '.markdownlint.json', '.markdownlint.jsonc',
        '.markdownlint.yaml', '.markdownlint.yml',
        '.markdownlintrc',
        '.markdownlint-cli2.jsonc', '.markdownlint-cli2.yaml', '.markdownlint-cli2.cjs',
      },
    }

    local function guarded_by_config(ft)
      local guards = ft_config_guards[ft]
      if not guards then return false end -- no guard → lint unconditionally
      local dir = vim.fn.expand '%:p:h'
      for _, f in ipairs(guards) do
        if vim.fn.findfile(f, dir .. ';') ~= '' then return false end
      end
      return true -- guarded and no config found → skip
    end

    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
      group = lint_augroup,
      callback = function()
        if not vim.bo.modifiable then return end
        if guarded_by_config(vim.bo.filetype) then return end
        lint.try_lint()
      end,
    })
  end,
}
