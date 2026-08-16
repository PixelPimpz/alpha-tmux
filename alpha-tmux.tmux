#!/usr/bin/env bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TMUX_CONF=""
for loc in "$HOME/.tmux.conf" "$HOME/.config/tmux/tmux.conf" "$HOME/.config/tmux.conf"; do
  [[ -f "$loc" ]] && { TMUX_CONF="$loc"; break; }
done

tmux set-env -g TMUX_CONFIG "${TMUX_CONF:-$HOME/.tmux.conf}"
tmux set-env -g DOTFILES "$HOME/dotfiles"
tmux set-env -g ACTIONS "$CURRENT_DIR/scripts/actions"
tmux set-hook -g session-created "send-keys -t :0.0 '$CURRENT_DIR/scripts/io-loop.sh' C-m"
tmux bind-key c new-window -n "Alpha-Tmux" "$CURRENT_DIR/scripts/io-loop.sh"
