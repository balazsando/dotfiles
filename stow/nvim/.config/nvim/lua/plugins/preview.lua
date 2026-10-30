vim.filetype.add({ extension = { mdc = "markdown" } })

local function preview(cmd)
  return function()
    local width = math.floor(vim.o.columns * 0.9)
    Snacks.terminal(
      cmd:format(vim.fn.shellescape(vim.fn.expand("%:p")), width - 4),
      { win = { style = "float", width = width, height = 0.9 } }
    )
  end
end

return {
  { "iamcco/markdown-preview.nvim", enabled = false },
  { "aklt/plantuml-syntax", ft = "plantuml" },
  { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = { "mermaid" } } },
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>cp", preview("mdview %s -p -w %d"), ft = "markdown", desc = "Markdown Preview (glow)" },
      { "<leader>cp", preview("(mermaid-ascii -x 3 -y 2 -f %s 2>/dev/null || echo 'mermaid: diagram type has no text rendering') | less -R"), ft = "mermaid", desc = "Mermaid Preview" },
      { "<leader>cp", preview("pumlview %s | less -S"), ft = "plantuml", desc = "PlantUML Preview" },
    },
  },
}
