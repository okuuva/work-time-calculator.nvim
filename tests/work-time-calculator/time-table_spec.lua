local tt = require("work-time-calculator.time-table")

describe("generate_markdown_table", function()
  it("handles days with varying number of time entries (1, 2, and 3 pairs)", function()
    local time_table = {
      {
        date = "2024-08-01",
        weekday = "Thu",
        day_type = "Work day",
        times = { "08:00", "16:00" }, -- 1 pair
        total_hours = 8 * 60,
        target_hours = 8 * 60,
        hours_diff = 0,
      },
      {
        date = "2024-08-02",
        weekday = "Fri",
        day_type = "Work day",
        times = { "08:00", "12:00", "13:00", "17:00" }, -- 2 pairs
        total_hours = 8 * 60,
        target_hours = 8 * 60,
        hours_diff = 0,
      },
      {
        date = "2024-08-03",
        weekday = "Sat",
        day_type = "Weekend",
        times = { "07:00", "09:00", "10:00", "12:00", "13:00", "15:00" }, -- 3 pairs
        total_hours = 6 * 60,
        target_hours = 0,
        hours_diff = 6 * 60,
      },
      {
        date = "2024-08-04",
        weekday = "Sun",
        day_type = "Weekend",
        times = {}, -- 0 pairs
        total_hours = 0,
        target_hours = 0,
        hours_diff = 0,
      },
    }
    local markdown = tt.generate_markdown_table(time_table)
    local expected_markdown = [[

| Date | Day | Type | In | Out | In | Out | In | Out | Total | Goal | Diff |
| ---- | --- | ---- | -- | --- | -- | --- | -- | --- | ----- | ---- | ---- |
| 2024-08-01 | Thu | Work day | 08:00 | 16:00 |    |    |    |    | 08:00 | 08:00 | 00:00 |
| 2024-08-02 | Fri | Work day | 08:00 | 12:00 | 13:00 | 17:00 |    |    | 08:00 | 08:00 | 00:00 |
| 2024-08-03 | Sat | Weekend | 07:00 | 09:00 | 10:00 | 12:00 | 13:00 | 15:00 | 06:00 | 00:00 | 06:00 |
| 2024-08-04 | Sun | Weekend |    |    |    |    |    |    | 00:00 | 00:00 | 00:00 |
| Total |       |       |      |      |      |      |      |      | 22:00 | 16:00 | 06:00 |
]]
    assert.are.same(expected_markdown, "\n" .. markdown)
  end)

  it("handles a day with no times (e.g. vacation)", function()
    local time_table = {
      {
        date = "2024-08-04",
        weekday = "Sun",
        day_type = "Vacation",
        times = {},
        total_hours = 0,
        target_hours = 0,
        hours_diff = 0,
      },
    }
    local markdown = tt.generate_markdown_table(time_table)
    local expected_markdown = [[

| Date | Day | Type | Total | Goal | Diff |
| ---- | --- | ---- | ----- | ---- | ---- |
| 2024-08-04 | Sun | Vacation | 00:00 | 00:00 | 00:00 |
| Total |       |       | 00:00 | 00:00 | 00:00 |
]]
    assert.are.same(expected_markdown, "\n" .. markdown)
  end)

  it("handles a day with an odd number of times (should ignore the last unmatched time)", function()
    local time_table = {
      {
        date = "2024-08-05",
        weekday = "Mon",
        day_type = "Work day",
        times = { "08:00", "12:00", "13:00" }, -- 1.5 pairs, should ignore last
        total_hours = 4 * 60, -- Only one pair added
        target_hours = 8 * 60,
        hours_diff = -4 * 60,
      },
    }
    local markdown = tt.generate_markdown_table(time_table)
    local expected_markdown = [[

| Date | Day | Type | In | Out | In | Out | Total | Goal | Diff |
| ---- | --- | ---- | -- | --- | -- | --- | ----- | ---- | ---- |
| 2024-08-05 | Mon | Work day | 08:00 | 12:00 | 13:00 |    | 04:00 | 08:00 | -04:00 |
| Total |       |       |      |      |      |      | 04:00 | 08:00 | -04:00 |
]]
    assert.are.same(expected_markdown, "\n" .. markdown)
  end)

  it("handles a single day with the maximum number of pairs", function()
    local time_table = {
      {
        date = "2024-08-06",
        weekday = "Tue",
        day_type = "Work day",
        times = { "08:00", "09:00", "09:30", "10:30", "11:00", "11:30" },
        total_hours = 3 * 60,
        target_hours = 8 * 60,
        hours_diff = -5 * 60,
      },
    }
    local markdown = tt.generate_markdown_table(time_table)
    local expected_markdown = [[

| Date | Day | Type | In | Out | In | Out | In | Out | Total | Goal | Diff |
| ---- | --- | ---- | -- | --- | -- | --- | -- | --- | ----- | ---- | ---- |
| 2024-08-06 | Tue | Work day | 08:00 | 09:00 | 09:30 | 10:30 | 11:00 | 11:30 | 03:00 | 08:00 | -05:00 |
| Total |       |       |      |      |      |      |      |      | 03:00 | 08:00 | -05:00 |
]]
    assert.are.same(expected_markdown, "\n" .. markdown)
  end)

  it("handles consecutive days with different numbers of time pairs", function()
    local time_table = {
      {
        date = "2024-08-07",
        weekday = "Wed",
        day_type = "Work day",
        times = { "08:00", "12:00" },
        total_hours = 4 * 60,
        target_hours = 8 * 60,
        hours_diff = -4 * 60,
      },
      {
        date = "2024-08-08",
        weekday = "Thu",
        day_type = "Work day",
        times = { "09:00", "17:00" },
        total_hours = 8 * 60,
        target_hours = 8 * 60,
        hours_diff = 0,
      },
      {
        date = "2024-08-09",
        weekday = "Fri",
        day_type = "Work day",
        times = { "08:30", "12:30", "13:30", "17:30" },
        total_hours = 8 * 60,
        target_hours = 8 * 60,
        hours_diff = 0,
      },
    }
    local markdown = tt.generate_markdown_table(time_table)
    local expected_markdown = [[

| Date | Day | Type | In | Out | In | Out | Total | Goal | Diff |
| ---- | --- | ---- | -- | --- | -- | --- | ----- | ---- | ---- |
| 2024-08-07 | Wed | Work day | 08:00 | 12:00 |    |    | 04:00 | 08:00 | -04:00 |
| 2024-08-08 | Thu | Work day | 09:00 | 17:00 |    |    | 08:00 | 08:00 | 00:00 |
| 2024-08-09 | Fri | Work day | 08:30 | 12:30 | 13:30 | 17:30 | 08:00 | 08:00 | 00:00 |
| Total |       |       |      |      |      |      | 20:00 | 24:00 | -04:00 |
]]
    assert.are.same(expected_markdown, "\n" .. markdown)
  end)

  it("handles a day with only one time (should pad correctly)", function()
    local time_table = {
      {
        date = "2024-08-10",
        weekday = "Sat",
        day_type = "Work day",
        times = { "08:00" },
        total_hours = 0,
        target_hours = 8 * 60,
        hours_diff = -8 * 60,
      },
    }
    local markdown = tt.generate_markdown_table(time_table)
    local expected_markdown = [[

| Date | Day | Type | In | Out | Total | Goal | Diff |
| ---- | --- | ---- | -- | --- | ----- | ---- | ---- |
| 2024-08-10 | Sat | Work day | 08:00 |    | 00:00 | 08:00 | -08:00 |
| Total |       |       |      |      | 00:00 | 08:00 | -08:00 |
]]
    assert.are.same(expected_markdown, "\n" .. markdown)
  end)

  it("handles a day with four pairs (eight times)", function()
    local time_table = {
      {
        date = "2024-08-11",
        weekday = "Sun",
        day_type = "Work day",
        times = { "08:00", "09:00", "09:10", "10:10", "10:20", "11:20", "12:00", "13:00" },
        total_hours = 5 * 60,
        target_hours = 8 * 60,
        hours_diff = -3 * 60,
      },
    }
    local markdown = tt.generate_markdown_table(time_table)
    local expected_markdown = [[

| Date | Day | Type | In | Out | In | Out | In | Out | In | Out | Total | Goal | Diff |
| ---- | --- | ---- | -- | --- | -- | --- | -- | --- | -- | --- | ----- | ---- | ---- |
| 2024-08-11 | Sun | Work day | 08:00 | 09:00 | 09:10 | 10:10 | 10:20 | 11:20 | 12:00 | 13:00 | 05:00 | 08:00 | -03:00 |
| Total |       |       |      |      |      |      |      |      |      |      | 05:00 | 08:00 | -03:00 |
]]
    assert.are.same(expected_markdown, "\n" .. markdown)
  end)

  it("handles mixed types of days (work, vacation, sick)", function()
    local time_table = {
      {
        date = "2024-08-12",
        weekday = "Mon",
        day_type = "Work day",
        times = { "08:00", "12:00", "13:00", "17:00" },
        total_hours = 8 * 60,
        target_hours = 8 * 60,
        hours_diff = 0,
      },
      {
        date = "2024-08-13",
        weekday = "Tue",
        day_type = "Vacation",
        times = {},
        total_hours = 0,
        target_hours = 0,
        hours_diff = 0,
      },
      {
        date = "2024-08-14",
        weekday = "Wed",
        day_type = "Sick day",
        times = { "09:00", "12:00" },
        total_hours = 3 * 60,
        target_hours = 8 * 60,
        hours_diff = -5 * 60,
      },
    }
    local markdown = tt.generate_markdown_table(time_table)
    local expected_markdown = [[

| Date | Day | Type | In | Out | In | Out | Total | Goal | Diff |
| ---- | --- | ---- | -- | --- | -- | --- | ----- | ---- | ---- |
| 2024-08-12 | Mon | Work day | 08:00 | 12:00 | 13:00 | 17:00 | 08:00 | 08:00 | 00:00 |
| 2024-08-13 | Tue | Vacation |    |    |    |    | 00:00 | 00:00 | 00:00 |
| 2024-08-14 | Wed | Sick day | 09:00 | 12:00 |    |    | 03:00 | 08:00 | -05:00 |
| Total |       |       |      |      |      |      | 11:00 | 16:00 | -05:00 |
]]
    assert.are.same(expected_markdown, "\n" .. markdown)
  end)
end)
