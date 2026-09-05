-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Java: sync buffer indent options from the Eclipse formatter XML on jdtls attach.
--
-- jdtls intentionally lets the LSP client's tabSize/insertSpaces override the
-- XML's tabulation.char/tabulation.size (eclipse.jdt.ls#1207). Neovim derives
-- tabSize from shiftwidth/tabstop and insertSpaces from expandtab when building
-- the format request (util.make_formatting_params). By reading the XML values
-- and applying them to the buffer here, every subsequent format call – whether
-- triggered by LazyVim, conform, or vim.lsp.buf.format – automatically carries
-- the correct indentation, making the formatter XML the single source of truth.
do
  local _cache = {}

  local function eclipse_indent(xml_path)
    if _cache[xml_path] ~= nil then return _cache[xml_path] end
    local result = { tab_size = 4, expand_tab = true }
    if xml_path ~= "" then
      local f = io.open(xml_path, "r")
      if f then
        local content = f:read("*all")
        f:close()
        local char =
          content:match('id="org%.eclipse%.jdt%.core%.formatter%.tabulation%.char"%s+value="([^"]+)"')
        local size =
          content:match('id="org%.eclipse%.jdt%.core%.formatter%.tabulation%.size"%s+value="([^"]+)"')
        if char then result.expand_tab = char ~= "tab" end
        if size then result.tab_size = tonumber(size) or result.tab_size end
      end
    end
    _cache[xml_path] = result
    return result
  end

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("java_indent_from_eclipse_xml", { clear = true }),
    pattern = "*.java",
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client or client.name ~= "jdtls" then return end
      local url = vim.tbl_get(client.config, "settings", "java", "format", "settings", "url") or ""
      local indent = eclipse_indent(url:gsub("^file://", ""))
      vim.bo[args.buf].expandtab = indent.expand_tab
      vim.bo[args.buf].tabstop = indent.tab_size
      vim.bo[args.buf].shiftwidth = indent.tab_size
      vim.bo[args.buf].softtabstop = indent.tab_size
      -- Disable format-on-save for Java by default; use <leader>uf/<leader>uF to toggle.
      vim.b[args.buf].autoformat = false
    end,
  })
end
