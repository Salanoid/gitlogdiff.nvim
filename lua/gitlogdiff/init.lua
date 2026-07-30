local M = {}

M.config = {
  max_count = 300,
  -- "auto" picks diffview.nvim if installed, then codediff.nvim.
  -- Set to "diffview" or "codediff" to force one.
  viewer = "auto",
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

return M
