-- main module file
local config = require("work-time-calculator.config")
local time_table = require("work-time-calculator.time-table")

---@class WorkTimeCalculator
local M = {}

---@type wtc.Config
M.config = config

---@param args wtc.Config?
-- you can define your setup function here. Usually configurations can be merged, accepting outside params and
-- you can also put some validation here for those.
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

M.calculate_time = function()
  time_table.generate_hours_table(M.config)
  vim.cmd("edit! " .. M.config.output_file)
end

return M
