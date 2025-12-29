local T = MiniTest.new_set()

package.loaded["snacks"] = {
  win = function(opts)
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, opts.buf)
    return {
      win = win,
      close = function() end,
    }
  end,
}

T.before_each = function()
  package.loaded["gitlogdiff.ui"] = nil
end

T.after_each = function()
end

T["move() updates cursor"] = function()
  local ui = require("gitlogdiff.ui")
  ui.open({ "hash1 commit1", "hash2 commit2", "hash3 commit3" })
  MiniTest.expect.equality(ui.state.cursor, 1)

  ui.move(1)
  MiniTest.expect.equality(ui.state.cursor, 2)

  ui.move(1)
  MiniTest.expect.equality(ui.state.cursor, 3)

  ui.move(1)
  MiniTest.expect.equality(ui.state.cursor, 3)

  ui.move(-1)
  MiniTest.expect.equality(ui.state.cursor, 2)
end

T["toggle() updates selection"] = function()
  local ui = require("gitlogdiff.ui")
  ui.open({ "hash1 commit1", "hash2 commit2" })
  MiniTest.expect.equality(ui.state.selected[1], nil)

  ui.toggle()
  MiniTest.expect.equality(ui.state.selected[1], true)

  ui.toggle()
  MiniTest.expect.equality(ui.state.selected[1], false)
end

T["get_selected_hashes() works"] = function()
  local ui = require("gitlogdiff.ui")
  ui.open({ "abc1234 commit1", "def5678 commit2", "ghi9012 commit3" })
  ui.state.selected[1] = true
  ui.state.selected[3] = true

  local hashes = ui.get_selected_hashes()
  table.sort(hashes)
  MiniTest.expect.equality(hashes, { "abc1234", "ghi9012" })
end

return T
