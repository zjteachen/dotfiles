# Sourced from ~/.bashrc.
#
# Records which Claude Code session id gets created in which tmux pane, so
# tmux-resurrect can resume the exact session per pane on restore (see
# claude-tmux-resume.sh) instead of "most recent session in this directory",
# which is ambiguous whenever two panes share a working directory.
#
# Only kicks in for a fresh, argument-less `claude` launch inside tmux; a
# manual `claude --resume/--continue/-p ...` just runs straight through.
claude() {
    if [ -z "${TMUX:-}" ] || [ "$#" -gt 0 ]; then
        command claude "$@"
        return
    fi

    local coord map_dir map_file proj_dir before
    coord="$(tmux display-message -p '#S:#I.#P')"
    map_dir="$HOME/.local/state/claude-tmux-sessions"
    mkdir -p "$map_dir"
    map_file="$map_dir/$(printf '%s' "$coord" | tr ':.' '__')"
    proj_dir="$HOME/.claude/projects/$(pwd | tr '/' '-')"
    before="$(date +%s)"

    (
        for _ in $(seq 1 20); do
            sleep 0.5
            newest="$(find "$proj_dir" -maxdepth 1 -name '*.jsonl' -newermt "@$before" 2>/dev/null | head -1)"
            if [ -n "$newest" ]; then
                basename "$newest" .jsonl > "$map_file"
                break
            fi
        done
    ) >/dev/null 2>&1 &
    disown

    command claude
}
