# LazyVim — bootstrap, extras, and UI

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
