#!/usr/bin/env bash
tmux display-popup -E | source $TMUX_CONFIG; echo 'tmux.conf reloaded...'
sleep 5
