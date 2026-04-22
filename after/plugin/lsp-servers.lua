-- Custom LSP servers — kept here to avoid merge conflicts with upstream init.lua.
-- Mason auto-install is handled via the vim.list_extend block in init.lua.
vim.lsp.enable { 'clangd', 'gopls', 'bashls', 'cmake', 'docker_compose_language_service', 'dockerls', 'pyright', 'rust_analyzer' }

-- PHP: intelephense — auto-install via Mason registry if not already present.
vim.api.nvim_create_autocmd('User', {
  pattern = 'LazyDone',
  once = true,
  callback = function()
    local ok, registry = pcall(require, 'mason-registry')
    if not ok then return end
    local pkg = registry.get_package 'intelephense'
    if not pkg:is_installed() then
      vim.notify('Mason: installing intelephense…', vim.log.levels.INFO)
      pkg:install()
    end
  end,
})
vim.lsp.enable { 'intelephense' }
