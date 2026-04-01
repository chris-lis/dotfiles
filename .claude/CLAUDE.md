# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A [chezmoi](https://www.chezmoi.io/) dotfiles repository managing macOS development configuration: Zsh, Neovim, Git, GPG/YubiKey, and Ghostty terminal.

The Neovim config (`dot_config/exact_nvim/`) is a semi-independent sub-project with its own `.claude/CLAUDE.md` covering nvim-specific architecture and workflows.

## Common Commands

```bash
chezmoi apply           # Apply all dotfiles to home directory
chezmoi diff            # Preview what would change
chezmoi add ~/.file     # Start managing a new dotfile
chezmoi edit ~/.zshrc   # Edit a managed file (auto-applies on save)
chezmoi apply --force   # Force re-run of on-change scripts
chezmoi update          # Pull from remote and apply
```

## File Naming Conventions

| Prefix/Suffix | Effect |
|---------------|--------|
| `dot_` | Becomes `.` in home dir (`dot_zshrc` → `~/.zshrc`) |
| `private_` | Deployed with mode 600 (secrets, sensitive configs) |
| `exact_` | Chezmoi removes any files in the target dir not tracked here |
| `.tmpl` suffix | Processed as Go templates |
| `run_once_` | Script runs once on first apply |
| `run_onchange_` | Script re-runs when content or template inputs change |

## Template System

`.chezmoi.toml.tmpl` prompts for:
- `env`: `"personal"` or `"perceptive-space"` (work)
- `git.email`: injected into `dot_config/git/config.tmpl`

Use `{{ .git.email }}`, `{{ .env }}`, etc. in any `.tmpl` file.

The GPG import script uses chezmoi's `include` + hashing to trigger re-runs when key backup files change.

## Dotfile Areas

### Shell (`dot_zshrc`, `private_dot_zshenv`)
- Built on [zsh4humans](https://github.com/romkatv/zsh4humans) (`z4h`) framework with Powerlevel10k (`dot_p10k.zsh`)
- Key tools: fzf, zoxide, thefuck, conda, Cloudflare WARP aliases

### Git (`dot_config/git/`)
- `config.tmpl` — templated email; GPG signing key `521F2340A0596487!`; all commits/tags signed

### GPG / YubiKey (`private_dot_gnupg/`, `.chezmoiscripts/`)
- Smart card via `scdaemon.conf`; SSH via GPG agent
- macOS LaunchAgents in `private_Library/LaunchAgents/` load the agent on login
- `run_once_after_load-gpg-agent-plist.darwin.sh` registers plists with launchctl (macOS only)

### Platform Conditionals
- `.chezmoiignore` excludes macOS-specific files on non-darwin systems
- Scripts scoped to macOS use the `.darwin.sh` suffix
