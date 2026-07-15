#!/usr/bin/env bash
# Bootstraps this machine's environment from the files in this repo.
# Safe to re-run: existing real files are backed up once, symlinks are just
# recreated.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

link() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"

    if [ -L "$dst" ]; then
        rm "$dst"
    elif [ -e "$dst" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname "${dst#"$HOME"/}")"
        mv "$dst" "$BACKUP_DIR/${dst#"$HOME"/}"
        echo "Backed up existing $dst -> $BACKUP_DIR/${dst#"$HOME"/}"
    fi

    ln -s "$src" "$dst"
    echo "Linked $dst -> $src"
}

# --- tmux ---
link "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"

# --- claude ---
link "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"

# --- nvim ---
# LazyVim starter provides files we don't customize (README.md, LICENSE,
# .gitignore, lua/config/lazy_bootstrap files etc). Clone it first if the
# config dir doesn't exist yet, then overlay our tracked files on top.
if [ ! -d "$HOME/.config/nvim" ]; then
    echo "Cloning LazyVim starter into ~/.config/nvim"
    git clone --depth 1 https://github.com/LazyVim/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
fi

link "$DOTFILES_DIR/nvim/init.lua" "$HOME/.config/nvim/init.lua"
link "$DOTFILES_DIR/nvim/stylua.toml" "$HOME/.config/nvim/stylua.toml"
link "$DOTFILES_DIR/nvim/neoconf.json" "$HOME/.config/nvim/.neoconf.json"
link "$DOTFILES_DIR/nvim/lazyvim.json" "$HOME/.config/nvim/lazyvim.json"
link "$DOTFILES_DIR/nvim/lazy-lock.json" "$HOME/.config/nvim/lazy-lock.json"
for f in "$DOTFILES_DIR"/nvim/lua/config/*.lua; do
    link "$f" "$HOME/.config/nvim/lua/config/$(basename "$f")"
done
for f in "$DOTFILES_DIR"/nvim/lua/plugins/*.lua; do
    link "$f" "$HOME/.config/nvim/lua/plugins/$(basename "$f")"
done

echo "Done."
