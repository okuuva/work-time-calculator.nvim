---@class TableGenerator
local M = {}

local function get_weekday_from_date(date_str)
  -- Assuming date format is YYYY-MM-DD
  local year, month, day = date_str:match("(%d+)-(%d+)-(%d+)")
  if not year or not month or not day then
    return ""
  end

  -- Convert to numbers
  year = tonumber(year)
  month = tonumber(month)
  day = tonumber(day)

  -- Create a timestamp for the date
  local timestamp = os.time({ year = year, month = month, day = day })
  local weekday = os.date("%a", timestamp) -- Returns short weekday name (Mon, Tue, etc.)
  return weekday
end

local function extract_times_from_file(filepath)
  local lines = {}
  local f = io.open(filepath, "r")
  if not f then
    return nil, nil, "Could not open file: " .. filepath
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

  local times = {}
  local day_type = "Work day"

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

local function generate_markdown_table(data, workday_length)
  local table_header =
    "| Date       | Day   | Type     | In    | Out   | In    | Out   | In    | Out   | Total | Goal  | Diff  |\n"
  table_header = table_header
    .. "| ---------- | ----- | -------- | ----- | ----- | ----- | ----- | ----- | ----- | ----- | ----- | -----:|\n"

  local table_rows = {}
  local grand_total_row = "| GrandTotal |       |          |"

  for _, entry in ipairs(data) do
    local date = entry.date
    local weekday = get_weekday_from_date(date)
    local times = entry.times
    local day_type = entry.day_type
    local row = string.format("| %s | %s   |", date, weekday)

    -- Change day type based on weekday
    if weekday == "Sat" or weekday == "Sun" then
      day_type = "Weekend"
    end
    row = row .. string.format(" %-8s |", day_type)

    -- Add time entries, only if they exist
    for i = 1, math.floor(#times / 2) do -- Iterate up to the number of pairs
      row = row .. string.format(" %s | %s |", times[2 * i - 1], times[2 * i])
    end

    -- Pad with empty cells if needed
    local num_time_pairs = math.floor(#times / 2)
    for i = 1, 3 - num_time_pairs do
      row = row .. "       |       |"
    end

    -- Add goal and diff
    local goal = workday_length
    if day_type ~= "Work day" then
      goal = "00:00"
    end
    row = row .. string.format("       | %s |       |\n", goal)
    table.insert(table_rows, row)
  end

  grand_total_row = grand_total_row .. "       |       |       |       |       |       |       |       |       |\n"

  return table_header .. table.concat(table_rows, "") .. grand_total_row
end

local function read_existing_header(filepath)
  local lines = {}
  local f = io.open(filepath, "r")
  if not f then
    return nil
  end

  -- Read the first 6 lines
  for i = 1, 6 do
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

local function add_formulas(content)
  return content
    .. "<!-- TBLFM: $10=((($5 - $4) + ($7 - $6)) + ($9 - $8));hm -->\n"
    .. "<!-- TBLFM: @>$10=sum(@I..@-1);hm -->\n"
    .. "<!-- TBLFM: @>$11=sum(@I..@-1);hm -->\n"
    .. "<!-- TBLFM: $12=($10-$11);hm -->\n"
end

---@param config WorkTimeCalculatorConfig
function M.generate_hours_table(config)
  local daily_notes = vim.fn.glob(config.daily_notes_dir .. "/*.md", 1, 1)
  local data = {}

  for _, filepath in ipairs(daily_notes) do
    local times, day_type, err = extract_times_from_file(filepath)
    if err then
      vim.notify("Error processing " .. filepath .. ": " .. err, vim.log.levels.ERROR)
    else
      local filename = vim.fn.fnamemodify(filepath, ":t:r")
      data[#data + 1] = {
        date = filename,
        times = times,
        day_type = day_type,
      }
    end
  end

  local markdown_table = generate_markdown_table(data, config.workday_length)
  local existing_header = read_existing_header(config.output_file)
  local output_content = ""

  if existing_header then
    output_content = existing_header
  end

  output_content = output_content .. "\n# Hours\n\n" .. markdown_table
  output_content = add_formulas(output_content)

  local f = io.open(config.output_file, "w")
  if not f then
    vim.notify("Could not open output file: " .. config.output_file, vim.log.levels.ERROR)
    return
  end
  f:write(output_content)
  f:close()

  vim.notify("Hours table generated at " .. config.output_file, vim.log.levels.INFO)
end

return M
