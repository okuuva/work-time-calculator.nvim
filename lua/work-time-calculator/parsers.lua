---@class WTCalcParsers
local M = {}

---@alias Timestamp integer
---@type Timestamp
local day = 24 * 60 * 60

---@param timestamp Timestamp
---@return Timestamp
local function next_day(timestamp)
  return timestamp + day
end

M.next_day = next_day

---@param date_str string
---@return Timestamp?
local function get_timestamp(date_str)
  -- Assuming date format is YYYY-MM-DD
  local year, month, day = date_str:match("(%d+)-(%d+)-(%d+)")
  if not year or not month or not day then
    return nil
  end

  -- Create a timestamp for the date
  return os.time({ year = year, month = month, day = day })
end

M.get_timestamp = get_timestamp

---@param timestamp Timestamp
---@return string
local function get_date(timestamp)
  return os.date("%Y-%m-%d", timestamp) --[[@as string]]
end

M.get_date = get_date

---@param timestamp Timestamp
---@return string
local function get_weekday(timestamp)
  local weekday = os.date("%a", timestamp) -- Returns short weekday name (Mon, Tue, etc.)
  return weekday --[[@as string]]
end

M.get_weekday = get_weekday

---@param time string (H)HH:MM format
---@return integer
local function time_to_minutes(time)
  local hours, minutes = time:match("(%d+):(%d+)")
  return tonumber(hours) * 60 + tonumber(minutes)
end

M.time_to_minutes = time_to_minutes

---@param ... integer minutes to turn to HH:MM
---@return string ...
local function minutes_to_time(...)
  local results = {}
  local sign = ""
  for _, minutes in ipairs({ ... }) do
    if minutes < 0 then
      minutes = -minutes
      sign = "-"
    end
    local hours = math.floor(minutes / 60)
    local remaining_minutes = minutes % 60
    results[#results + 1] = string.format("%s%02d:%02d", sign, hours, remaining_minutes)
  end
  return unpack(results)
end

M.minutes_to_time = minutes_to_time

---@param times table<string>
---@return integer
local function get_total_time(times)
  if #times % 2 ~= 0 then
    vim.notify("Odd number of times in the schedule", vim.log.levels.ERROR)
    return 0
  end

  local total_minutes = 0
  for i = 1, #times, 2 do
    local start_time = time_to_minutes(times[i])
    local end_time = time_to_minutes(times[i + 1])
    total_minutes = total_minutes + (end_time - start_time)
  end
  return total_minutes
end

M.get_total_time = get_total_time

local function read_existing_header(filepath)
  local lines = {}
  local f = io.open(filepath, "r")
  if not f then
    return nil
  end

  -- Read the first 6 lines
  for _ = 1, 6 do
    local line = f:read()
    if line then
      table.insert(lines, line)
    else
      break -- Stop if the file has fewer than 6 lines
    end
  end
  f:close()

  if #lines > 0 then
    return table.concat(lines, "\n") .. "\n"
  else
    return nil
  end
end

M.read_existing_header = read_existing_header

---@return table<string, string>, string, string?
local function extract_times_from_file(filepath)
  local lines = {}
  local times = {}
  local day_type = "Work day"
  local f = io.open(filepath, "r")
  if not f then
    return times, day_type, "Could not open file: " .. filepath
  end
  for line in f:lines() do
    table.insert(lines, line)
  end
  f:close()

  local schedule_start = nil
  for i, line in ipairs(lines) do
    if string.find(line, "## Schedule") then
      schedule_start = i
      break
    end
  end

  if not schedule_start then
    return times, day_type, nil
  end

  for i = schedule_start + 1, #lines do
    local line = string.lower(lines[i])
    if string.find(line, "## plan:") then
      break
    end
    local time = string.match(line, "%s*(%d%d:%d%d)")
    if time then
      table.insert(times, time)
    end
    if string.find(line, "sick") then
      day_type = "Sick day"
    end
    if string.find(line, "vac") then
      day_type = "Vacation"
    end
    if string.find(line, "holiday") then
      day_type = "Holiday"
    end
  end

  return times, day_type, nil
end

M.extract_times_from_file = extract_times_from_file

return M
