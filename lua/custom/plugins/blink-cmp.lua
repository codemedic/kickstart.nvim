-- Use the Rust fuzzy binary for better performance.
-- blink.cmp will download a prebuilt binary on :Lazy build blink.cmp
return {
  'saghen/blink.cmp',
  opts = {
    keymap = {
      -- 'super-tab': Tab accepts the selected (or first) item, like JetBrains IDEs.
      -- When the menu is closed, Tab falls through to Copilot ghost-text acceptance.
      preset = 'super-tab',
    },
    completion = {
      list = {
        selection = {
          -- Pre-highlight the first item when the menu opens so one Tab press accepts it.
          preselect = true,
          -- Don't auto-insert as you type — wait for explicit Tab/Enter.
          auto_insert = false,
        },
      },
    },
    fuzzy = { implementation = 'prefer_rust_with_warning', prebuilt_binaries = { download = true } },
  },
}
