local M = {}

local function diffview_open(args)
  vim.cmd("DiffviewOpen " .. table.concat(args, " "))
  -- vim.cmd("CodeDiff " .. table.concat(args, " "))
end

function M.show_selected(hashes)
  if #hashes == 0 then
    vim.notify("No commits selected", vim.log.levels.INFO)
    return
  end

  local ordered = vim.deepcopy(hashes)
  table.sort(ordered, function(a, b)
    return a < b
  end)

  if #ordered == 1 then
    diffview_open({ ordered[1] .. "^.." .. ordered[1] })
    return
  end

  diffview_open(ordered)
end

return M
