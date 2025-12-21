---@class wtc.Path
local M = {}

local strptime = require("work-time-calculator.strptime")

---@param config wtc.Config
---@param timestamp Timestamp?
---@return string
function M.get_daily_note_base_dir(config, timestamp)
  local date_str = os.date(config.date_format, timestamp) --[[@as string]]
  local notes_dir = config.daily_notes_dir or ""
  local path = vim.fs.joinpath(notes_dir, date_str)
  return vim.fs.dirname(path)
end

---Returns all daily note files in the base directory that match the date pattern
---@param config wtc.Config
---@return string[]
function M.get_daily_notes(config, timestamp)
  local base_dir = M.get_daily_note_base_dir(config, timestamp)
  local filename_format = vim.fs.basename(config.date_format)

  return vim.fs.find(function(name)
    local basename = name:match("^(.+)%.md$")
    if not basename then
      return false
    end
    return strptime.matches(basename, filename_format)
  end, {
    path = base_dir,
    type = "file",
    limit = math.huge,
  })
end

---Returns the full path to the output file (output_file joined with daily note base dir)
---@param config wtc.Config
---@param timestamp Timestamp?
---@return string
function M.get_output_file_path(config, timestamp)
  local base_dir = M.get_daily_note_base_dir(config, timestamp)
  local parsed_output_file = os.date(config.output_file, timestamp) --[[@as string]]
  return vim.fs.joinpath(base_dir, parsed_output_file)
end

---Get the timestamp from a file path if it's a daily note, or nil otherwise
---Checks that the path is within the daily_notes_dir and matches the date_format
---@param config wtc.Config
---@param filepath string The file path to check
---@return integer? timestamp The parsed timestamp, or nil if the path is not a daily note
function M.get_timestamp_from_filepath(config, filepath)
  local daily_notes_dir = config.daily_notes_dir
  if not daily_notes_dir then
    return nil
  end

  -- Normalize paths (ensure trailing slash for directory comparison)
  daily_notes_dir = vim.fs.normalize(daily_notes_dir)
  filepath = vim.fs.normalize(filepath)

  -- Check if filepath is within the daily_notes_dir
  if not vim.startswith(filepath, daily_notes_dir .. "/") then
    return nil
  end

  -- Get the relative path from daily_notes_dir (without the .md extension)
  local relative_path = filepath:sub(#daily_notes_dir + 2) -- +2 to skip the trailing slash
  local relative_path_without_ext = relative_path:match("^(.+)%.md$")
  if not relative_path_without_ext then
    return nil
  end

  -- Try to parse using the full date_format (which may include subdirectories)
  local parsed_ts = strptime.parse(relative_path_without_ext, config.date_format)
  if not parsed_ts then
    return nil
  end

  -- Convert to os.time format (noon) for consistency with Lua's os.time({ year, month, day })
  local date_table = os.date("*t", parsed_ts) --[[@as table]]
  return os.time({ year = date_table.year, month = date_table.month, day = date_table.day })
end

---Get the timestamp from the current buffer if it's a daily note, or nil otherwise
---@param config wtc.Config
---@return integer? timestamp The parsed timestamp, or nil if the buffer is not a daily note
function M.get_timestamp_from_current_buffer(config)
  local bufpath = vim.api.nvim_buf_get_name(0)
  return M.get_timestamp_from_filepath(config, bufpath)
end

return M
