local api = vim.api
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

  local width = 90
  local height = math.min(#commits + 2, 30)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  M.state.win = api.nvim_open_win(M.state.buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = "Git Commits",
    title_pos = "center",
  })

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

function M.get_selected_indices()
  local indices = {}
  for i = 1, #M.state.commits do
    if M.state.selected[i] then
      table.insert(indices, i)
    end
  end
  return indices
end

function M.get_selected_hashes()
  local hashes = {}
  local indices = M.get_selected_indices()
  for _, i in ipairs(indices) do
    local h = M.state.commits[i]:match("^(%w+)")
    if h then
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
    local ui = require("gitlogdiff.ui")
    require("gitlogdiff.actions").show_selected(ui.get_selected_hashes(), ui.get_selected_indices())
  end, opts)

  vim.keymap.set("n", "q", function()
    if M.state.win and api.nvim_win_is_valid(M.state.win) then
      api.nvim_win_close(M.state.win, true)
    end
  end, opts)
end

return M
