rockspec_format = "3.0"
package = "work-time-calculator.nvim"
version = "dev-1"
source = {
  url = "git+ssh://git@github.com/okuuva/work-time-calculator.nvim.git",
}
description = {
  homepage = "https://github.com/okuuva/work-time-calculator.nvim",
  license = "MIT",
}
dependencies = {
  "lua == 5.1",
}
test_dependencies = {
  "busted",
  "nlua",
}
