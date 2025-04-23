-- main module file
local config = require("work-time-calculator.config")
local time_table = require("work-time-calculator.time-table")

---@class WorkTimeCalculator
local M = {}

---@type wtc.Config
M.config = config

---@param args wtc.Config?
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

M.calculate_time = function()
  time_table.generate_hours_table(M.config)
  vim.cmd("edit! " .. M.config.output_file) -- open the output file
  vim.cmd("normal Gi") -- go to insert mode on the last line so markdown-table-mode can reformat the table
end

return M
