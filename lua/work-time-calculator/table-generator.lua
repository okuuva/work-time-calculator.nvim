---@class TableGenerator
local M = {}

local function extract_times_from_file(filepath)
  local lines = {}
  local f = io.open(filepath, "r")
  if not f then
    return nil, "Could not open file: " .. filepath
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
    return nil, "No '## Schedule' found in " .. filepath
  end

  local times = {}
  for i = schedule_start + 1, #lines do
    local line = lines[i]
    if string.find(line, "## Plan:") then
      break
    end
    local time = string.match(line, "%s*(%d%d:%d%d)")
    if time then
      table.insert(times, time)
    end
  end

  return times, nil
end

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

local function generate_markdown_table(data)
  local table_header = "| Date       | Day   | In    | Out   | In    | Out   | In    | Out   | Total |\n"
  table_header = table_header .. "| ---------- | ----- | ----- | ----- | ----- | ----- | ----- | ----- | ----- |\n"

  local table_rows = {}
  local grand_total_row = "| GrandTotal |       |"

  for _, entry in ipairs(data) do
    local date = entry.date
    local weekday = get_weekday_from_date(date)
    local times = entry.times
    local row = string.format("| %s |  %s  |", date, weekday)

    -- Add time entries, only if they exist
    for i = 1, math.floor(#times / 2) do -- Iterate up to the number of pairs
      row = row .. string.format(" %s | %s |", times[2 * i - 1], times[2 * i])
    end

    -- Pad with empty cells if needed
    local num_time_pairs = math.floor(#times / 2)
    for i = 1, 3 - num_time_pairs do
      row = row .. "   -   |   -   |"
    end

    row = row .. string.format(" %s |\n", total_time)
    table.insert(table_rows, row)
  end

  grand_total_row = grand_total_row .. "   -   |   -   |   -   |   -   |   -   |   -   | 00:00 |\n"

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

---@param config WorkTimeCalculatorConfig
function M.generate_hours_table(config)
  local daily_notes = vim.fn.glob(config.daily_notes_dir .. "/*.md", 1, 1)
  local data = {}

  for _, filepath in ipairs(daily_notes) do
    local times, err = extract_times_from_file(filepath)
    if err then
      vim.notify("Error processing " .. filepath .. ": " .. err, vim.log.levels.ERROR)
    else
      local filename = vim.fn.fnamemodify(filepath, ":t:r")
      data[#data + 1] = {
        date = filename,
        times = times,
      }
    end
  end

  local markdown_table = generate_markdown_table(data)
  local existing_header = read_existing_header(config.output_file)
  local output_content = ""

  if existing_header then
    output_content = existing_header
  end

  output_content = output_content .. "\n# Hours\n\n" .. markdown_table

  local f = io.open(config.output_file, "w")
  if not f then
    vim.notify("Could not open output file: " .. config.output_file, vim.log.levels.ERROR)
    return
  end
  f:write(output_content)
  f:close()

  vim.notify("Hours table generated at " .. config.output_file, vim.log.levels.INFO)
end

local function generate_goal_column(content, workday_length)
  local lines = {}
  for line in content:gmatch("[^\n]+") do
    if line:match("^|") then
      if line:match("GrandTotal") then
        line = line:gsub("|$", "|       |")
      elseif line:match("^| Date") then
        line = line:gsub("|$", "| Goal  |")
      elseif line:match("^| %-") then
        line = line:gsub("|$", "| ----- |")
      else
        local weekday = line:match("%((%w+)%)")
        local goal = "00:00"
        if weekday and weekday ~= "Sat" and weekday ~= "Sun" then
          goal = workday_length
        end
        line = line:gsub("|$", "| " .. goal .. " |")
      end
    end
    table.insert(lines, line)
  end
  return table.concat(lines, "\n")
end

---@param config WorkTimeCalculatorConfig
function M.add_goal_column(config)
  -- Read the file after time calculation
  local f = io.open(config.output_file, "r")
  if not f then
    return
  end
  local content = f:read("*all")
  f:close()

  -- Add goal column
  content = generate_goal_column(content, config.workday_length)

  -- Write back to file
  f = io.open(config.output_file, "w")
  if not f then
    return
  end
  f:write(content)
  f:close()
end

return M
