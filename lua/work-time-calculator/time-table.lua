---@class wtc.TimeTable
local M = {}
local parsers = require("work-time-calculator.parsers")

---@class DayEntry
---@field date string
---@field timestamp Timestamp
---@field weekday string
---@field day_type string
---@field times table<string>
---@field total_hours integer
---@field target_hours integer
---@field hours_diff integer
---@field carryover integer?
local DayEntry = {}

---@class DayInfo
---@field timestamp Timestamp
---@field workday_length string
---@field day_type string
---@field times table<string>
---@field carryover string?
local DayInfo = {}

---@param info DayInfo
---@return DayEntry
function DayEntry.from_timestamp(info)
  local timestamp, workday_length, day_type, times, carryover = unpack(info)
  local weekday = parsers.get_weekday(timestamp)
  local target_hours = parsers.time_to_minutes(workday_length)
  if carryover then
    carryover = parsers.time_to_minutes(carryover)
  end
  if weekday == "Sat" or weekday == "Sun" then
    day_type = "Weekend"
  end
  if day_type == "Holiday" or day_type == "Weekend" then
    target_hours = 0
  end

  local total_hours = parsers.get_total_time(times)
  local hours_diff = total_hours - target_hours
  if day_type ~= "Work day" then
    if total_hours > 0 then
      day_type = day_type .. "*"
      hours_diff = total_hours
    else
      hours_diff = 0
    end
    total_hours = target_hours
  end

  ---@type DayEntry
  return {
    timestamp = timestamp,
    date = parsers.get_date(timestamp),
    weekday = weekday,
    day_type = day_type,
    times = times,
    target_hours = target_hours,
    total_hours = total_hours,
    hours_diff = hours_diff,
    carryover = carryover,
  }
end

---@param filepath string
---@param workday_length string
---@return DayEntry, string?
function DayEntry.new(filepath, workday_length)
  local times, day_type, carryover, err = parsers.extract_times_from_file(filepath)
  if err then
    return {}, err
  end

  local filename = vim.fn.fnamemodify(filepath, ":t:r")
  local timestamp = parsers.get_timestamp(filename)
  if timestamp == nil then
    return {}, "Could not parse date"
  end

  return DayEntry.from_timestamp({
    timestamp,
    workday_length,
    day_type,
    times,
    carryover,
  }), nil
end

---@alias TimeTable table<number, DayEntry>

