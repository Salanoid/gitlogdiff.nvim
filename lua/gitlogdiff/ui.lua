local api = vim.api
local snacks = require("snacks")

local M = {}

M.state = {
  buf = nil,
  win = nil,
  commits = {},
  selected = {},
  cursor = 1,
}

function M.open(commits)
  M.state.commits = commits
  M.state.selected = {}
  M.state.cursor = 1

  M.state.buf = api.nvim_create_buf(false, true)
  vim.bo[M.state.buf].buftype = "nofile"
  vim.bo[M.state.buf].bufhidden = "wipe"
  vim.bo[M.state.buf].swapfile = false
  vim.bo[M.state.buf].filetype = "gitlogdiff"

  M.state.win_obj = snacks.win({
    buf = M.state.buf,
    width = 90,
    height = math.min(#commits + 2, 30),
    title = "Git Commits",
    border = "rounded",
  })
  M.state.win = M.state.win_obj.win
  vim.wo[M.state.win].cursorline = true

  M.render()
  M.keymaps()
end

function M.render()
  local lines = {}
  for i, c in ipairs(M.state.commits) do
    local mark = M.state.selected[i] and "●" or "○"
    table.insert(lines, mark .. " " .. c)
  end

  vim.bo[M.state.buf].modifiable = true
  api.nvim_buf_set_lines(M.state.buf, 0, -1, false, lines)
  vim.bo[M.state.buf].modifiable = false
  api.nvim_win_set_cursor(M.state.win, { M.state.cursor, 0 })
end

function M.move(delta)
  M.state.cursor = math.max(1, math.min(#M.state.commits, M.state.cursor + delta))
  M.render()
end

function M.toggle()
  local i = M.state.cursor
  M.state.selected[i] = not M.state.selected[i]
  M.render()
end

function M.get_selected_hashes()
  local hashes = {}
  for i, ok in pairs(M.state.selected) do
    if ok then
      local h = M.state.commits[i]:match("^(%w+)")
      table.insert(hashes, h)
    end
  end
  return hashes
end

function M.keymaps()
  local opts = { buffer = M.state.buf, silent = true }

  vim.keymap.set("n", "j", function()
    M.move(1)
  end, opts)
  vim.keymap.set("n", "k", function()
    M.move(-1)
  end, opts)
  vim.keymap.set("n", "<space>", M.toggle, opts)

  vim.keymap.set("n", "<CR>", function()
    require("gitlogdiff.actions").show_selected(M.get_selected_hashes())
  end, opts)

  vim.keymap.set("n", "q", function()
    M.state.win_obj:close()
  end, opts)
end

return M
