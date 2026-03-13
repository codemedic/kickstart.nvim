# Neovim Config — Claude Instructions

## Keybinding Tips (`lua/custom/keytips.lua`)

`keytips.lua` contains a **hand-curated static list** of keybinding tips shown at startup and via `:KeyTip`.

**You MUST keep this file in sync whenever keybindings change:**

- A new keymap is added anywhere in the config → add a corresponding tip
- A keymap is removed or rebound → update or remove the tip
- A new plugin with keybindings is added → add its most useful bindings as tips

The tips table is the source of truth for what the user is expected to learn. Stale or missing entries defeat the purpose of the feature.
