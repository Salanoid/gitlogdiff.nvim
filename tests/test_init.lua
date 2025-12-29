local T = MiniTest.new_set()

T["setup()"] = function()
  local gitlogdiff = require("gitlogdiff")
  gitlogdiff.setup({ max_count = 100 })
  MiniTest.expect.equality(gitlogdiff.config.max_count, 100)
end

T["actions"] = MiniTest.new_set()

local original_cmd = vim.cmd
T["actions"].before_each = function()
  vim.cmd = function() end
end
T["actions"].after_each = function()
  vim.cmd = original_cmd
end

T["actions"]["show_selected() diffs single commit correctly"] = function()
  local actions = require("gitlogdiff.actions")
  local cmds = {}
  vim.cmd = function(cmd)
    table.insert(cmds, cmd)
  end

  actions.show_selected({ "abc1234" })
  MiniTest.expect.equality(cmds[1], "DiffviewOpen abc1234^..abc1234")
end

T["actions"]["show_selected() diffs two commits correctly"] = function()
  local actions = require("gitlogdiff.actions")
  local cmds = {}
  vim.cmd = function(cmd)
    table.insert(cmds, cmd)
  end

  actions.show_selected({ "def5678", "abc1234" })
  MiniTest.expect.equality(cmds[1], "DiffviewOpen abc1234 def5678")
end

T["log"] = MiniTest.new_set()

T["log"]["get_commits() parses git log correctly"] = function()
  local log = require("gitlogdiff.log")
  local original_system = vim.system
  local original_schedule = vim.schedule

  vim.schedule = function(fn)
    fn()
  end
  vim.system = function(args, _, cb)
    cb({
      code = 0,
      stdout = "h1 2023-01-01 commit1\nh2 2023-01-02 commit2\n",
      stderr = "",
    })
    return {}
  end

  local result = nil
  log.get_commits(function(commits)
    result = commits
  end)

  MiniTest.expect.equality(result, { "h1 2023-01-01 commit1", "h2 2023-01-02 commit2" })

  vim.system = original_system
  vim.schedule = original_schedule
end

return T
