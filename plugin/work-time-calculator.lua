vim.api.nvim_create_user_command("CalculateWorkHours", function()
  require("work-time-calculator").calculate_time()
end, {})
