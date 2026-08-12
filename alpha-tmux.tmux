#!/usr/bin/env bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tmux set-hook -g session-created "send-keys -t :0.0 '$CURRENT_DIR/scripts/io_loop.sh'"
tmux bind-key A run-shell "$CURRENT_DIR/scripts/io_loop.sh"
tmux set-env -g DOTFILES "$HOME/dotfiles"
