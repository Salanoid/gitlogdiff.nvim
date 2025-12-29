vim.api.nvim_create_user_command("GitLogDiff", function()
  require("gitlogdiff").open()
end, {
  force = true,
  desc = "Open a picker to select commits and diff them",
})
