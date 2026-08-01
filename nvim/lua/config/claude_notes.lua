-- Scan markdown notes for inline %%...%% markers on save and resolve them
-- with a headless Claude Code run. Opt-in per project: only runs under a
-- directory tree that has a .claude-notes.json file (walked upward from the
-- saved file). Presence of the file is enough; contents are optional.

local M = {}

local MARKER_FILE_NAMES = { ".claude-notes.json" }
local MARKER_PATTERN = "%%%%.-%%%%" -- matches %%...%% (non-greedy, spans lines)

-- Tracks in-flight jobs by absolute file path so a rapid string of saves
-- doesn't spawn overlapping Claude runs on the same file.
local running = {}
local running_count = 0

local SPINNER_FRAMES = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local spinner_index = 1
local spinner_timer = nil

local function start_job(abs_path)
  running[abs_path] = true
  running_count = running_count + 1
  if not spinner_timer then
    spinner_timer = vim.uv.new_timer()
    spinner_timer:start(
      0,
      80,
      vim.schedule_wrap(function()
        spinner_index = (spinner_index % #SPINNER_FRAMES) + 1
        vim.cmd("redrawstatus")
      end)
    )
  end
end

local function finish_job(abs_path)
  running[abs_path] = nil
  running_count = running_count - 1
  if running_count <= 0 and spinner_timer then
    spinner_timer:stop()
    spinner_timer:close()
    spinner_timer = nil
    vim.schedule(function()
      vim.cmd("redrawstatus")
    end)
  end
end

-- Number of claude-notes jobs currently running. Used by the lualine
-- component to decide whether to render at all.
function M.active_count()
  return running_count
end

-- Statusline text for the current spinner frame. Empty string when idle.
function M.statusline()
  if running_count == 0 then
    return ""
  end
  local suffix = running_count > 1 and (" x" .. running_count) or ""
  return SPINNER_FRAMES[spinner_index] .. " Claude" .. suffix
end

local function count_changed_lines(before_lines, after_lines)
  local before = table.concat(before_lines, "\n") .. "\n"
  local after = table.concat(after_lines, "\n") .. "\n"
  local hunks = vim.diff(before, after, { result_type = "indices" })
  local total = 0
  for _, hunk in ipairs(hunks) do
    local _, count_a, _, count_b = hunk[1], hunk[2], hunk[3], hunk[4]
    total = total + math.max(count_a, count_b)
  end
  return total
end

-- Finds the nearest .claude-notes.json walking upward from start_path, then
-- resolves the "root" directory Claude should be pointed at: the config's
-- own directory by default, or config.root (relative to that directory) if
-- set, e.g. {"root": ".."} when the config lives in a notes/ subfolder but
-- Claude should see the whole project.
local function find_project_root(start_path)
  local config_path = vim.fs.find(MARKER_FILE_NAMES, {
    upward = true,
    path = vim.fs.dirname(start_path),
    stop = vim.uv.os_homedir(),
  })[1]
  if not config_path then
    return nil
  end
  local config_dir = vim.fs.dirname(config_path)

  local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(config_path), "\n"))
  local root_override = ok and type(decoded) == "table" and decoded.root or nil
  if not root_override then
    return config_dir
  end

  local resolved = vim.fs.abspath(vim.fs.joinpath(config_dir, root_override))
  if vim.fn.isdirectory(resolved) == 0 then
    vim.notify(
      "claude-notes: root '" .. root_override .. "' in " .. config_path .. " does not exist",
      vim.log.levels.ERROR
    )
    return nil
  end
  return vim.fs.normalize(resolved)
end

local function build_prompt(rel_path)
  return table.concat({
    "Scan the markdown file '" .. rel_path .. "' for inline task markers",
    "delimited by double percent signs, like %%this%%.",
    "",
    "For each %%...%% marker found:",
    "- If it's a question, research prompt, or lookup request, find the",
    "  answer and replace the marker (including the %% delimiters) with the",
    "  answer, written inline in the surrounding text's voice and format.",
    "- If it's a conjecture or claim, evaluate it and replace the marker",
    "  with a brief assessment.",
    "- If it asks you to write or draft something, write it and replace",
    "  the marker with that content.",
    "- Keep replacements concise and formatted appropriately for a",
    "  personal notes file. No meta-commentary like 'Here is the answer:'.",
    "- If a marker is ambiguous or unanswerable, replace it with",
    "  '[claude: could not resolve, <short reason>]' so it stands out.",
    "- Do not modify any other part of the file.",
    "",
    "Use the Edit tool to apply changes directly. Do not ask for",
    "confirmation and do not explain what you did afterward.",
  }, "\n")
end

local function reload_if_current(abs_path)
  local buf = vim.fn.bufnr(abs_path)
  if buf == -1 then
    return
  end
  vim.schedule(function()
    if vim.api.nvim_buf_is_loaded(buf) then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd("checktime")
      end)
    end
  end)
end

function M.scan(abs_path)
  if running[abs_path] then
    return
  end

  local root = find_project_root(abs_path)
  if not root then
    return
  end

  local before_lines = vim.fn.readfile(abs_path)
  local content = table.concat(before_lines, "\n")
  if not content:find(MARKER_PATTERN) then
    return
  end

  local rel_path = abs_path:sub(#root + 2) -- strip root + "/"
  start_job(abs_path)

  vim.system({
    "claude",
    "-p",
    build_prompt(rel_path),
    "--permission-mode",
    "acceptEdits",
    "--allowedTools",
    "Edit,Read,WebSearch,WebFetch",
    "--model",
    "sonnet",
  }, { cwd = root, text = true }, function(obj)
    finish_job(abs_path)
    vim.schedule(function()
      if obj.code ~= 0 then
        vim.notify(
          "claude-notes: scan failed for " .. rel_path .. "\n" .. (obj.stderr or ""),
          vim.log.levels.ERROR
        )
        return
      end
      reload_if_current(abs_path)
      local after_lines = vim.fn.readfile(abs_path)
      local edited = count_changed_lines(before_lines, after_lines)
      local plural = edited == 1 and "" or "s"
      vim.notify(edited .. " line" .. plural .. " edited by Claude in " .. rel_path, vim.log.levels.INFO)
    end)
  end)
end

function M.setup()
  vim.o.autoread = true

  local group = vim.api.nvim_create_augroup("claude_notes", { clear = true })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*.md",
    callback = function(ev)
      M.scan(vim.fn.fnamemodify(ev.file, ":p"))
    end,
  })

  -- Pick up external edits (from the claude-notes job, or anything else)
  -- without prompting, as long as the buffer has no unsaved changes.
  vim.api.nvim_create_autocmd({ "FocusGained", "CursorHold", "CursorHoldI" }, {
    group = group,
    pattern = "*.md",
    callback = function()
      if vim.fn.mode() ~= "c" then
        vim.cmd("checktime")
      end
    end,
  })
end

return M
