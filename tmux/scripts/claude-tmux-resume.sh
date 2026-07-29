#!/usr/bin/env bash
# tmux-resurrect restore target for `claude` panes (see @resurrect-processes
# in tmux.conf). Resumes the exact session that was running in this specific
# pane, using the coord->session-id map written by the `claude` shell
# function in claude-track.bash at launch time. Falls back to --continue
# (most recent session in this directory) if no map entry exists yet, e.g.
# a pane whose claude process hasn't been (re)launched since tracking was set
# up.
coord="$(tmux display-message -p '#S:#I.#P' 2>/dev/null)"
map_file="$HOME/.local/state/claude-tmux-sessions/$(printf '%s' "$coord" | tr ':.' '__')"

if [ -f "$map_file" ]; then
    exec claude --resume "$(cat "$map_file")"
else
    exec claude --continue
fi
