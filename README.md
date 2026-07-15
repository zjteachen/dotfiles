# dotfiles

Personal environment setup: nvim, tmux, claude.

## Usage

```
git clone <this repo> ~/dotfiles
~/dotfiles/install.sh
```

The script symlinks each tracked file into place. Any existing real file at
the destination is backed up once to `~/.dotfiles-backup/<timestamp>/` before
being replaced. Re-running is safe.

## Layout

- `tmux/tmux.conf` -> `~/.tmux.conf`
- `claude/CLAUDE.md` -> `~/.claude/CLAUDE.md` (global instructions)
- `claude/settings.json` -> `~/.claude/settings.json`
- `nvim/` -> `~/.config/nvim/` (LazyVim starter customizations)
  - On a fresh machine with no `~/.config/nvim`, the script clones the
    [LazyVim starter](https://github.com/LazyVim/starter) first, then
    overlays the files tracked here on top of it.

## Adding something new

1. Copy the real file into the matching subdirectory here.
2. Add a `link` call in `install.sh`.
3. Commit.
