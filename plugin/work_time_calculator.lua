vim.api.nvim_create_user_command("CalculateWorkHours", function()
  require("work_time_calculator").calculate_time()
end, {})
