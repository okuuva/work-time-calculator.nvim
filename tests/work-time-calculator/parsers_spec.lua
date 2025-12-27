local parsers = require("work-time-calculator.parsers")

describe("extract_times_from_file", function()
  it("returns correct structure on missing file", function()
    local times, day_type, err = parsers.extract_times_from_file("nonexistent.txt")
    assert.are.same({}, times)
    assert.is_truthy(err)
  end)
end)

describe("get_date", function()
  it("returns date string", function()
    local now = os.time({ year = 2024, month = 1, day = 2 })
    assert.are.same("2024-01-02", parsers.get_date(now))
  end)
end)

describe("get_timestamp", function()
  it("returns correct timestamp", function()
    local ts = parsers.get_timestamp("2024-01-01")
    assert.are.same(os.time({ year = 2024, month = 1, day = 1 }), ts)
  end)
end)

describe("get_total_time", function()
  it("sums intervals correctly", function()
    local times = { "08:00", "12:00", "13:00", "17:00" }
    assert.are.same(8 * 60, parsers.get_total_time(times))
  end)
end)

describe("get_weekday", function()
  it("returns weekday abbreviation", function()
    local now = os.time({ year = 2024, month = 1, day = 1 }) -- Monday
    assert.is_truthy(type(parsers.get_weekday(now)) == "string")
  end)
end)

describe("minutes_to_time", function()
  it("returns correct string for positive and negative", function()
    assert.are.same("01:30", parsers.minutes_to_time(90))
    assert.are.same("-00:30", parsers.minutes_to_time(-30))
  end)
end)

describe("next_day", function()
  it("increases time by one day", function()
    local now = os.time({ year = 2024, month = 1, day = 1 })
    assert.are.same(now + 24 * 60 * 60, parsers.next_day(now))
  end)

  it("handles DST transitions correctly", function()
    -- Test DST transition in October 2025 (clocks go back on Oct 26)
    -- This ensures next_day produces timestamps that match get_timestamp
    local oct25 = parsers.get_timestamp("2025-10-25")
    local oct26_next = parsers.next_day(oct25)
    local oct27_next = parsers.next_day(oct26_next)

    local oct26_direct = parsers.get_timestamp("2025-10-26")
    local oct27_direct = parsers.get_timestamp("2025-10-27")

    assert.are.same(oct26_direct, oct26_next, "Oct 26 timestamps should match")
    assert.are.same(oct27_direct, oct27_next, "Oct 27 timestamps should match")
  end)

  it("produces consistent date strings across DST", function()
    -- Ensure that next_day produces the correct date string even across DST
    local oct25 = parsers.get_timestamp("2025-10-25")
    local oct26 = parsers.next_day(oct25)
    local oct27 = parsers.next_day(oct26)

    assert.are.same("2025-10-26", parsers.get_date(oct26))
    assert.are.same("2025-10-27", parsers.get_date(oct27))
  end)
end)

describe("read_existing_header", function()
  it("returns nil if file does not exist", function()
    assert.is_nil(parsers.read_existing_header("file_that_does_not_exist.txt"))
  end)
end)

describe("time_to_minutes", function()
  it('parses "08:30" as 510', function()
    assert.are.same(510, parsers.time_to_minutes("08:30"))
  end)
end)
