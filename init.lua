local M = {}

M.config = {
  max_count = 300,
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.open()
  require("gitlogdiff.log").get_commits(function(commits)
    if #commits == 0 then
      vim.notify("No git commits found", vim.log.levels.WARN)
      return
    end
    require("gitlogdiff.ui").open(commits)
  end)
end

vim.api.nvim_create_user_command("GitLogDiff", M.open, {
  force = true,
  desc = "Open a picker to select commits and diff them",
})

return M
