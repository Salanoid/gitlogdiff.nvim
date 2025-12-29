local Docs = require("lazy.docs")

local M = {}

function M.suggested()
  return {
    "Salanoid/gitlogdiff.nvim",
    main = "gitlogdiff",
    dependencies = {
      "sindrets/diffview.nvim",
      "folke/snacks.nvim",
    },
    cmd = "GitLogDiff",
    opts = { max_count = 300 },
  }
end

function M.update()
  local name = "gitlogdiff"

  -- Update README.md
  Docs.save({
    suggested = {
      content = [[{
  "Salanoid/gitlogdiff.nvim",
  main = "gitlogdiff",
  dependencies = {
    "sindrets/diffview.nvim",
    "folke/snacks.nvim",
  },
  cmd = "GitLogDiff",
  opts = { max_count = 300 },
}]],
      lang = "lua",
    },
  })

  -- Generate Vimdocs
  local readme = vim.fn.readfile("README.md")
  local lines = {}

  table.insert(lines, "*" .. name .. ".txt*  Recent Git commits and diffs")
  table.insert(lines, "")
  table.insert(lines, "==============================================================================")
  table.insert(lines, "INTRODUCTION                                         *" .. name .. "-intro*")
  table.insert(lines, "")

  local in_code_block = false
  for _, line in ipairs(readme) do
    if line:find("^<!%-%-") then
      -- Skip HTML comments
    elseif line:find("^```") then
      in_code_block = not in_code_block
      table.insert(lines, in_code_block and ">" or "<")
    elseif line:find("^%s*# ") then
      -- Skip
    elseif line:find("^%s*%[!%[") then
      -- Skip badges
    elseif line:find("^## ") then
      local title = line:match("^## (.*)")
      local tag = "*" .. name .. "-" .. title:lower():gsub("[%s/]+", "-"):gsub("%-+$", "") .. "*"
      table.insert(lines, "")
      table.insert(lines, "==============================================================================")
      table.insert(lines, title:upper() .. string.rep(" ", 78 - #title - #tag) .. tag)
      table.insert(lines, "")
    elseif line:find("^### ") then
      local title = line:match("^### (.*)")
      local tag = "*" .. name .. "-" .. title:lower():gsub("[%s/]+", "-"):gsub("%-+$", "") .. "*"
      table.insert(lines, "")
      table.insert(lines, title .. string.rep(" ", 78 - #title - #tag) .. tag)
      table.insert(lines, "")
    else
      if not in_code_block then
        line = line:gsub("%%", "%%%%")
        line = line:gsub("%[(.-)%]%(.-%)", "%1")
        line = line:gsub("%[(.-)%]", "%1")
        line = line:gsub("`(.-)`", "%1")
      end
      table.insert(lines, line)
    end
  end

  table.insert(lines, "")
  table.insert(lines, " vim:tw=78:ts=8:ft=help:norl:")

  vim.fn.mkdir("doc", "p")
  vim.fn.writefile(lines, "doc/" .. name .. ".txt")
end

M.update()

return M
