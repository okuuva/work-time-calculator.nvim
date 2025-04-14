-- main module file
local table_generator = require("work-time-calculator.table-generator")

---@class WorkTimeCalculatorConfig
---@field daily_notes_dir string
---@field output_file string
local config = {
  -- FIXME: fetch these paths with obsidian.nvim
  daily_notes_dir = vim.fn.expand("~/Notes/notes/dailies"),
  output_file = vim.fn.expand("~/Notes/notes/1740225022-hours.md"),
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

-- TODO: refresh open buffer if it's the hour list buffer
-- TODO: actually trigger the time calculator
M.calculate_time = function()
  table_generator.generate_hours_table(M.config)
end

return M
