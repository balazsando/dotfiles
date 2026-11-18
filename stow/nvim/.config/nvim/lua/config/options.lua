-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- LazyVim default (ai_cmp = true) disables Copilot inline ghost text and
-- routes suggestions through the blink.cmp dropdown instead. Setting false
-- restores the classic "ghost text appears as you type" experience: Copilot
-- auto-triggers inline suggestions and Tab accepts them.
vim.g.ai_cmp = false

vim.opt.scrolloff = 8 -- keep more lines visible when scrolling near edges

vim.opt.clipboard = "unnamedplus"

local osc52 = require("vim.ui.clipboard.osc52")
local function local_paste()
	return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
end
vim.g.clipboard = {
	name = "osc52-copy-local-paste",
	copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
	paste = { ["+"] = local_paste, ["*"] = local_paste },
}
