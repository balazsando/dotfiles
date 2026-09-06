# LazyVim — LSP, formatters, linters, Treesitter

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
