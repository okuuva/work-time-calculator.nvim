-- main module file
local config = require("work-time-calculator.config")
local time_table = require("work-time-calculator.time-table")
local path = require("work-time-calculator.path")
local mtm = require("markdown-table-mode")

---@class WorkTimeCalculator
local M = {}

---@type wtc.Config
M.config = config

---@param args wtc.Config?
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

M.calculate_time = function()
  local output_file_path = path.get_output_file_path(M.config)
  time_table.generate_hours_table(M.config)
  vim.cmd("edit! " .. output_file_path) -- open the output file
  vim.cmd("keepjumps normal! G3k") -- go to the last line of the table so markdown-table-mode can reformat it
  if mtm ~= nil then
    mtm.format_markdown_table()
  end
end

return M
