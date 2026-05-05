---@module 'lazy'
---@type LazySpec
return {
  'chrisgrieser/nvim-origami',
  event = 'VeryLazy',
  opts = {
    -- LSP fold ranges load asynchronously and override treesitter's foldexpr
    -- via LspAttach, causing E490 ("No fold found") when folding before the
    -- LSP responds. Treesitter has comprehensive fold queries for all configured
    -- languages; LSP folding adds no benefit here.
    useLspFoldsWithTreesitterFallback = { enabled = false },
  },
}
