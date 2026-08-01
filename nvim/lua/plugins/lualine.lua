return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    table.insert(opts.sections.lualine_x, 1, {
      function()
        return require("config.claude_notes").statusline()
      end,
      cond = function()
        return require("config.claude_notes").active_count() > 0
      end,
      color = { fg = "#e0af68" },
    })
    return opts
  end,
}
