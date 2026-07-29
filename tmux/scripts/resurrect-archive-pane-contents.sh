#!/usr/bin/env bash
# tmux-resurrect hook: @resurrect-hook-post-save-all (see tmux.conf).
#
# resurrect writes pane scrollback to a single shared pane_contents.tar.gz,
# overwritten on every save (including continuum's periodic autosave)
# regardless of which manifest generation it belongs to. That silently
# orphans older tmux_resurrect_<ts>.txt manifests from their own scrollback
# the moment a newer save happens - including a later save of a near-empty
# post-crash session, which is exactly what clobbered a real backup once.
#
# Fix: after each save, copy the archive to a name tied to the manifest
# `last` points to right now, so every manifest generation keeps its own
# scrollback permanently instead of sharing one slot.
set -euo pipefail

RESURRECT_SCRIPTS="$HOME/.tmux/plugins/tmux-resurrect/scripts"
source "$RESURRECT_SCRIPTS/variables.sh"
source "$RESURRECT_SCRIPTS/helpers.sh"

dir="$(resurrect_dir)"
archive="$(pane_contents_archive_file)"
[ -f "$archive" ] || exit 0

manifest="$(readlink -f "$(last_resurrect_file)")"
ts="$(basename "$manifest")"
ts="${ts#${RESURRECT_FILE_PREFIX}_}"
ts="${ts%.${RESURRECT_FILE_EXTENSION}}"

cp "$archive" "$dir/pane_contents_${ts}.tar.gz"

# Prune per-generation archives whose manifest has already been rotated out
# by save.sh's own remove_old_backups (which already ran by this point).
shopt -s nullglob
for f in "$dir"/pane_contents_*.tar.gz; do
    fts="$(basename "$f" .tar.gz)"
    fts="${fts#pane_contents_}"
    [ -f "$dir/${RESURRECT_FILE_PREFIX}_${fts}.${RESURRECT_FILE_EXTENSION}" ] || rm -f "$f"
done
