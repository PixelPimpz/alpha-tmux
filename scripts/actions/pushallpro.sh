#!/usr/bin/env bash
ls -1 "$TMUX_PLUGIN_MANAGER_PATH/"
ITEMC="$(find "$TMUX_PLUGIN_MANAGER_PATH/" -type d | wc -l)"
REPO="$( git info | grep -e "(push)" | awk '{print $2}' )"
read -rp "Push $ITEMC projects to $REPO? [Y|n]" -n 1 key 
case "$key" in
  [nN])
    exit ;;
  [yY])
    while read -r line; do
      echo "$line"
    done
    ;;
  *)
    echo "$key no recognized" 
    exit ;;
esac
