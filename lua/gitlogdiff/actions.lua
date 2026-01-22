local M = {}

local function diffview_open(args)
  vim.cmd("DiffviewOpen " .. table.concat(args, " "))
end

function M.show_selected(hashes, _)
  if #hashes == 0 then
    vim.notify("No commits selected", vim.log.levels.INFO)
    return
  end

  if #hashes == 1 then
    diffview_open({ hashes[1] .. "^.." .. hashes[1] })
  else
    diffview_open({ hashes[#hashes] .. "^.." .. hashes[1] })
  end
end

return M
