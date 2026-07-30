local M = {}

local function resolve_viewer()
  local viewer = require("gitlogdiff").config.viewer
  if viewer ~= "auto" then
    return viewer
  end
  if vim.fn.exists(":DiffviewOpen") == 2 then
    return "diffview"
  end
  if vim.fn.exists(":CodeDiff") == 2 then
    return "codediff"
  end
  return nil
end

--- Open `from` vs `to` in the configured diff viewer.
local function open_diff(from, to)
  local viewer = resolve_viewer()
  if viewer == "codediff" then
    vim.cmd(("CodeDiff %s %s"):format(from, to))
  elseif viewer == "diffview" then
    vim.cmd(("DiffviewOpen %s..%s"):format(from, to))
  else
    vim.notify("gitlogdiff: no diff viewer found (install diffview.nvim or codediff.nvim)", vim.log.levels.ERROR)
  end
end

local function git(args)
  return vim.system(args, { text = true }):wait()
end

-- Indices come sorted in log order (1 = newest).
local function is_contiguous(indices)
  if #indices < 2 then
    return true
  end
  return indices[#indices] - indices[1] + 1 == #indices
end

--- Combine the selected commits (newest first) into a synthetic commit on top
--- of the oldest one's parent, so diffing base..synthetic shows only their
--- changes — commits between them that were not selected are left out.
--- The synthetic commit becomes unreachable once the temp worktree is removed,
--- but git keeps unreachable objects around long enough for viewing.
---@return string|nil synthetic commit hash, nil if the commits don't apply cleanly
---@return string|nil error output from git
function M.build_combined(hashes)
  local base = hashes[#hashes] .. "^"
  local worktree = vim.fn.tempname()

  local res = git({ "git", "worktree", "add", "--detach", worktree, base })
  if res.code ~= 0 then
    return nil, res.stderr
  end

  local pick = { "git", "-C", worktree, "cherry-pick", "--keep-redundant-commits" }
  for i = #hashes, 1, -1 do
    table.insert(pick, hashes[i])
  end
  res = git(pick)

  local synthetic, err
  if res.code == 0 then
    synthetic = vim.trim(git({ "git", "-C", worktree, "rev-parse", "HEAD" }).stdout)
  else
    err = res.stderr
    git({ "git", "-C", worktree, "cherry-pick", "--abort" })
  end
  git({ "git", "worktree", "remove", "--force", worktree })

  return synthetic, err
end

local function show_combined(hashes)
  local base = hashes[#hashes] .. "^"
  local synthetic, err = M.build_combined(hashes)
  if synthetic then
    open_diff(base, synthetic)
    return
  end

  local msg = "Selected commits conflict with skipped ones; opening one diff per commit instead"
  if err and err ~= "" then
    msg = msg .. "\n" .. vim.trim(err)
  end
  vim.notify(msg, vim.log.levels.WARN)
  for i = #hashes, 1, -1 do
    open_diff(hashes[i] .. "^", hashes[i])
  end
end

function M.show_selected(hashes, indices)
  if #hashes == 0 then
    vim.notify("No commits selected", vim.log.levels.INFO)
    return
  end

  if #hashes == 1 then
    open_diff(hashes[1] .. "^", hashes[1])
  elseif is_contiguous(indices) then
    open_diff(hashes[#hashes] .. "^", hashes[1])
  else
    show_combined(hashes)
  end
end

return M
