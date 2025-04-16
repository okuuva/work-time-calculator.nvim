-- main module file
local table_generator = require("work-time-calculator.table-generator")
local time_calculator = require("time-calculator")

---@class WorkTimeCalculatorConfig
---@field opt string Your config option
---@field output_file string Path to the output file
---@field workday_length string Expected workday length in HH:MM format
local config = {
  -- FIXME: fetch these paths with obsidian.nvim
  daily_notes_dir = vim.fn.expand("~/Notes/notes/dailies"),
  output_file = vim.fn.expand("~/Notes/notes/1740225022-hours.md"),
  workday_length = "06:00",
}

---@class MyModule
local M = {}

---@type WorkTimeCalculatorConfig
M.config = config

---@param args WorkTimeCalculatorConfig?
-- you can define your setup function here. Usually configurations can be merged, accepting outside params and
-- you can also put some validation here for those.
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

M.calculate_time = function()
  table_generator.generate_hours_table(M.config)
  vim.cmd("edit! " .. M.config.output_file)
  time_calculator.calculate_time()

  -- Reload the buffer
  vim.cmd("e! " .. M.config.output_file)
end

return M
