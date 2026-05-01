return {
  'ray-x/go.nvim',
  ft = { 'go', 'gomod', 'gowork', 'gosum' },
  dependencies = {
    'ray-x/guihua.lua',
    'nvim-treesitter/nvim-treesitter',
    'nvim-lua/plenary.nvim',
  },
  build = function()
    require('go.install').update_all_sync()
  end,
  config = function()
    require('custom.gomod-lens').setup()

    require('go').setup {
      -- kickstart.nvim already manages gopls via mason + lspconfig
      lsp_cfg        = false,
      lsp_gofumpt    = false,
      lsp_keymaps    = false,
      -- no DAP configured in this setup
      dap_debug      = false,
    }

    -- Module / workspace / vuln keymaps, scoped to Go filetypes.
    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'go', 'gomod', 'gowork', 'gosum' },
      callback = function(args)
        local buf = args.buf
        local map = function(keys, fn, desc)
          vim.keymap.set('n', keys, fn, { buffer = buf, desc = desc })
        end

        map('<leader>gmt', '<Cmd>GoModTidy<CR>',    'Go: mod tidy')
        map('<leader>gmv', '<Cmd>GoModVendor<CR>',  'Go: mod vendor')
        map('<leader>gmg', function()
          vim.ui.input({ prompt = 'go get: ' }, function(pkg)
            if pkg and pkg ~= '' then vim.cmd('GoGet ' .. pkg) end
          end)
        end, 'Go: get <pkg>')
        map('<leader>gmi', function()
          vim.ui.input({ prompt = 'module name: ' }, function(mod)
            if mod and mod ~= '' then vim.cmd('GoMod init ' .. mod) end
          end)
        end, 'Go: mod init <module>')
        map('<leader>gws', '<Cmd>GoWork sync<CR>',  'Go: work sync')
        map('<leader>gwa', function()
          vim.ui.input({ prompt = 'go work use: ' }, function(path)
            if path and path ~= '' then vim.cmd('GoWork use ' .. path) end
          end)
        end, 'Go: work use <path>')
        map('<leader>gv',  '<Cmd>GoVulnCheck<CR>',  'Go: vulnerability check')
      end,
    })
  end,
}
