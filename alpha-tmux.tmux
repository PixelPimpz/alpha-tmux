#!/usr/bin/env bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TMUX_CONF=""
for loc in "$HOME/.tmux.conf" "$HOME/.config/tmux/tmux.conf" "$HOME/.config/tmux.conf"; do
  [[ -f "$loc" ]] && { TMUX_CONF="$loc"; break; }
done

tmux set-env -g TMUX_CONFIG "${TMUX_CONF:-$HOME/.tmux.conf}"
tmux set-env -g DOTFILES "$HOME/dotfiles"
#tmux set-env -g ACTIONS "$CURRENT_DIR/scripts/actions"
tmux set-hook -g session-created "run-shell '$CURRENT_DIR/scripts/hooks/session-created.sh #{session_name}:#{window_index}.#{pane_index}'"
tmux bind-key c new-window -c "#{pane_current_path}" -n "Alpha-Tmux" "$CURRENT_DIR/scripts/io-loop.sh"
