local M = {}

function M.get_commits(cb)
  local cfg = require("gitlogdiff").config or {}
  local max_count = tonumber(cfg.max_count)

  local args = {
    "git",
    "log",
    string.format("--max-count=%d", max_count),
    "--pretty=format:%h %ad %s",
    "--date=short",
    "--color=never",
  }

  vim.system(args, { text = true }, function(res)
    if res.code ~= 0 then
      local err = (res.stderr or ""):gsub("\n$", "")
      vim.schedule(function()
        vim.notify(
          (#err > 0) and ("git log failed: " .. err) or "git log failed (are you in a git repo?)",
          vim.log.levels.WARN
        )
        cb({})
      end)
      return
    end

    local commits = vim.split(res.stdout, "\n", { trimempty = true })
    vim.schedule(function()
      cb(commits)
    end)
  end)
end

return M
