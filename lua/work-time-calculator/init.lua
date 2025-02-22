-- main module file
local table_generator = require("work-time-calculator.table-generator")

---@class Config
---@field opt string Your config option
local config = {
  opt = "Hello!",
}

---@class MyModule
local M = {}

---@type Config
M.config = config

---@param args Config?
-- you can define your setup function here. Usually configurations can be merged, accepting outside params and
-- you can also put some validation here for those.
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

-- TODO: refresh open buffer if it's the hour list buffer
-- TODO: actually trigger the time calculator
M.calculate_time = function()
  table_generator.generate_hours_table()
end

return M
