# Neovim Config — Claude Instructions

## File Placement Rules

**`init.lua` is read-only upstream (kickstart.nvim).** You MUST NOT edit it under any circumstances. Doing so causes merge conflicts on upstream updates.

All additions MUST go in one of:
- `after/plugin/options.lua` — vim options and `vim.opt.*` settings
- `after/plugin/keymaps.lua` — keymaps
- `after/plugin/gui.lua` — GUI-specific settings
- `lua/custom/plugins/<name>.lua` — plugin specs and overrides (Lazy.nvim merges these)
- `lua/custom/` — general custom modules

## Keybinding Tips (`lua/custom/keytips.lua`)

`keytips.lua` contains a **hand-curated static list** of keybinding tips shown at startup and via `:KeyTip`.

**You MUST keep this file in sync whenever keybindings change:**

- A new keymap is added anywhere in the config → add a corresponding tip
- A keymap is removed or rebound → update or remove the tip
- A new plugin with keybindings is added → add its most useful bindings as tips

The tips table is the source of truth for what the user is expected to learn. Stale or missing entries defeat the purpose of the feature.
