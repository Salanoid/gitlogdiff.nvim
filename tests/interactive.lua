-- Interactive sandbox for manual testing, isolated from your own config:
--
--   cd <any git repo> && nvim -u /path/to/gitlogdiff.nvim/tests/interactive.lua
--
-- Then run :GitLogDiff.

local here = debug.getinfo(1, "S").source:sub(2)
local plugin_dir = vim.fs.dirname(vim.fs.dirname(here))

vim.env.LAZY_STDPATH = plugin_dir .. "/.tests"
vim.env.LAZY_PATH = vim.fs.normalize("~/projects/lazy.nvim")

if vim.fn.isdirectory(vim.env.LAZY_PATH) == 1 then
  loadfile(vim.env.LAZY_PATH .. "/bootstrap.lua")()
else
  load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"), "bootstrap.lua")()
end

require("lazy.minit").setup({
  spec = {
    {
      dir = plugin_dir,
      main = "gitlogdiff",
      dependencies = { "sindrets/diffview.nvim" },
      opts = {},
    },
  },
})
