# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

This is the Neovim configuration, managed as part of a chezmoi dotfiles repo (see root `.claude/CLAUDE.md` for chezmoi conventions). The `exact_` prefix on this directory means chezmoi will delete any files in `~/.config/nvim` that aren't tracked here.

## Structure

```
init.lua                  # Entry point — sets leader keys, loads config modules
exact_lua/
  exact_config/
    lazy.lua              # Lazy.nvim bootstrap + setup
    settings.lua          # Editor options and Neovide GUI config
    keymaps.lua           # Global keymaps (window nav, Mac shortcuts)
    autocmds.lua          # Global autocmds (yank highlight)
  exact_plugins/          # One file per plugin concern, all loaded by lazy.nvim
```

Leader key is `<Space>`, local leader is also `<Space>`. These are set in `init.lua` **before** lazy loads (required for correct keymap registration).

## Plugin System

[Lazy.nvim](https://github.com/folke/lazy.nvim) is the plugin manager, bootstrapped in `lazy.lua` (clones from stable branch if not present). It auto-discovers all files under `exact_plugins/` via `{ import = "plugins" }`.

**Adding a plugin:** Create a new file in `exact_plugins/` or add to `misc.lua`. Each file returns a table (or array of tables) matching lazy's plugin spec.

**Common patterns:**
- `opts = {}` — passed directly to `plugin.setup()`; use for simple config
- `config = function() ... end` — use when setup needs logic or ordering
- `keys = { ... }` — lazy-loads the plugin on first keypress
- `event = "VeryLazy"` — defers load until after UI is ready
- `lazy = false` + `priority = 1000` — force early load (colorscheme, snacks)

## Key Plugin Responsibilities

| File | Plugin(s) | Role |
|------|-----------|------|
| `lsp.lua` | nvim-lspconfig, mason, mason-lspconfig | Language servers + installer |
| `completion.lua` | blink.cmp | Completion (LSP + path + snippets, supertab) |
| `fzf.lua` | fzf-lua | Fuzzy finding for files, LSP ops, grep |
| `treesitter.lua` | nvim-treesitter | Syntax, indentation, folding |
| `git.lua` | gitsigns, neogit | Hunk ops, blame, diffs |
| `mini.lua` | mini.nvim suite | Text objects, autopairs, surround, statusline, icons, etc. |
| `snacks.lua` | snacks.nvim | Picker (with frecency) + LSP progress notifications |
| `colorscheme.lua` | kanagawa | Active theme; others defined but commented out |
| `misc.lua` | uv.nvim, chezmoi.nvim | Python uv support; chezmoi file picker |
| `yazi.lua` | yazi.nvim | File browser (`\` at file, `<leader>\` at CWD); replaces netrw |
| `dap.lua` | nvim-dap | Debugger — loaded but **not yet configured** |
| `molten.lua` | molten-nvim | Jupyter integration — **currently disabled** (empty return) |
| `noice.lua` | noice.nvim | Enhanced UI — **currently disabled** (all commented out) |

## Language Servers (mason-managed)

| Server | Language | Notes |
|--------|----------|-------|
| `lua-language-server` | Lua | |
| `rust-analyzer` | Rust | Managed via rustaceanvim, not lspconfig directly |
| `pyrefly` | Python | Type checking; hover disabled (conflicts with ruff) |
| `ruff` | Python | Linting + formatting; formatting capability disabled |
| `codelldb` | Rust/C++ | Debug adapter; installed but DAP not configured yet |

## Keymap Reference

**LSP** (via fzf-lua, `gr` prefix — matches Neovim 0.11 defaults):
`gra` code actions · `grn` rename · `grr` references · `grd` definition · `gri` implementations · `grt` type def · `gO` doc symbols · `gW` workspace symbols

**Find** (`<leader>f` prefix):
`ff` files · `fb` buffers · `f.` recent · `f/` live grep · `fc` chezmoi configs · `fn` nvim config · `fh` help · `fk` keymaps

**Git** (`<leader>h` prefix, gitsigns):
`]c`/`[c` next/prev hunk · `hs` stage · `hr` reset · `hb` blame · `hd` diff · `hp` preview

**Navigation:**
`<C-h/j/k/l>` window splits · `\` yazi at file · `<leader>z` zoxide jump

## Testing Config Changes

There's no hot-reload mechanism. Workflow:
- **Single file:** `:luafile %` to re-source the current buffer
- **Plugin changes:** `:Lazy reload <plugin-name>` or restart nvim
- **Full reload:** Restart nvim (changes are picked up fresh)

Chezmoi: after editing files here, run `chezmoi apply` to deploy to `~/.config/nvim`. Or use `chezmoi edit` to edit + auto-apply.
