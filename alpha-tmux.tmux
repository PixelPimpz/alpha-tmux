#!/usr/bin/env bash
 CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
 tmux set-hook -g session-created "sendkeys -t :0.0 '$CURRENT_DIR/scripts/alpha-tmux.sh' C-m"
 tmux bind-key A run-shell "$CURRENT_DIR/scripts/alpha-tmux.sh"
