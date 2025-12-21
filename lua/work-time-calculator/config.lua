---@class wtc.Config
---@field daily_notes_dir string? Path to the daily notes directory
---@field date_format string Date format used by the daily notes. Supports subdirs, e.g. "%Y/%m/%Y-%m-%d". Defaults to "%Y-%m-%d"
---@field output_file string? Path to the output file
---@field workday_length string Expected workday length in HH:MM format
local default_config = {
  -- FIXME: fetch these paths with obsidian.nvim
  daily_notes_dir = nil,
  date_format = "%Y-%m-%d",
  output_file = nil,
  workday_length = "07:30",
}

return default_config
