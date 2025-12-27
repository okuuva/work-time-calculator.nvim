local strptime = require("work-time-calculator.strptime")

---Run a function multiple times and return timing stats
---@param fn function The function to benchmark
---@param iterations number Number of iterations
---@return table stats Timing statistics
local function benchmark(fn, iterations)
  iterations = iterations or 10000

  -- Warmup
  for _ = 1, 100 do
    fn()
  end

  local times = {}
  for i = 1, iterations do
    local start = vim.uv.hrtime()
    fn()
    local elapsed = vim.uv.hrtime() - start
    times[i] = elapsed
  end

  table.sort(times)
  local sum = 0
  for _, t in ipairs(times) do
    sum = sum + t
  end

  return {
    min = times[1] / 1e6, -- Convert to ms
    max = times[iterations] / 1e6,
    avg = (sum / iterations) / 1e6,
    median = times[math.floor(iterations / 2)] / 1e6,
    p95 = times[math.floor(iterations * 0.95)] / 1e6,
    p99 = times[math.floor(iterations * 0.99)] / 1e6,
    total = sum / 1e6,
    iterations = iterations,
  }
end

---Format benchmark results for display
---@param name string Benchmark name
---@param stats table Stats from benchmark()
---@return string
local function format_results(name, stats)
  return string.format(
    "%s:\n  avg: %.4f ms | median: %.4f ms | p95: %.4f ms | p99: %.4f ms\n  min: %.4f ms | max: %.4f ms | total: %.2f ms (%d iterations)",
    name,
    stats.avg,
    stats.median,
    stats.p95,
    stats.p99,
    stats.min,
    stats.max,
    stats.total,
    stats.iterations
  )
end

describe("benchmarks #benchmark", function()
  local ITERATIONS = 10000

  describe("parse", function()
    it("benchmark: ISO date format %Y-%m-%d", function()
      local stats = benchmark(function()
        strptime.parse("2024-06-15", "%Y-%m-%d")
      end, ITERATIONS)
      print("\n" .. format_results("parse ISO date", stats))
    end)

    it("benchmark: date with time %Y-%m-%d %H:%M:%S", function()
      local stats = benchmark(function()
        strptime.parse("2024-06-15 14:30:45", "%Y-%m-%d %H:%M:%S")
      end, ITERATIONS)
      print("\n" .. format_results("parse datetime", stats))
    end)

    it("benchmark: text-based format %B %d, %Y", function()
      local stats = benchmark(function()
        strptime.parse("June 15, 2024", "%B %d, %Y")
      end, ITERATIONS)
      print("\n" .. format_results("parse text date", stats))
    end)

    it("benchmark: complex format %A, %B %d, %Y", function()
      local stats = benchmark(function()
        strptime.parse("Saturday, June 15, 2024", "%A, %B %d, %Y")
      end, ITERATIONS)
      print("\n" .. format_results("parse complex date", stats))
    end)

    it("benchmark: invalid input (returns nil)", function()
      local stats = benchmark(function()
        strptime.parse("not-a-date", "%Y-%m-%d")
      end, ITERATIONS)
      print("\n" .. format_results("parse invalid", stats))
    end)

    it("benchmark: partial match rejection", function()
      local stats = benchmark(function()
        strptime.parse("2024-06-15-extra", "%Y-%m-%d")
      end, ITERATIONS)
      print("\n" .. format_results("parse partial match", stats))
    end)
  end)

  describe("matches", function()
    it("benchmark: valid ISO date", function()
      local stats = benchmark(function()
        strptime.matches("2024-06-15", "%Y-%m-%d")
      end, ITERATIONS)
      print("\n" .. format_results("matches valid ISO", stats))
    end)

    it("benchmark: invalid date", function()
      local stats = benchmark(function()
        strptime.matches("not-a-date", "%Y-%m-%d")
      end, ITERATIONS)
      print("\n" .. format_results("matches invalid", stats))
    end)

    it("benchmark: partial match rejection", function()
      local stats = benchmark(function()
        strptime.matches("2024-06-15.md", "%Y-%m-%d")
      end, ITERATIONS)
      print("\n" .. format_results("matches partial", stats))
    end)
  end)

  describe("throughput comparison", function()
    it("benchmark: batch of 100 mixed operations", function()
      local inputs = {
        { "2024-06-15", "%Y-%m-%d" },
        { "2024/06/15", "%Y/%m/%d" },
        { "June 15, 2024", "%B %d, %Y" },
        { "invalid", "%Y-%m-%d" },
        { "2024-06-15-extra", "%Y-%m-%d" },
      }
      local stats = benchmark(function()
        for _ = 1, 20 do
          for _, input in ipairs(inputs) do
            strptime.parse(input[1], input[2])
          end
        end
      end, ITERATIONS / 10)
      print("\n" .. format_results("batch 100 parse ops", stats))
    end)
  end)
end)
