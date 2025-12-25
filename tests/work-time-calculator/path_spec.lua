---@diagnostic disable: invisible
local path = require("work-time-calculator.path")

describe("path", function()

  describe("last_n_path_components", function()
    it("returns last component when n=1", function()
      assert.are.same("file.md", path.last_n_path_components("/home/user/notes/file.md", 1, "/"))
    end)

    it("returns last 2 components when n=2", function()
      assert.are.same("notes/file.md", path.last_n_path_components("/home/user/notes/file.md", 2, "/"))
    end)

    it("returns last 3 components when n=3", function()
      assert.are.same("user/notes/file.md", path.last_n_path_components("/home/user/notes/file.md", 3, "/"))
    end)

    it("returns entire path when n equals number of components", function()
      assert.are.same("home/user/notes/file.md", path.last_n_path_components("/home/user/notes/file.md", 4, "/"))
    end)

    it("returns entire path when n exceeds number of components", function()
      assert.are.same("home/user/notes/file.md", path.last_n_path_components("/home/user/notes/file.md", 10, "/"))
    end)

    it("handles path without leading slash", function()
      assert.are.same("notes/file.md", path.last_n_path_components("home/user/notes/file.md", 2, "/"))
    end)

    it("handles single component path", function()
      assert.are.same("file.md", path.last_n_path_components("file.md", 1, "/"))
    end)

    it("handles single component path with n > 1", function()
      assert.are.same("file.md", path.last_n_path_components("file.md", 5, "/"))
    end)

    it("handles path with trailing slash", function()
      assert.are.same("notes/file", path.last_n_path_components("/home/user/notes/file/", 2, "/"))
    end)

    it("handles n=0 returning empty string", function()
      assert.are.same("", path.last_n_path_components("/home/user/notes/file.md", 0, "/"))
    end)

    it("uses forward slash as default separator on unix-like systems", function()
      -- This test assumes the default separator works correctly
      local result = path.last_n_path_components("/home/user/file.md", 1)
      assert.are.same("file.md", result)
    end)

    it("works with custom separator", function()
      assert.are.same("notes\\file.md", path.last_n_path_components("C:\\Users\\notes\\file.md", 2, "\\"))
    end)

    it("handles empty path", function()
      assert.are.same("", path.last_n_path_components("", 1, "/"))
    end)
  end)

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

      -- Create subdirectory structure
      local subdir = vim.fs.joinpath(temp_dir, "2024", "06")
      vim.fn.mkdir(subdir, "p")

      -- Create test files in the subdirectory
      local file1 = vim.fs.joinpath(subdir, "2024-06-01.md")
      local file2 = vim.fs.joinpath(subdir, "2024-06-15.md")

      vim.fn.writefile({}, file1)
      vim.fn.writefile({}, file2)

      -- Mock current buffer to return a file in June 2024
      local original_nvim_buf_get_name = vim.api.nvim_buf_get_name
      vim.api.nvim_buf_get_name = function()
        return file2
      end

      local result = path.get_daily_notes(config)

      vim.api.nvim_buf_get_name = original_nvim_buf_get_name

      assert.are.same(2, #result)
      assert.is_truthy(vim.tbl_contains(result, file1))
      assert.is_truthy(vim.tbl_contains(result, file2))
    end)

    it("does not return files from other directories", function()
      local config = { daily_notes_dir = temp_dir, date_format = "%Y/%m/%Y-%m-%d" }

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

      -- Mock current buffer to return a file in June 2024
      local original_nvim_buf_get_name = vim.api.nvim_buf_get_name
      vim.api.nvim_buf_get_name = function()
        return june_file
      end

      local result = path.get_daily_notes(config)

      vim.api.nvim_buf_get_name = original_nvim_buf_get_name

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

  describe("get_output_file_path", function()
    it("returns output file in daily_notes_dir for simple date format", function()
      local config = { daily_notes_dir = "/notes", date_format = "%Y-%m-%d", output_file = "time-tracking.md" }
      assert.are.same("/notes/time-tracking.md", path.get_output_file_path(config))
    end)

    it("returns output file in subdirectory for date format with subdirs", function()
      local config = { daily_notes_dir = "/notes", date_format = "%Y/%m/%Y-%m-%d", output_file = "hours.md" }

      -- Mock current buffer to return a file in June 2024
      local original_nvim_buf_get_name = vim.api.nvim_buf_get_name
      vim.api.nvim_buf_get_name = function()
        return "/notes/2024/06/2024-06-15.md"
      end

      local result = path.get_output_file_path(config)

      vim.api.nvim_buf_get_name = original_nvim_buf_get_name

      assert.are.same("/notes/2024/06/hours.md", result)
    end)

    it("uses default output file name when provided", function()
      local config = { daily_notes_dir = "/my/notes", date_format = "%Y-%m-%d", output_file = "time-tracking.md" }
      assert.are.same("/my/notes/time-tracking.md", path.get_output_file_path(config))
    end)

    it("handles custom output file name", function()
      local config = { daily_notes_dir = "/notes", date_format = "%Y-%m-%d", output_file = "custom-hours.md" }
      assert.are.same("/notes/custom-hours.md", path.get_output_file_path(config))
    end)

    it("handles nil daily_notes_dir", function()
      local config = { daily_notes_dir = nil, date_format = "%Y-%m-%d", output_file = "time-tracking.md" }
      -- When daily_notes_dir is nil, base dir becomes "/" so output file is at root
      assert.are.same("/time-tracking.md", path.get_output_file_path(config))
    end)

    it("supports strftime formatting in output file name with year-month", function()
      local config = { daily_notes_dir = "/notes", date_format = "%Y-%m-%d", output_file = "hours-%Y-%m.md" }

      -- Mock current buffer to return a file in June 2024
      local original_nvim_buf_get_name = vim.api.nvim_buf_get_name
      vim.api.nvim_buf_get_name = function()
        return "/notes/2024-06-15.md"
      end

      local result = path.get_output_file_path(config)

      vim.api.nvim_buf_get_name = original_nvim_buf_get_name

      assert.are.same("/notes/hours-2024-06.md", result)
    end)

    it("supports strftime formatting in output file name with full date", function()
      local config = { daily_notes_dir = "/notes", date_format = "%Y-%m-%d", output_file = "time-tracking-%Y-%m-%d.md" }

      -- Mock current buffer to return a file on Dec 25, 2024
      local original_nvim_buf_get_name = vim.api.nvim_buf_get_name
      vim.api.nvim_buf_get_name = function()
        return "/notes/2024-12-25.md"
      end

      local result = path.get_output_file_path(config)

      vim.api.nvim_buf_get_name = original_nvim_buf_get_name

      assert.are.same("/notes/time-tracking-2024-12-25.md", result)
    end)

    it("supports strftime formatting with subdirectory date format", function()
      local config = { daily_notes_dir = "/notes", date_format = "%Y/%m/%Y-%m-%d", output_file = "hours-%Y-%m.md" }

      -- Mock current buffer to return a file in June 2024
      local original_nvim_buf_get_name = vim.api.nvim_buf_get_name
      vim.api.nvim_buf_get_name = function()
        return "/notes/2024/06/2024-06-15.md"
      end

      local result = path.get_output_file_path(config)

      vim.api.nvim_buf_get_name = original_nvim_buf_get_name

      assert.are.same("/notes/2024/06/hours-2024-06.md", result)
    end)

    it("handles output file with only strftime specifiers", function()
      local config = { daily_notes_dir = "/notes", date_format = "%Y-%m-%d", output_file = "%Y-%m-hours.md" }

      -- Mock current buffer to return a file in March 2023
      local original_nvim_buf_get_name = vim.api.nvim_buf_get_name
      vim.api.nvim_buf_get_name = function()
        return "/notes/2023-03-10.md"
      end

      local result = path.get_output_file_path(config)

      vim.api.nvim_buf_get_name = original_nvim_buf_get_name

      assert.are.same("/notes/2023-03-hours.md", result)
    end)
  end)

  describe("get_timestamp_from_filepath", function()
    it("returns timestamp for simple date format", function()
      local filepath = "/notes/2024-06-15.md"
      local expected_timestamp = os.time({ year = 2024, month = 6, day = 15 })
      assert.are.same(expected_timestamp, path.get_timestamp_from_filepath("%Y-%m-%d", filepath))
    end)

    it("returns timestamp for subdirectory date format", function()
      local filepath = "/notes/2024/06/2024-06-15.md"
      local expected_timestamp = os.time({ year = 2024, month = 6, day = 15 })
      assert.are.same(expected_timestamp, path.get_timestamp_from_filepath("%Y/%m/%Y-%m-%d", filepath))
    end)

    it("returns timestamp for file in any directory with matching format", function()
      local filepath = "/other/2024-06-15.md"
      local expected_timestamp = os.time({ year = 2024, month = 6, day = 15 })
      assert.are.same(expected_timestamp, path.get_timestamp_from_filepath("%Y-%m-%d", filepath))
    end)

    it("returns nil when path depth is less than format depth", function()
      -- Format expects 3 levels (year/month/filename) but filepath only has 1 level
      local filepath = "/2024-06-15.md"
      assert.is_nil(path.get_timestamp_from_filepath("%Y/%m/%Y-%m-%d", filepath))
    end)

    it("returns nil for non-md file", function()
      local filepath = "/notes/2024-06-15.txt"
      assert.is_nil(path.get_timestamp_from_filepath("%Y-%m-%d", filepath))
    end)

    it("returns nil for file with name not matching date format", function()
      local filepath = "/notes/my-notes.md"
      assert.is_nil(path.get_timestamp_from_filepath("%Y-%m-%d", filepath))
    end)

    it("returns timestamp from deeply nested path", function()
      local filepath = "/home/user/documents/notes/daily/2024-06-15.md"
      local expected_timestamp = os.time({ year = 2024, month = 6, day = 15 })
      assert.are.same(expected_timestamp, path.get_timestamp_from_filepath("%Y-%m-%d", filepath))
    end)

    it("returns timestamp with subdirectory format from deeply nested path", function()
      local filepath = "/home/user/notes/2024/06/2024-06-15.md"
      local expected_timestamp = os.time({ year = 2024, month = 6, day = 15 })
      assert.are.same(expected_timestamp, path.get_timestamp_from_filepath("%Y/%m/%Y-%m-%d", filepath))
    end)

    it("returns nil when subdirectory structure doesn't match format", function()
      -- Format expects year/month/filename but path has wrong structure
      local filepath = "/notes/2024/2024-06-15.md"
      assert.is_nil(path.get_timestamp_from_filepath("%Y/%m/%Y-%m-%d", filepath))
    end)
  end)
end)
