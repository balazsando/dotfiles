-- IDE-ish UX enhancements on top of LazyVim defaults.
-- inlay_hints are already enabled by LazyVim; these add the rest.
return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>e",
        function()
          local explorer = Snacks.picker.get({ source = "explorer" })[1]
          if explorer then
            explorer:focus()
          else
            Snacks.explorer({ cwd = LazyVim.root() })
          end
        end,
        desc = "Explorer Snacks (root dir, focus)",
      },
    },
  },
  -- Blink.cmp: enable signature-help popup (shows param types as you type)
  -- and surface docs faster.
  {
    "saghen/blink.cmp",
    opts = {
      signature = { enabled = true },
      keymap = {
        ["<Tab>"] = {
          "select_next",
          function()
            return LazyVim.cmp.map({ "snippet_forward", "ai_nes", "ai_accept" })()
          end,
          "fallback",
        },
        ["<S-Tab>"] = {
          function()
            return LazyVim.cmp.map({ "ai_nes", "ai_accept" })()
          end,
          "snippet_backward",
          "fallback",
        },
      },
      completion = {
        list = { selection = { preselect = false } },
        documentation = {
          auto_show_delay_ms = 100,
        },
      },
    },
  },
}
