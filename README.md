# gitlogdiff.nvim

[![CI](https://github.com/Salanoid/gitlogdiff.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/Salanoid/gitlogdiff.nvim/actions/workflows/ci.yml)

A tiny Neovim plugin that shows a simple, keyboard‑driven list of recent Git commits and lets you diff them quickly via Diffview.

Works great for: “show me the last N commits, let me pick one (or two) and open the diff”.

## Features

- Lists recent commits using `git log` (configurable `max_count`)
- Toggle selection with space, navigate with `j/k`
- Press Enter to open diffs in [diffview.nvim]
  - 1 selected commit → diff that commit against its parent (`<hash>^..<hash>`)
  - 2 selected commits → diff between the two commits

## Requirements

- Neovim ≥ 0.10 (uses `vim.system`)
- Git available on your `$PATH`
- Dependencies:
  - [sindrets/diffview.nvim]
  - [folke/snacks.nvim]

## Installation

### lazy.nvim

<!-- suggested:start -->

```lua
{
  "Salanoid/gitlogdiff.nvim",
  main = "gitlogdiff",
  dependencies = {
    "sindrets/diffview.nvim",
    "folke/snacks.nvim",
  },
  cmd = "GitLogDiff",
  opts = { max_count = 300 },
}
```

<!-- suggested:end -->

### packer.nvim

```lua
use({
  "Salanoid/gitlogdiff.nvim",
  requires = {
    "sindrets/diffview.nvim",
    "folke/snacks.nvim",
  },
  config = function()
    require("gitlogdiff").setup({
      max_count = 300,
    })
  end,
})
```

Note: This plugin defines the `:GitLogDiff` command on load. If your plugin manager pre-defines lazy command stubs, `gitlogdiff.nvim` will safely overwrite them (we create the command with `force = true`).

## Usage

- Run `:GitLogDiff` inside a Git repository
- Navigate with `j/k`
- Toggle selection with `<space>`
- Press `<CR>` to open diffs in Diffview
- Press `q` to close the list

## Configuration

```lua
require("gitlogdiff").setup({
  max_count = 300, -- how many commits to list
})
```

## Troubleshooting

- “No git commits found”: you are likely not in a Git repo (or `max_count` is 0)
- “git log failed …”: check that `git` is installed and available in `$PATH`

## Roadmap / Notes

- Currently, selecting two commits diffs A..B. Selecting more than two is not supported and may yield unexpected results.

## License

MIT — see [LICENSE](./LICENSE).

[sindrets/diffview.nvim]: https://github.com/sindrets/diffview.nvim
[folke/snacks.nvim]: https://github.com/folke/snacks.nvim
