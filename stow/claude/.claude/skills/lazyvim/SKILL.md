---
name: lazyvim
description: "Configuring Neovim in this setup (LazyVim): plugin specs, overriding defaults, keymaps, extras, LSP, formatters, and troubleshooting."
argument-hint: "the LazyVim change (e.g. 'add a plugin', 'override jdtls settings', 'add a keymap')"
---

# LazyVim

Config is `~/.config/nvim`, stowed from `stow/nvim/.config/nvim/`. Read the files before changing
them; the upstream docs (https://www.lazyvim.org) are the reference, not memory.

- Extras are enabled through `:LazyExtras` and recorded in `lazyvim.json` — do not add
  `import = "lazyvim.plugins.extras..."` lines to `lua/config/lazy.lua` as well.
- Own specs live in `lua/plugins/`: `ide.lua` (completion), `java.lua` (jdtls).
  `example.lua` is the LazyVim starter's inert example — never a place for real config.
- Completion is `blink.cmp`, not `nvim-cmp`.
- `lua/config/{options,keymaps,autocmds}.lua` are loaded by LazyVim; never `require()` them.
