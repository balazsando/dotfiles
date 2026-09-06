---
name: neovim-lua
description: "Writing and debugging Neovim Lua config and plugins: the vim.* stdlib, keymaps, autocmds, options, LSP, and module patterns."
argument-hint: "Describe the Neovim config task (e.g., 'add custom keymap', 'configure LSP', 'write plugin module')"
---

# Neovim Lua Scripting Skill

## Core Namespaces Cheatsheet

| Namespace | Purpose |
|---|---|
| `vim.api.*` | Low-level Nvim API (buffers, windows, marks, extmarks) |
| `vim.fn.*` | Call Vimscript functions |
| `vim.cmd(...)` | Execute Ex commands |
| `vim.keymap.set/del` | Define/remove keymaps |
| `vim.opt` / `vim.o` / `vim.bo` / `vim.wo` | Set editor options |
| `vim.g` / `vim.b` / `vim.w` / `vim.t` | Variable scopes |
| `vim.lsp.*` | LSP client utilities |
| `vim.fs.*` | Filesystem utilities |
| `vim.uv` | libuv async I/O (timers, fs events, TCP) |
| `vim.iter(...)` | Functional iterators (map, filter, fold, …) |
| `vim.system(...)` | Run external commands |
| `vim.notify(...)` | User notifications |
| `vim.schedule(fn)` | Defer fn to main loop (needed in async callbacks) |

---

## Step-by-Step Workflow

### 1. Understand the task type
- **Configuration**: options, keymaps, autocmds, colorscheme — lives in `init.lua` or `lua/config/`.
- **Plugin spec**: lazy.nvim, packer — lives in `lua/plugins/`.
- **Utility module**: reusable functions — lives in `lua/` under a named module.
- **LSP setup**: server config, on_attach, capabilities — lives in `lua/config/` or `lua/core/lsp.lua`.

### 2. Choose the right API layer

**Options**
```lua
-- Global option (like :set)
vim.o.number = true

-- Buffer-local (like :setlocal)
vim.bo.expandtab = true

-- Window-local
vim.wo.wrap = false

-- Use vim.opt for list/map-style options
vim.opt.wildignore:append({ "*.pyc", "node_modules" })
```

**Keymaps**
```lua
-- Basic mapping
vim.keymap.set('n', '<leader>ff', require('telescope.builtin').find_files, {
  desc = 'Find files',
  noremap = true,
  silent = true,
})

-- Buffer-local mapping (e.g., inside on_attach)
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr, desc = 'Go to definition' })

-- Remove a mapping
vim.keymap.del('n', '<leader>ff')
```

**Autocmds**
```lua
local group = vim.api.nvim_create_augroup('MyGroup', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = 'lua',
  callback = function(ev)
    vim.bo[ev.buf].shiftwidth = 2
  end,
})
```

**User commands**
```lua
vim.api.nvim_create_user_command('Format', function(opts)
  vim.lsp.buf.format({ async = true })
end, { desc = 'Format buffer with LSP' })
```

### 3. Module structure
```lua
-- lua/mymod/init.lua
local M = {}

function M.setup(opts)
  opts = vim.tbl_deep_extend('force', M.defaults, opts or {})
  -- ...
end

M.defaults = { timeout = 500 }

return M
```
Load with `require('mymod').setup({ timeout = 1000 })`.

### 4. Async patterns

**Timers** — use `vim.defer_fn` for one-shot; `vim.uv.new_timer` for repeating:
```lua
vim.defer_fn(function()
  vim.notify('done!')
end, 500)
```

**Async callbacks must use `vim.schedule`** to call most `vim.api.*` functions:
```lua
vim.uv.new_timer():start(1000, 0, vim.schedule_wrap(function()
  vim.api.nvim_command('checktime')
end))
```

**External commands**
```lua
-- Async
vim.system({ 'git', 'status' }, { text = true }, function(result)
  vim.schedule(function()
    vim.notify(result.stdout)
  end)
end)

-- Sync (blocks)
local result = vim.system({ 'git', 'rev-parse', 'HEAD' }, { text = true }):wait()
print(result.stdout)
```

### 5. Error handling

**Expected failures** — return `nil, errmsg`:
```lua
local function read_file(path)
  local f, err = io.open(path, 'r')
  if not f then return nil, err end
  local content = f:read('*a')
  f:close()
  return content
end
```

**Unexpected failures** — use `error()` / `assert()` / `pcall()`:
```lua
local ok, err = pcall(require, 'some-plugin')
if not ok then vim.notify('Failed: ' .. err, vim.log.levels.WARN) end
```

### 6. Debugging

- `:lua =expr` — print/inspect any Lua expression in command mode.
- `vim.print(val)` — pretty-print any value (uses `vim.inspect` internally).
- `:Inspect` — show treesitter/syntax/LSP highlight groups under cursor.
- `vim.inspect(val)` — convert to readable string for logging.
- Check `:messages` or `vim.notify` for runtime output.

---

## Common Patterns

### LSP on_attach
```lua
local on_attach = function(client, bufnr)
  local map = function(keys, func, desc)
    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
  end
  map('gd', vim.lsp.buf.definition, 'Go to definition')
  map('K',  vim.lsp.buf.hover,      'Hover docs')
  map('<leader>rn', vim.lsp.buf.rename, 'Rename')
  map('<leader>ca', vim.lsp.buf.code_action, 'Code action')
end
```

### Highlight on yank
```lua
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.hl.on_yank({ higroup = 'IncSearch', timeout = 150 })
  end,
})
```

### Finding project root
```lua
local root = vim.fs.root(0, { '.git', 'Makefile', 'package.json' })
```

### Iterators
```lua
-- Collect loaded LSP client names
local names = vim.iter(vim.lsp.get_clients()):map(function(c) return c.name end):totable()
```

---

## Quality Checklist

Before finishing any Lua Neovim code:

- [ ] Options use the correct scope (`vim.o`, `vim.bo`, `vim.wo`, `vim.opt`).
- [ ] Keymaps include `desc` for discoverability (`:map`, which-key, etc.).
- [ ] Autocmds use a named `augroup` with `clear = true` to avoid duplicates.
- [ ] Async callbacks that call `vim.api.*` are wrapped in `vim.schedule`.
- [ ] Modules return a table (`return M`) and are not side-effect-only.
- [ ] `require()` calls are guarded with `pcall` when the plugin may be absent.
- [ ] No global state pollution — use `local` for all module-level variables.
- [ ] Error paths return `nil, message` or use `vim.notify` with a level.

---

## Key References

- Full API: `:help vim.api`
- Options: `:help vim.opt`
- Keymaps: `:help vim.keymap.set()`
- Autocmds: `:help nvim_create_autocmd()`
- Iterator: `:help vim.iter`
- Async/uv: `:help vim.uv`
- Online: https://neovim.io/doc/user/lua/
