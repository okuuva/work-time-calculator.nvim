local strptime = require("work-time-calculator.strptime")

describe("parse", function()
  it("parses standard ISO date format", function()
    local ts = strptime.parse("2024-06-15", "%Y-%m-%d")
    assert.is_not_nil(ts)
    assert.are.same("2024-06-15", os.date("%Y-%m-%d", ts))
  end)

  it("parses date with slashes", function()
    local ts = strptime.parse("2024/06/15", "%Y/%m/%d")
    assert.is_not_nil(ts)
    assert.are.same("2024-06-15", os.date("%Y-%m-%d", ts))
  end)

  it("parses American date format", function()
    local ts = strptime.parse("06/15/2024", "%m/%d/%Y")
    assert.is_not_nil(ts)
    assert.are.same("2024-06-15", os.date("%Y-%m-%d", ts))
  end)

  it("parses European date format", function()
    local ts = strptime.parse("15.06.2024", "%d.%m.%Y")
    assert.is_not_nil(ts)
    assert.are.same("2024-06-15", os.date("%Y-%m-%d", ts))
  end)

  it("parses two-digit year", function()
    local ts = strptime.parse("24-06-15", "%y-%m-%d")
    assert.is_not_nil(ts)
    assert.are.same("06-15", os.date("%m-%d", ts))
  end)

  it("parses full month name", function()
    local ts = strptime.parse("June 15, 2024", "%B %d, %Y")
    assert.is_not_nil(ts)
    assert.are.same("2024-06-15", os.date("%Y-%m-%d", ts))
  end)

  it("parses abbreviated month name", function()
    local ts = strptime.parse("Jun 15, 2024", "%b %d, %Y")
    assert.is_not_nil(ts)
    assert.are.same("2024-06-15", os.date("%Y-%m-%d", ts))
  end)

  it("parses full weekday name", function()
    local ts = strptime.parse("Saturday, June 15, 2024", "%A, %B %d, %Y")
    assert.is_not_nil(ts)
    assert.are.same("2024-06-15", os.date("%Y-%m-%d", ts))
  end)

  it("parses abbreviated weekday name", function()
    local ts = strptime.parse("Sat, Jun 15, 2024", "%a, %b %d, %Y")
    assert.is_not_nil(ts)
    assert.are.same("2024-06-15", os.date("%Y-%m-%d", ts))
  end)

  it("parses time components", function()
    local ts = strptime.parse("2024-06-15 14:30:45", "%Y-%m-%d %H:%M:%S")
    assert.is_not_nil(ts)
    assert.are.same("2024-06-15 14:30:45", os.date("%Y-%m-%d %H:%M:%S", ts))
  end)

  it("parses 12-hour time with AM/PM", function()
    local ts = strptime.parse("2024-06-15 02:30 PM", "%Y-%m-%d %I:%M %p")
    assert.is_not_nil(ts)
    assert.are.same("14:30", os.date("%H:%M", ts))
  end)

  it("returns nil for invalid date string", function()
    assert.is_nil(strptime.parse("not-a-date", "%Y-%m-%d"))
  end)

  it("returns nil for mismatched format", function()
    assert.is_nil(strptime.parse("2024-06-15", "%Y/%m/%d"))
  end)

  it("returns nil for partial match", function()
    -- "2024-06-15-extra" should not match "%Y-%m-%d"
    assert.is_nil(strptime.parse("2024-06-15-extra", "%Y-%m-%d"))
  end)

  it("returns nil for empty string", function()
    assert.is_nil(strptime.parse("", "%Y-%m-%d"))
  end)

  it("handles edge case dates", function()
    -- First day of year
    local ts1 = strptime.parse("2024-01-01", "%Y-%m-%d")
    assert.is_not_nil(ts1)
    assert.are.same("2024-01-01", os.date("%Y-%m-%d", ts1))

    -- Last day of year
    local ts2 = strptime.parse("2024-12-31", "%Y-%m-%d")
    assert.is_not_nil(ts2)
    assert.are.same("2024-12-31", os.date("%Y-%m-%d", ts2))

    -- Leap day
    local ts3 = strptime.parse("2024-02-29", "%Y-%m-%d")
    assert.is_not_nil(ts3)
    assert.are.same("2024-02-29", os.date("%Y-%m-%d", ts3))
  end)

  it("handles various year ranges", function()
    local ts1 = strptime.parse("1970-01-01", "%Y-%m-%d")
    assert.is_not_nil(ts1)

    local ts2 = strptime.parse("2099-12-31", "%Y-%m-%d")
    assert.is_not_nil(ts2)
  end)
end)

describe("matches", function()
  it("returns true for valid date", function()
    assert.is_true(strptime.matches("2024-06-15", "%Y-%m-%d"))
  end)

  it("returns false for invalid date", function()
    assert.is_false(strptime.matches("not-a-date", "%Y-%m-%d"))
  end)

  it("returns false for mismatched format", function()
    assert.is_false(strptime.matches("2024-06-15", "%Y/%m/%d"))
  end)

  it("returns true for text-based format", function()
    assert.is_true(strptime.matches("January 15, 2024", "%B %d, %Y"))
  end)

  it("returns false for partial match", function()
    assert.is_false(strptime.matches("2024-06-15.md", "%Y-%m-%d"))
  end)
end)
