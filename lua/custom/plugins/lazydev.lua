-- lazydev.nvim: faster lua_ls setup with full plugin API autocomplete.
-- Replaces mass-indexing of all runtimepath directories with on-demand type
-- information sourced directly from lazy.nvim's plugin registry.
return {
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
}
