-- IDE-ish UX enhancements on top of LazyVim defaults.
-- inlay_hints are already enabled by LazyVim; these add the rest.
return {
  -- Blink.cmp: enable signature-help popup (shows param types as you type)
  -- and surface docs faster.
  {
    "saghen/blink.cmp",
    opts = {
      signature = { enabled = true },
      completion = {
        documentation = {
          auto_show_delay_ms = 100,
        },
      },
    },
  },
}
