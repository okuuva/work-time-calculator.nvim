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

return M
