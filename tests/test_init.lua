local T = MiniTest.new_set()

-- Helpers for integration tests that need a real git repo.

local function sh(args, cwd)
  local res = vim.system(args, { text = true, cwd = cwd }):wait()
  if res.code ~= 0 then
    error(res.stderr)
  end
  return vim.trim(res.stdout)
end

local function make_repo()
  local repo = vim.fn.tempname()
  vim.fn.mkdir(repo, "p")
  sh({ "git", "init" }, repo)
  sh({ "git", "config", "user.email", "test@test" }, repo)
  sh({ "git", "config", "user.name", "test" }, repo)
  return repo
end

local function git_commit(repo, file, content, msg)
  vim.fn.writefile({ content }, repo .. "/" .. file)
  sh({ "git", "add", file }, repo)
  sh({ "git", "commit", "-m", msg }, repo)
  return sh({ "git", "rev-parse", "--short", "HEAD" }, repo)
end

local function in_repo(repo, fn)
  local cwd = vim.fn.getcwd()
  vim.fn.chdir(repo)
  local ok, a, b = pcall(fn)
  vim.fn.chdir(cwd)
  if not ok then
    error(a)
  end
  return a, b
end

T["setup()"] = function()
  local gitlogdiff = require("gitlogdiff")
  gitlogdiff.setup({ max_count = 100 })
  MiniTest.expect.equality(gitlogdiff.config.max_count, 100)
  -- partial opts keep the other defaults
  MiniTest.expect.equality(gitlogdiff.config.viewer, "auto")
end

T[":GitLogDiff command is defined"] = function()
  MiniTest.expect.equality(vim.fn.exists(":GitLogDiff"), 2)
end

T["open() notifies when there are no commits"] = function()
  local original_log = package.loaded["gitlogdiff.log"]
  package.loaded["gitlogdiff.log"] = {
    get_commits = function(cb)
      cb({})
    end,
  }
  local original_notify = vim.notify
  local messages = {}
  vim.notify = function(msg)
    table.insert(messages, msg)
  end

  require("gitlogdiff").open()

  vim.notify = original_notify
  package.loaded["gitlogdiff.log"] = original_log

  MiniTest.expect.equality(messages[1], "No git commits found")
end

