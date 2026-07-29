#!/usr/bin/env bash
# tmux-resurrect hook: @resurrect-hook-pre-restore-all (see tmux.conf).
#
# restore.sh always reads the single shared pane_contents.tar.gz regardless
# of which manifest generation `last` points to. Pairs with
# resurrect-archive-pane-contents.sh: before restore runs, swap in the
# archive tied to the manifest actually being restored, so scrollback
# matches the layout instead of whatever the most recent save happened to
# capture.
#
# No-op for manifests saved before this hook existed (no per-generation
# archive to find) - restore just falls back to whatever is already in the
# shared file.
set -euo pipefail

RESURRECT_SCRIPTS="$HOME/.tmux/plugins/tmux-resurrect/scripts"
source "$RESURRECT_SCRIPTS/variables.sh"
source "$RESURRECT_SCRIPTS/helpers.sh"

dir="$(resurrect_dir)"
manifest="$(readlink -f "$(last_resurrect_file)")"
ts="$(basename "$manifest")"
ts="${ts#${RESURRECT_FILE_PREFIX}_}"
ts="${ts%.${RESURRECT_FILE_EXTENSION}}"

archive="$dir/pane_contents_${ts}.tar.gz"
[ -f "$archive" ] || exit 0
cp "$archive" "$(pane_contents_archive_file)"
