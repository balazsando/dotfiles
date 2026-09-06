---
name: lazyvim
description: "Configuring LazyVim: plugin specs, customising or disabling defaults, keymaps, :LazyExtras, LSP/formatters/linters, lua/config files, and troubleshooting."
argument-hint: "Describe the LazyVim task (e.g., 'add a plugin', 'override LSP settings', 'enable Java extra', 'change colorscheme', 'add custom keymap')"
---

# LazyVim Skill

**Detail lives in `references/`** — read the file the task needs, not both.

- `references/setup-and-extras.md` — `lazy.lua` bootstrap, LazyVim global `opts`, `:LazyExtras`
  and the Java extra, default keymaps, colorscheme, Snacks.nvim.
- `references/lsp-and-tooling.md` — LSP servers and per-server setup, inlay hints, Mason,
  conform.nvim formatters, nvim-lint linters, Treesitter.

---

## Directory Structure

```
~/.config/nvim/
├── init.lua                    ← bootstrap lazy.nvim + LazyVim
└── lua/
    ├── config/
    │   ├── autocmds.lua        ← custom autocmds (auto-loaded on VeryLazy)
    │   ├── keymaps.lua         ← custom keymaps  (auto-loaded on VeryLazy)
    │   ├── lazy.lua            ← lazy.nvim bootstrap + LazyVim setup
    │   └── options.lua         ← vim options     (auto-loaded at startup)
    └── plugins/
        ├── any-name.lua        ← plugin specs (all files auto-loaded)
        └── ...
```

> **Do NOT** `require()` files under `lua/config/` manually — LazyVim loads them automatically.

---

## Plugin Spec Patterns

### Adding a plugin
```lua
-- lua/plugins/extras.lua
return {
  {
    "simrat39/symbols-outline.nvim",
    cmd = "SymbolsOutline",
    keys = { { "<leader>cs", "<cmd>SymbolsOutline<cr>", desc = "Symbols Outline" } },
    opts = { position = "right" },
  },
}
```

### Disabling a default plugin
```lua
return {
  { "folke/trouble.nvim", enabled = false },
}
```

### Overriding plugin opts (merged, not replaced)
```lua
return {
  {
    "folke/trouble.nvim",
    opts = { use_diagnostic_signs = true },
  },
}
```

### Extending opts with a function (modify defaults in-place)
```lua
return {
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-emoji" },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      table.insert(opts.sources, { name = "emoji" })
    end,
  },
}
```

### Adding a keymap to an existing plugin
```lua
return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      { "<leader>fp", function()
          require("telescope.builtin").find_files({
            cwd = require("lazy.core.config").options.root
          })
        end, desc = "Find Plugin File" },
    },
  },
}
```

### Disabling a default keymap
```lua
return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      { "<leader>/", false },  -- disable grep keymap
    },
  },
}
```

### Replacing all keymaps for a plugin
```lua
return {
  {
    "nvim-telescope/telescope.nvim",
    keys = function()
      return {
        { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      }
    end,
  },
}
```

> **Merging rules**: `cmd`, `event`, `ft`, `keys`, `opts`, `dependencies` are **merged**. Any other property **overrides**.

---

## Config Files

### `lua/config/options.lua`
```lua
-- Loaded before lazy.nvim, before plugins
vim.opt.relativenumber = true
vim.opt.scrolloff = 8
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
```

### `lua/config/keymaps.lua`
```lua
-- Loaded on VeryLazy event
local map = vim.keymap.set

map("n", "<leader>x", "<cmd>bd<cr>", { desc = "Close buffer" })
map("i", "jk", "<Esc>", { desc = "Escape insert mode" })
```

### `lua/config/autocmds.lua`
```lua
-- Loaded on VeryLazy event
vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

-- Remove a LazyVim default augroup:
-- vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
```

---

## Common Gotchas & Troubleshooting

| Problem | Fix |
|---|---|
| Plugin not loading | Check `:Lazy` for errors; verify spec is in `lua/plugins/` |
| Keymap conflict | Use `:map <key>` to see what's bound; disable with `{ "key", false }` |
| LSP not starting | `:LspInfo` / `:LspLog`; check mason installed the server |
| Formatter not running | `:ConformInfo`; ensure executable is on `$PATH` |
| Linter errors silent | `:lua require("lint").try_lint()` manually; check `nvim-lint` config |
| Options not applied | Make sure `options.lua` doesn't use `vim.o` for list-type opts — use `vim.opt` |
| Extra not loading | Run `:LazyExtras` and toggle; or verify import path in `lazy.lua` |
| Treesitter broken | `:TSUpdate`; `:TSInstall <lang>` |
| Mason tool missing | `:Mason` → search and install; or add to `ensure_installed` |
| Augroup duplicates | Use `clear = true` in `nvim_create_augroup`; for LazyVim groups use `nvim_del_augroup_by_name("lazyvim_*")` |

---

## Quality Checklist

- [ ] Plugin specs live under `lua/plugins/` — never `require()`d manually.
- [ ] `opts` tables are merged safely (use `vim.tbl_deep_extend("force", ...)` when overriding nested tables inside `opts` functions).
- [ ] Keymaps include `desc` for which-key discoverability.
- [ ] `lua/config/options.lua` sets options before plugins load.
- [ ] Mason `ensure_installed` lists all required tools.
- [ ] Extras are imported **before** user plugin specs in `lazy.lua`.
- [ ] LSP servers that need special setup return `true` from `setup[name]`.
- [ ] Autocmds use named augroups with `clear = true`.
- [ ] `colorscheme` fallback is set in `install.colorscheme` to avoid startup errors.

---

## Key References

- LazyVim docs: https://www.lazyvim.org
- Configuration: https://www.lazyvim.org/configuration
- Plugins: https://www.lazyvim.org/plugins
- Extras: https://www.lazyvim.org/extras
- lazy.nvim spec: https://github.com/folke/lazy.nvim
- Snacks.nvim: https://github.com/folke/snacks.nvim
- Mason: https://github.com/mason-org/mason.nvim
- conform.nvim: https://github.com/stevearc/conform.nvim
- nvim-lint: https://github.com/mfussenegger/nvim-lint
