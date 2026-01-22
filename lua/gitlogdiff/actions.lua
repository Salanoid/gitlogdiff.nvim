local M = {}

local function diffview_open(args)
  vim.cmd("DiffviewOpen " .. table.concat(args, " "))
end

local function diffview_history(args)
  vim.cmd("DiffviewFileHistory " .. table.concat(args, " "))
end

function M.show_selected(hashes, indices)
  if #hashes == 0 then
    vim.notify("No commits selected", vim.log.levels.INFO)
    return
  end

  local is_consecutive = true
  if #indices > 1 then
    for i = 2, #indices do
      if indices[i] ~= indices[i - 1] + 1 then
        is_consecutive = false
        break
      end
    end
  end

  if is_consecutive then
    if #hashes == 1 then
      diffview_open({ hashes[1] .. "^.." .. hashes[1] })
    else
      diffview_open({ hashes[#hashes] .. "^.." .. hashes[1] })
    end
  else
    local args = { "--no-walk" }
    for _, h in ipairs(hashes) do
      table.insert(args, h)
    end
    diffview_history(args)
  end
end

return M
