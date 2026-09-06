---
name: lazyvim
description: "Configuring LazyVim: plugin specs, customising or disabling defaults, keymaps, :LazyExtras, LSP/formatters/linters, lua/config files, and troubleshooting."
argument-hint: "Describe the LazyVim task (e.g., 'add a plugin', 'override LSP settings', 'enable Java extra', 'change colorscheme', 'add custom keymap')"
---

# LazyVim Skill

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

## Bootstrap (`lua/config/lazy.lua`)

```lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- import your extras:
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.json" },
    -- your own plugin specs:
    { import = "plugins" },
  },
  defaults = { lazy = false, version = false },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = { enabled = true },
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
    },
  },
})
```

---

## LazyVim Global Options (`lua/plugins/lazyvim.lua`)

```lua
return {
  {
    "LazyVim/LazyVim",
    opts = {
      -- Change colorscheme
      colorscheme = "catppuccin",

      -- Or use a function for full control
      -- colorscheme = function() require("tokyonight").load() end,

      -- Disable default autocmds/keymaps
      defaults = {
        autocmds = true,
        keymaps = true,
      },
    },
  },
}
```

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

## Default Keymaps Quick Reference

| Key | Action |
|---|---|
| `<leader>ff` | Find files (Snacks/Telescope) |
| `<leader>fg` | Live grep |
| `<leader>fb` | Buffers |
| `<leader>fr` | Recent files |
| `<leader>e` | File explorer (neo-tree) |
| `<leader>gg` | Lazygit |
| `<leader>gh*` | Git hunks (gitsigns) |
| `<leader>ca` | Code action |
| `<leader>cr` | Rename symbol |
| `<leader>cl` | LSP info |
| `gd` | Go to definition |
| `gr` | References |
| `gI` | Go to implementation |
| `K` | Hover docs |
| `<C-k>` (insert) | Signature help |
| `]]` / `[[` | Next/prev reference |
| `<leader>cd` | Line diagnostics |
| `<leader>cf` | Format buffer |
| `<leader>qq` | Quit all |
| `<leader>bd` | Delete buffer |

---

## LSP Configuration

### Add/configure LSP servers
```lua
-- lua/plugins/lsp.lua
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {},
        tsserver = {
          settings = {
            typescript = { inlayHints = { includeInlayParameterNameHints = "all" } },
          },
        },
      },
    },
  },
}
```

### Custom setup for a server (skip lspconfig, handle manually)
```lua
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      setup = {
        tsserver = function(_, opts)
          require("typescript").setup({ server = opts })
          return true  -- return true to skip default lspconfig setup
        end,
      },
    },
  },
}
```

### Enable/disable inlay hints globally
```lua
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = true },
      codelens = { enabled = true },
    },
  },
}
```

### Disable Mason auto-install for a server
```lua
opts = {
  servers = {
    rust_analyzer = {
      mason = false,  -- don't install via Mason
    },
  },
}
```

---

## Formatters (conform.nvim)

```lua
-- lua/plugins/formatting.lua
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "isort", "black" },
        javascript = { "prettierd", "prettier", stop_after_first = true },
        ["*"] = { "codespell" },
        ["_"] = { "trim_whitespace" },
      },
    },
  },
}
```

---

## Linters (nvim-lint)

```lua
-- lua/plugins/linting.lua
return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        python = { "flake8" },
        javascript = { "eslint_d" },
        markdown = { "markdownlint" },
      },
    },
  },
}
```

---

## Treesitter

```lua
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash", "lua", "python", "typescript", "java", "go",
        "markdown", "markdown_inline", "json", "yaml",
      },
    },
  },
}
```

---

## Extras

The easiest way to install extras is with `:LazyExtras` (interactive UI).

Alternatively, import them directly in `lua/config/lazy.lua`:

```lua
spec = {
  { "LazyVim/LazyVim", import = "lazyvim.plugins" },
  -- Language extras
  { import = "lazyvim.plugins.extras.lang.typescript" },
  { import = "lazyvim.plugins.extras.lang.java" },
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.go" },
  { import = "lazyvim.plugins.extras.lang.rust" },
  -- Editor extras
  { import = "lazyvim.plugins.extras.editor.aerial" },
  { import = "lazyvim.plugins.extras.editor.harpoon2" },
  -- AI extras
  { import = "lazyvim.plugins.extras.ai.copilot" },
  { import = "lazyvim.plugins.extras.ai.avante" },
  -- Formatting/linting extras
  { import = "lazyvim.plugins.extras.formatting.prettier" },
  { import = "lazyvim.plugins.extras.linting.eslint" },
  -- UI extras
  { import = "lazyvim.plugins.extras.ui.mini-animate" },
  -- Util extras
  { import = "lazyvim.plugins.extras.util.mini-hipatterns" },
}
```

### Java extra — key pattern
```lua
-- Automatically loaded by the Java extra:
-- nvim-jdtls (LSP), nvim-treesitter (java parser),
-- mason (java-debug-adapter, java-test), nvim-dap

-- To override jdtls settings:
return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          inlayHints = { parameterNames = { enabled = "all" } },
        },
      })
      return opts
    end,
  },
}
```

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

## Colorscheme

```lua
-- Switch to catppuccin
return {
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = { flavour = "mocha" },
  },
}
```

---

## Snacks.nvim (built-in utility layer)

LazyVim bundles `folke/snacks.nvim` — a collection of small but powerful utilities:

| Utility | Usage |
|---|---|
| `Snacks.picker.*` | Fuzzy finder (replaces Telescope in recent LazyVim) |
| `Snacks.words.jump(n)` | Jump between LSP references |
| `Snacks.rename.rename_file()` | Rename file with LSP awareness |
| `Snacks.git.blame_line()` | Inline git blame |
| `Snacks.notify(msg, level)` | Notification |
| `Snacks.terminal()` | Floating terminal |
| `Snacks.lazygit()` | Lazygit integration |

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
