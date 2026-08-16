#!/usr/bin/env bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tmux set-env -g TMUX_CONFIG = "$HOME/.config/tmux/tmux.conf" # I would prefer that this be discovered with find
tmux set-env -g DOTFILES "$HOME/dotfiles"
tmux set-env -g ACTIONS "$CURRENT_DIR/scripts/actions"
tmux set-hook -g session-created "send-keys -t :0.0 '$CURRENT_DIR/scripts/io-loop.sh' C-m"
tmux bind-key c new-window -n "Alpha-Tmux" "$CURRENT_DIR/scripts/io-loop.sh"
