# Nvim Notes

## Treesitter: Clean Slate Reset

To fully reset all installed parsers, remove all three state directories:

```bash
rm -rf ~/.local/share/nvim/site/parser/
rm -rf ~/.local/share/nvim/site/parser-info/
rm -rf ~/.local/share/nvim/site/queries/
```

Deleting only `parser/` leaves stale `parser-info/` and `queries/` entries, causing `TSInstall` to silently skip reinstallation (it considers the language already installed if queries exist).

Use `:TSInstall! <lang>` (with bang) to force reinstall without clearing directories.
