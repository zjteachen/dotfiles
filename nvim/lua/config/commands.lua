-- User commands. Loaded from config/autocmds.lua on the VeryLazy event.

-- :Md <filename>  Insert a markdown link to <filename>.md at the cursor
-- (in the current file's directory) and open that file for editing.
vim.api.nvim_create_user_command("Md", function(opts)
  local name = opts.args
  if not name:match("%.md$") then
    name = name .. ".md"
  end

  local dir = vim.fn.expand("%:p:h")
  if dir == "" then
    vim.notify("Md: current buffer has no file path, can't resolve a folder", vim.log.levels.ERROR)
    return
  end
  local path = dir .. "/" .. name

  local title = name:gsub("%.md$", "")
  local link = string.format("[%s](%s)", title, name)

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { link })
  vim.api.nvim_win_set_cursor(0, { row, col + #link })

  vim.cmd.edit(vim.fn.fnameescape(path))
end, {
  nargs = 1,
  complete = "file",
  desc = "Insert a markdown link to <file>.md and open it",
})
