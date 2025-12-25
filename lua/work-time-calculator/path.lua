---@class wtc.Path
local M = {}

local strptime = require("work-time-calculator.strptime")

---Returns the last n path components of a path
---@private
---@param path string
---@param n integer
---@param sep string? Path separator, defaults to platform-specific separator
function M.last_n_path_components(path, n, sep)
  sep = sep or package.config:sub(1, 1)
  local parts = vim.split(path, sep, { plain = true, trimempty = true })

  local len = #parts
  if n >= len then
    return table.concat(parts, sep)
  end

  -- slice from the end
  local slice = {}
  for i = len - n + 1, len do
    slice[#slice + 1] = parts[i]
  end

  return table.concat(slice, sep)
end

---@private
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
function M.get_daily_notes(config)
  local timestamp = M.get_timestamp_from_current_buffer(config)
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
---@return string
function M.get_output_file_path(config)
  local timestamp = M.get_timestamp_from_current_buffer(config)
  local base_dir = M.get_daily_note_base_dir(config, timestamp)
  local parsed_output_file = os.date(config.output_file, timestamp) --[[@as string]]
  return vim.fs.joinpath(base_dir, parsed_output_file)
end

---Get the timestamp from a file path by matching the date format against the path suffix
---@private
---@param date_format string The date format pattern (may include subdirectories like "%Y/%m/%Y-%m-%d")
---@param filepath string The file path to parse
---@return integer? timestamp The parsed timestamp, or nil if the path doesn't match the format
function M.get_timestamp_from_filepath(date_format, filepath)
  filepath = vim.fs.normalize(filepath)

  -- Remove .md extension
  local path_without_ext = filepath:match("^(.+)%.md$")
  if not path_without_ext then
    return nil
  end

  -- Count how many path components are in the date_format
  -- e.g., "%Y/%m/%Y-%m-%d" has 3 components (split by /)
  local format_depth = 1
  for _ in date_format:gmatch("/") do
    format_depth = format_depth + 1
  end

  local date_string = M.last_n_path_components(path_without_ext, format_depth)

  -- Try to parse using the date_format
  local parsed_ts = strptime.parse(date_string, date_format)
  if not parsed_ts then
    return nil
  end

  -- Convert to os.time format (noon) for consistency with Lua's os.time({ year, month, day })
  local date_table = os.date("*t", parsed_ts) --[[@as table]]
  return os.time({ year = date_table.year, month = date_table.month, day = date_table.day })
end

---Get the timestamp from the current buffer if it's a daily note, or nil otherwise
---@private
---@param config wtc.Config
---@return integer? timestamp The parsed timestamp, or nil if the buffer is not a daily note
function M.get_timestamp_from_current_buffer(config)
  local bufpath = vim.api.nvim_buf_get_name(0)
  return M.get_timestamp_from_filepath(config.date_format, bufpath)
end

return M
