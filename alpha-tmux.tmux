#!/usr/bin/env bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tmux set-env -g DOTFILES "$HOME/dotfiles"
tmux set-env ACTIONS "$CURRENT_DIR/scripts/actioons"
tmux set-hook -g session-created "send-keys -t :0.0 '$CURRENT_DIR/scripts/io-loop.sh' C-m"
tmux bind-key c new-window -n "Alpha-Tmux" "$CURRENT_DIR/scripts/io-loop.sh"
