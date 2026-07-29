return {
  "tpope/vim-obsession",
  lazy = false,
  config = function()
    -- Auto-track a session (Session.vim in cwd) whenever nvim is opened with
    -- no file arguments, matching how tmux-resurrect relaunches it (bare
    -- `nvim`) so the pane's buffers actually come back on restore instead of
    -- the home screen. Skips one-off `nvim somefile.py` edits on purpose.
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = function()
        if vim.fn.argc() == 0 then
          vim.cmd("silent! Obsession")
        end
      end,
    })
  end,
}