T["open() shows the commit picker (end to end)"] = function()
  require("gitlogdiff").setup({ max_count = 3 })
  require("gitlogdiff").open()

  local ui = require("gitlogdiff.ui")
  local opened = vim.wait(5000, function()
    return ui.state.win ~= nil and vim.api.nvim_win_is_valid(ui.state.win)
  end, 10)
  MiniTest.expect.equality(opened, true)

  local lines = vim.api.nvim_buf_get_lines(ui.state.buf, 0, -1, false)
  MiniTest.expect.equality(#lines, 3)
  MiniTest.expect.equality(lines[1]:match("^○ %w+") ~= nil, true)

  vim.api.nvim_win_close(ui.state.win, true)
end

local original_cmd = vim.cmd
T["actions"] = MiniTest.new_set({
  hooks = {
    pre_case = function()
      vim.cmd = function() end
      require("gitlogdiff").config.viewer = "diffview"
    end,
    post_case = function()
      vim.cmd = original_cmd
      require("gitlogdiff").config.viewer = "auto"
    end,
  },
})

local function capture_cmds()
  local cmds = {}
  vim.cmd = function(cmd)
    table.insert(cmds, cmd)
  end
  return cmds
end

local function capture_notify()
  local messages = {}
  vim.notify = function(msg)
    table.insert(messages, msg)
  end
  return messages
end

T["actions"]["show_selected() notifies on empty selection"] = function()
  local actions = require("gitlogdiff.actions")
  local cmds = capture_cmds()
  local original_notify = vim.notify
  local messages = capture_notify()

  actions.show_selected({}, {})
  vim.notify = original_notify

  MiniTest.expect.equality(cmds, {})
  MiniTest.expect.equality(messages[1], "No commits selected")
end

T["actions"]["show_selected() diffs single commit correctly"] = function()
  local actions = require("gitlogdiff.actions")
  local cmds = capture_cmds()

  actions.show_selected({ "abc1234" }, { 1 })
  MiniTest.expect.equality(cmds[1], "DiffviewOpen abc1234^..abc1234")
end

T["actions"]["show_selected() diffs two consecutive commits correctly"] = function()
  local actions = require("gitlogdiff.actions")
  local cmds = capture_cmds()

  actions.show_selected({ "newer123", "older456" }, { 1, 2 })
  MiniTest.expect.equality(cmds[1], "DiffviewOpen older456^..newer123")
end

T["actions"]["show_selected() diffs a consecutive range as one diff"] = function()
  local actions = require("gitlogdiff.actions")
  local cmds = capture_cmds()

  actions.show_selected({ "c3", "c2", "c1" }, { 4, 5, 6 })
  MiniTest.expect.equality(cmds, { "DiffviewOpen c1^..c3" })
end

T["actions"]["show_selected() combines non-consecutive commits via synthetic commit"] = function()
  local actions = require("gitlogdiff.actions")
  local cmds = capture_cmds()

  local original_build = actions.build_combined
  local built_with
  actions.build_combined = function(hashes)
    built_with = hashes
    return "synth99"
  end

  actions.show_selected({ "newer123", "older789" }, { 1, 3 })
  actions.build_combined = original_build

  MiniTest.expect.equality(built_with, { "newer123", "older789" })
  MiniTest.expect.equality(cmds[1], "DiffviewOpen older789^..synth99")
end

T["actions"]["show_selected() falls back to per-commit diffs on conflict"] = function()
  local actions = require("gitlogdiff.actions")
  local cmds = capture_cmds()

  local original_build = actions.build_combined
  local original_notify = vim.notify
  local messages = capture_notify()
  actions.build_combined = function()
    return nil, "CONFLICT (content): merge conflict in foo.txt"
  end

  actions.show_selected({ "newer123", "older789" }, { 1, 3 })
  actions.build_combined = original_build
  vim.notify = original_notify

  MiniTest.expect.equality(
    messages[1]:find("CONFLICT (content): merge conflict in foo.txt", 1, true) ~= nil,
    true
  )
  MiniTest.expect.equality(cmds, {
    "DiffviewOpen older789^..older789",
    "DiffviewOpen newer123^..newer123",
  })
end

T["actions"]["show_selected() uses codediff when configured"] = function()
  local actions = require("gitlogdiff.actions")
  local cmds = capture_cmds()
  require("gitlogdiff").config.viewer = "codediff"

  actions.show_selected({ "abc1234" }, { 1 })
  MiniTest.expect.equality(cmds[1], "CodeDiff abc1234^ abc1234")

  actions.show_selected({ "newer123", "older456" }, { 1, 2 })
  MiniTest.expect.equality(cmds[2], "CodeDiff older456^ newer123")
end

T["actions"]["show_selected() uses codediff for combined diffs too"] = function()
  local actions = require("gitlogdiff.actions")
  local cmds = capture_cmds()
  require("gitlogdiff").config.viewer = "codediff"

  local original_build = actions.build_combined
  actions.build_combined = function()
    return "synth99"
  end

  actions.show_selected({ "newer123", "older789" }, { 1, 3 })
  actions.build_combined = original_build

  MiniTest.expect.equality(cmds[1], "CodeDiff older789^ synth99")
end

T["actions"]["show_selected() notifies when no viewer is available"] = function()
  local actions = require("gitlogdiff.actions")
  local cmds = capture_cmds()
  require("gitlogdiff").config.viewer = "auto" -- neither plugin installed in tests

  local original_notify = vim.notify
  local messages = capture_notify()

  actions.show_selected({ "abc1234" }, { 1 })
  vim.notify = original_notify

  MiniTest.expect.equality(cmds, {})
  MiniTest.expect.equality(messages[1]:find("no diff viewer") ~= nil, true)
end

T["actions"]["viewer=auto detects installed viewers, preferring diffview"] = function()
  local actions = require("gitlogdiff.actions")
  local cmds = capture_cmds()
  require("gitlogdiff").config.viewer = "auto"

  vim.api.nvim_create_user_command("CodeDiff", function() end, { nargs = "*" })
  actions.show_selected({ "abc1234" }, { 1 })
  MiniTest.expect.equality(cmds[1], "CodeDiff abc1234^ abc1234")

  vim.api.nvim_create_user_command("DiffviewOpen", function() end, { nargs = "*" })
  actions.show_selected({ "abc1234" }, { 1 })
  MiniTest.expect.equality(cmds[2], "DiffviewOpen abc1234^..abc1234")

  vim.api.nvim_del_user_command("CodeDiff")
  vim.api.nvim_del_user_command("DiffviewOpen")
end

T["actions"]["build_combined() ignores skipped commits"] = function()
  local repo = make_repo()
  git_commit(repo, "base.txt", "base", "base")
  local c1 = git_commit(repo, "a.txt", "a", "add a")
  git_commit(repo, "b.txt", "b", "add b") -- not selected, must not appear in the diff
  local c3 = git_commit(repo, "c.txt", "c", "add c")

  local synthetic, err = in_repo(repo, function()
    return require("gitlogdiff.actions").build_combined({ c3, c1 })
  end)

  MiniTest.expect.equality(err, nil)
  local files = sh({ "git", "diff", "--name-only", c1 .. "^", synthetic }, repo)
  MiniTest.expect.equality(files, "a.txt\nc.txt")

  -- the temp worktree must be gone
  local worktrees = sh({ "git", "worktree", "list" }, repo)
  MiniTest.expect.equality(worktrees:find("\n"), nil)
end

T["actions"]["build_combined() fails cleanly when a skipped commit conflicts"] = function()
  local repo = make_repo()
  git_commit(repo, "f.txt", "base", "base")
  local c1 = git_commit(repo, "f.txt", "a", "change to a")
  git_commit(repo, "f.txt", "b", "change to b") -- skipped, touches the same line
  local c3 = git_commit(repo, "f.txt", "c", "change to c")

  local synthetic, err = in_repo(repo, function()
    return require("gitlogdiff.actions").build_combined({ c3, c1 })
  end)

  MiniTest.expect.equality(synthetic, nil)
  MiniTest.expect.equality(err ~= nil, true)

  -- no leftover temp worktree, no in-progress cherry-pick
  local worktrees = sh({ "git", "worktree", "list" }, repo)
  MiniTest.expect.equality(worktrees:find("\n"), nil)
  MiniTest.expect.equality(sh({ "git", "status", "--porcelain" }, repo), "")
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

T["log"]["get_commits() warns and returns empty list on git failure"] = function()
  local log = require("gitlogdiff.log")
  local original_system = vim.system
  local original_schedule = vim.schedule
  local original_notify = vim.notify

  vim.schedule = function(fn)
    fn()
  end
  local messages = {}
  vim.notify = function(msg)
    table.insert(messages, msg)
  end
  vim.system = function(_, _, cb)
    cb({ code = 128, stdout = "", stderr = "fatal: not a git repository\n" })
    return {}
  end

  local result = nil
  log.get_commits(function(commits)
    result = commits
  end)

  vim.system = original_system
  vim.schedule = original_schedule
  vim.notify = original_notify

  MiniTest.expect.equality(result, {})
  MiniTest.expect.equality(messages[1], "git log failed: fatal: not a git repository")
end

T["log"]["get_commits() passes max_count to git"] = function()
  require("gitlogdiff").setup({ max_count = 42 })
  local log = require("gitlogdiff.log")
  local original_system = vim.system
  local original_schedule = vim.schedule

  vim.schedule = function(fn)
    fn()
  end
  local seen_args
  vim.system = function(args, _, cb)
    seen_args = args
    cb({ code = 0, stdout = "", stderr = "" })
    return {}
  end

  log.get_commits(function() end)

  vim.system = original_system
  vim.schedule = original_schedule

  MiniTest.expect.equality(vim.tbl_contains(seen_args, "--max-count=42"), true)
end

return T
