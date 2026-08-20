#!/usr/bin/env bash
tmux display-popup | source $TMUX_CONFIG; echo 'tmux.conf reloaded...'
sleep 3000
tmux display-popup -C
