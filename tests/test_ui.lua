local api = vim.api

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      package.loaded["gitlogdiff.ui"] = nil
    end,
    post_case = function()
      local ui = package.loaded["gitlogdiff.ui"]
      if ui and ui.state.win and api.nvim_win_is_valid(ui.state.win) then
        api.nvim_win_close(ui.state.win, true)
      end
    end,
  },
})

local function feed(keys)
  api.nvim_feedkeys(api.nvim_replace_termcodes(keys, true, false, true), "x", false)
end

T["open() shows commits in a floating window"] = function()
  local ui = require("gitlogdiff.ui")
  ui.open({ "hash1 commit1", "hash2 commit2" })

  MiniTest.expect.equality(api.nvim_win_is_valid(ui.state.win), true)
  MiniTest.expect.equality(api.nvim_win_get_config(ui.state.win).relative, "editor")
  MiniTest.expect.equality(vim.bo[ui.state.buf].filetype, "gitlogdiff")
  MiniTest.expect.equality(vim.bo[ui.state.buf].modifiable, false)
  MiniTest.expect.equality(api.nvim_buf_get_lines(ui.state.buf, 0, -1, false), {
    "○ hash1 commit1",
    "○ hash2 commit2",
  })
end

T["open() resets selection state"] = function()
  local ui = require("gitlogdiff.ui")
  ui.open({ "hash1 commit1", "hash2 commit2" })
  ui.toggle()
  ui.move(1)

  ui.open({ "hash1 commit1", "hash2 commit2" })
  MiniTest.expect.equality(ui.get_selected_indices(), {})
  MiniTest.expect.equality(ui.state.cursor, 1)
end

T["move() updates cursor and clamps at both ends"] = function()
  local ui = require("gitlogdiff.ui")
  ui.open({ "hash1 commit1", "hash2 commit2", "hash3 commit3" })
  MiniTest.expect.equality(ui.state.cursor, 1)

  ui.move(-1)
  MiniTest.expect.equality(ui.state.cursor, 1)

  ui.move(1)
  MiniTest.expect.equality(ui.state.cursor, 2)

  ui.move(1)
  ui.move(1)
  MiniTest.expect.equality(ui.state.cursor, 3)

  ui.move(-1)
  MiniTest.expect.equality(ui.state.cursor, 2)
end

T["toggle() updates selection and rendered marks"] = function()
  local ui = require("gitlogdiff.ui")
  ui.open({ "hash1 commit1", "hash2 commit2" })
  MiniTest.expect.equality(ui.state.selected[1], nil)

  ui.toggle()
  MiniTest.expect.equality(ui.state.selected[1], true)
  local lines = api.nvim_buf_get_lines(ui.state.buf, 0, -1, false)
  MiniTest.expect.equality(lines[1], "● hash1 commit1")
  MiniTest.expect.equality(lines[2], "○ hash2 commit2")

  ui.toggle()
  MiniTest.expect.equality(ui.state.selected[1], false)
  lines = api.nvim_buf_get_lines(ui.state.buf, 0, -1, false)
  MiniTest.expect.equality(lines[1], "○ hash1 commit1")
end

T["get_selected_hashes() works"] = function()
  local ui = require("gitlogdiff.ui")
  ui.open({ "abc1234 commit1", "def5678 commit2", "ghi9012 commit3" })
  ui.state.selected[1] = true
  ui.state.selected[3] = true

  local hashes = ui.get_selected_hashes()
  MiniTest.expect.equality(hashes, { "abc1234", "ghi9012" })
end

T["get_selected_indices() works"] = function()
  local ui = require("gitlogdiff.ui")
  ui.open({ "abc1234 commit1", "def5678 commit2", "ghi9012 commit3" })
  ui.state.selected[1] = true
  ui.state.selected[3] = true

  local indices = ui.get_selected_indices()
  MiniTest.expect.equality(indices, { 1, 3 })
end

T["keymaps"] = MiniTest.new_set()

T["keymaps"]["j/k move the cursor"] = function()
  local ui = require("gitlogdiff.ui")
  ui.open({ "hash1 commit1", "hash2 commit2", "hash3 commit3" })

  feed("j")
  MiniTest.expect.equality(ui.state.cursor, 2)
  feed("j")
  MiniTest.expect.equality(ui.state.cursor, 3)
  feed("k")
  MiniTest.expect.equality(ui.state.cursor, 2)
end

T["keymaps"]["<space> toggles selection under the cursor"] = function()
  local ui = require("gitlogdiff.ui")
  ui.open({ "hash1 commit1", "hash2 commit2" })

  feed(" ")
  MiniTest.expect.equality(ui.state.selected[1], true)
  feed(" ")
  MiniTest.expect.equality(ui.state.selected[1], false)
end

T["keymaps"]["<CR> passes selected hashes and indices to actions"] = function()
  local ui = require("gitlogdiff.ui")
  ui.open({ "abc1234 commit1", "def5678 commit2", "ghi9012 commit3" })

  local original_actions = package.loaded["gitlogdiff.actions"]
  local got_hashes, got_indices
  package.loaded["gitlogdiff.actions"] = {
    show_selected = function(hashes, indices)
      got_hashes, got_indices = hashes, indices
    end,
  }

  feed(" jj ") -- select line 1, move to line 3, select it
  feed("<CR>")
  package.loaded["gitlogdiff.actions"] = original_actions

  MiniTest.expect.equality(got_hashes, { "abc1234", "ghi9012" })
  MiniTest.expect.equality(got_indices, { 1, 3 })
end

T["keymaps"]["q closes the window"] = function()
  local ui = require("gitlogdiff.ui")
  ui.open({ "hash1 commit1" })
  local win = ui.state.win

  feed("q")
  MiniTest.expect.equality(api.nvim_win_is_valid(win), false)
end

return T
