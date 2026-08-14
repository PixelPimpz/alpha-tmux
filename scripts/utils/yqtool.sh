#!/usr/bin/env bash
##-------------------------------------------------------
get_active_theme() {
  local config="$PLUGIN_ROOT/config/settings.yaml"
  yq e '.Profiles[] | select(.status == "active") | .theme' "$config"  
}

##-------------------------------------------------------
## we NEVER call trhis.Instead we just call make_button(KEY)
get_button() {
  local KEY file
  local KEY="$1"
  local file="${2:-$PLUGIN_ROOT/lib/menu-main.yaml}"
  yq e ".Buttons[] | select(.key == \"$KEY\") | [.name, .icon, .key, .comm] | join(\"|\")" "$file"
}

## call THIS and pass the KEY. It will use thr output of 
#  get_button(KEY) for the read command and return the  
#  useable button
make_button() {
  local name icon key KEY comm button
  KEY="$1"
  IFS="|" read -r name icon key comm < <(get_button "$KEY")
  button=("$name" "$icon" "$key" "$comm")
  echo "${button[@]}"
}

##-------------------------------------------------------
get_color() {
  local data 
  THEME="${1:-$PLUGIN_ROOT/themes/gruvbox-alpha-tmux.yaml}"
  "$HEX2ANSI" "$(yq e "$1" "$THEME")"
}

##-------------------------------------------------------
yqshow() {
  local file
  file="$2"
  [[ ! -n "$file" || ! -f "$file" ]]  && fatal "$file not found."
  yq e . "$file"
}
