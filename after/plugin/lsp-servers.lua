-- Custom LSP servers — kept here to avoid merge conflicts with upstream init.lua.
-- Mason auto-install is handled via the vim.list_extend block in init.lua.
vim.lsp.enable { 'clangd', 'gopls', 'bashls', 'cmake', 'docker_compose_language_service', 'dockerls', 'pyright', 'rust_analyzer' }
