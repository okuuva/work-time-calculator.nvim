---@class wtc.Config
---@field daily_notes_dir string? Path to the daily notes directory
---@field output_file string? Path to the output file
---@field workday_length string Expected workday length in HH:MM format
local default_config = {
  -- FIXME: fetch these paths with obsidian.nvim
  daily_notes_dir = nil,
  output_file = nil,
  workday_length = "07:30",
}

return default_config
