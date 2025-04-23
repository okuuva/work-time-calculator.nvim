---@class wtc.Config
---@field daily_notes_dir string Path to the daily notes directory
---@field output_file string Path to the output file
---@field workday_length string Expected workday length in HH:MM format
local default_config = {
  -- FIXME: fetch these paths with obsidian.nvim
  daily_notes_dir = vim.fn.expand("~/Notes/notes/dailies"),
  output_file = vim.fn.expand("~/Notes/notes/1740225022-hours.md"),
  workday_length = "06:00",
}

return default_config