---@return TimeTable
---@param config wtc.Config
local function TimeTable(config)
  ---@type TimeTable
  local time_table = {}
  local daily_notes = vim.fn.glob(config.daily_notes_dir .. "/*.md", true, true)

  for _, filepath in ipairs(daily_notes) do
    local today, err = DayEntry.new(filepath, config.workday_length)
    if err ~= nil then
      vim.notify("Error processing " .. filepath .. ": " .. err, vim.log.levels.ERROR)
      goto continue
    end

    local yesterday = time_table[#time_table]
    if yesterday == nil then
      time_table[#time_table + 1] = today
      goto continue
    end

    local missing_timestamp = parsers.next_day(yesterday.timestamp)
    while missing_timestamp < today.timestamp do
      -- add missing days
      time_table[#time_table + 1] = DayEntry.from_timestamp({
        missing_timestamp,
        config.workday_length,
        "Work day",
        {},
      })
      missing_timestamp = parsers.next_day(missing_timestamp)
    end
    time_table[#time_table + 1] = today
    ::continue::
  end
  -- log error if table is empty and drop the last entry if its total hours is 0
  local last_entry = table.remove(time_table, #time_table)
  if last_entry == nil then
    vim.notify("No daily notes found", vim.log.levels.ERROR)
  elseif last_entry.total_hours ~= 0 then
    time_table[#time_table + 1] = last_entry
  end
  return time_table
end

---@param time_table TimeTable
---@return integer
local function most_entries(time_table)
  local max = 0
  for _, entry in ipairs(time_table) do
    if #entry.times > max then
      max = #entry.times
    end
  end
  return max
end

local function padRow(row, times_count, most_records)
  -- Pad with empty cells if needed, ensure always right number of columns
  local num_time_pairs = math.floor(times_count / 2)
  local max_pairs = math.floor(most_records / 2)
  for i = num_time_pairs * 2 + 1, max_pairs * 2 do
    row = row .. "|    "
  end
  return row
end

---@param time_table TimeTable
---@return integer, integer
local function count_special_days(time_table)
  local vacation_days = 0
  local sick_days = 0
  for _, entry in ipairs(time_table) do
    -- Check for Vacation or Vacation* (worked on vacation)
    if string.find(entry.day_type, "^Vacation") then
      vacation_days = vacation_days + 1
    end
    -- Check for Sick day or Sick day* (worked on sick day)
    if string.find(entry.day_type, "^Sick day") then
      sick_days = sick_days + 1
    end
  end
  return vacation_days, sick_days
end

---@param time_table TimeTable
---@return string
local function generate_markdown_table(time_table)
  local table_header = ""
  local most_records = most_entries(time_table)
  table_header = table_header .. "| Date | Day | Type "
  table_header = table_header .. string.rep("| In | Out ", most_records / 2)
  table_header = table_header .. "| Total | Goal | Diff |\n"
  table_header = table_header .. "| ---- | --- | ---- "
  table_header = table_header .. string.rep("| -- | --- ", most_records / 2)
  table_header = table_header .. "| ----- | ---- | ---- |\n"

  local total_row = ""
  total_row = total_row .. "| Total |       |       "
  total_row = total_row .. string.rep("|      |      ", most_records / 2)

  local table_rows = {}

  local total, total_target, total_diff = 0, 0, 0
  for _, entry in ipairs(time_table) do
    if entry.carryover then
      total = total + entry.carryover
      total_diff = total_diff + entry.carryover
      local row = "| Carryover |       |       "
      row = padRow(row, 0, most_records)
      row = row .. string.format("| %s | %s | %s |\n", parsers.minutes_to_time(entry.carryover, 0, entry.carryover))
      table_rows[#table_rows + 1] = row
    end
    total = total + entry.total_hours
    total_target = total_target + entry.target_hours
    total_diff = total_diff + entry.hours_diff
    local row = string.format("| %s | %s | %s ", entry.date, entry.weekday, entry.day_type)

    -- Add time entries, only if they exist
    for i = 1, math.floor(#entry.times / 2) do -- Iterate up to the number of pairs
      row = row .. string.format("| %s | %s ", entry.times[2 * i - 1], entry.times[2 * i])
    end

    row = padRow(row, #entry.times, most_records)

    row = row
      .. string.format(
        "| %s | %s | %s |\n",
        parsers.minutes_to_time(entry.total_hours, entry.target_hours, entry.hours_diff)
      )
    table_rows[#table_rows + 1] = row
  end

  total_row = total_row .. string.format("| %s | %s | %s |\n", parsers.minutes_to_time(total, total_target, total_diff))

  return table_header .. table.concat(table_rows, "") .. total_row
end

M.generate_markdown_table = generate_markdown_table

---@param config wtc.Config
local function generate_hours_table(config)
  local time_table = TimeTable(config)

  local markdown_table = generate_markdown_table(time_table)
  local vacation_days, sick_days = count_special_days(time_table)
  local existing_header = parsers.read_existing_header(config.output_file)
  local output_content = ""

  if existing_header then
    output_content = existing_header
  end

  output_content = output_content .. "# Hours\n\n" .. markdown_table
  output_content = output_content .. "\n"
  output_content = output_content .. "**Vacation days:** " .. vacation_days .. "\n"
  output_content = output_content .. "**Sick leave days:** " .. sick_days .. "\n"

  local f = io.open(config.output_file, "w")
  if not f then
    vim.notify("Could not open output file: " .. config.output_file, vim.log.levels.ERROR)
    return
  end
  f:write(output_content)
  f:close()

  vim.notify("Hours table generated at " .. config.output_file, vim.log.levels.INFO)
end

M.generate_hours_table = generate_hours_table

return M
