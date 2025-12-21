local path = require("work-time-calculator.path")

describe("path", function()

  describe("get_daily_note_base_dir", function()
    it("returns daily_notes_dir for simple date format", function()
      local config = { daily_notes_dir = "/notes", date_format = "%Y-%m-%d" }
      assert.are.same("/notes", path.get_daily_note_base_dir(config))
    end)

    it("returns subdirectory for date format with subdirs", function()
      local config = { daily_notes_dir = "/notes", date_format = "%Y/%m/%Y-%m-%d" }
      local timestamp = os.time({ year = 2024, month = 6, day = 15 })
      assert.are.same("/notes/2024/06", path.get_daily_note_base_dir(config, timestamp))
    end)

    it("handles nil daily_notes_dir", function()
      local config = { daily_notes_dir = nil, date_format = "%Y-%m-%d" }
      -- When daily_notes_dir is nil, it becomes "" and dirname of "/2024-01-01" returns "/"
      assert.are.same("/", path.get_daily_note_base_dir(config))
    end)
  end)

  describe("glob_daily_notes", function()
    local temp_dir

    before_each(function()
      -- Create a temporary directory for test files
      temp_dir = vim.fn.tempname()
      vim.fn.mkdir(temp_dir, "p")
    end)

    after_each(function()
      -- Clean up temporary directory
      vim.fn.delete(temp_dir, "rf")
    end)

    it("returns empty table when no files match", function()
      local config = { daily_notes_dir = temp_dir, date_format = "%Y-%m-%d" }
      local result = path.get_daily_notes(config)
      assert.are.same({}, result)
    end)

    it("returns only files matching the date format", function()
      local config = { daily_notes_dir = temp_dir, date_format = "%Y-%m-%d" }

      -- Create some test files
      local file1 = vim.fs.joinpath(temp_dir, "2024-01-01.md")
      local file2 = vim.fs.joinpath(temp_dir, "2024-01-02.md")
      local file3 = vim.fs.joinpath(temp_dir, "not-a-date.md")
      local file4 = vim.fs.joinpath(temp_dir, "March 3rd 99.md")

      vim.fn.writefile({}, file1)
      vim.fn.writefile({}, file2)
      vim.fn.writefile({}, file3)
      vim.fn.writefile({}, file4)

      local result = path.get_daily_notes(config)

      -- Only files matching YYYY-MM-DD pattern should be returned
      assert.are.same(2, #result)
      assert.is_truthy(vim.tbl_contains(result, file1))
      assert.is_truthy(vim.tbl_contains(result, file2))
      assert.is_falsy(vim.tbl_contains(result, file3))
      assert.is_falsy(vim.tbl_contains(result, file4))
    end)

    it("returns matching files with subdirectory date format", function()
      local config = { daily_notes_dir = temp_dir, date_format = "%Y/%m/%Y-%m-%d" }
      local timestamp = os.time({ year = 2024, month = 6, day = 15 })

      -- Create subdirectory structure
      local subdir = vim.fs.joinpath(temp_dir, "2024", "06")
      vim.fn.mkdir(subdir, "p")

      -- Create test files in the subdirectory
      local file1 = vim.fs.joinpath(subdir, "2024-06-01.md")
      local file2 = vim.fs.joinpath(subdir, "2024-06-15.md")

      vim.fn.writefile({}, file1)
      vim.fn.writefile({}, file2)

      local result = path.get_daily_notes(config, timestamp)

      assert.are.same(2, #result)
      assert.is_truthy(vim.tbl_contains(result, file1))
      assert.is_truthy(vim.tbl_contains(result, file2))
    end)

    it("does not return files from other directories", function()
      local config = { daily_notes_dir = temp_dir, date_format = "%Y/%m/%Y-%m-%d" }
      local timestamp = os.time({ year = 2024, month = 6, day = 15 })

      -- Create subdirectory structure for June
      local june_dir = vim.fs.joinpath(temp_dir, "2024", "06")
      vim.fn.mkdir(june_dir, "p")

      -- Create subdirectory structure for July
      local july_dir = vim.fs.joinpath(temp_dir, "2024", "07")
      vim.fn.mkdir(july_dir, "p")

      -- Create test files
      local june_file = vim.fs.joinpath(june_dir, "2024-06-15.md")
      local july_file = vim.fs.joinpath(july_dir, "2024-07-15.md")

      vim.fn.writefile({}, june_file)
      vim.fn.writefile({}, july_file)

      local result = path.get_daily_notes(config, timestamp)

      -- Should only find June files
      assert.are.same(1, #result)
      assert.are.same(june_file, result[1])
    end)

    it("ignores non-md files", function()
      local config = { daily_notes_dir = temp_dir, date_format = "%Y-%m-%d" }

      -- Create test files with different extensions
      local md_file = vim.fs.joinpath(temp_dir, "2024-01-01.md")
      local txt_file = vim.fs.joinpath(temp_dir, "2024-01-02.txt")

      vim.fn.writefile({}, md_file)
      vim.fn.writefile({}, txt_file)

      local result = path.get_daily_notes(config)

      assert.are.same(1, #result)
      assert.are.same(md_file, result[1])
    end)
  end)
end)

