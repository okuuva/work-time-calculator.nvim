---@class wtc.Strptime
local M = {}

---Parse a date string using an strftime format pattern
---Uses Vim's built-in strptime function.
---@param str string The string to parse
---@param format string The strftime format pattern
---@return integer|nil timestamp The parsed timestamp, or nil if parsing failed
function M.parse(str, format)
  if str == "" then
    return nil
  end
  local timestamp = vim.fn.strptime(format, str)
  if timestamp == 0 and not str:find("1970") then
    return nil
  end
  -- vim.fn.strptime allows partial matches (e.g., "2024-06-15-extra" matches "%Y-%m-%d")
  -- We require an exact match, so verify by formatting back and comparing
  local formatted = os.date(format, timestamp)
  if formatted ~= str then
    return nil
  end
  return timestamp
end

---Check if a string matches an strftime format pattern
---@param str string The string to check
---@param format string The strftime format pattern
---@return boolean
function M.matches(str, format)
  return M.parse(str, format) ~= nil
end

return M
