#!/usr/bin/env bash
[[ -n "$_ALPHA_YQTOOLS_SH" ]] && return 0
_ALPHA_YQTOOLS_SH=1

source "$PLUGIN_ROOT/scripts/utils/errors.sh"
source "$PLUGIN_ROOT/scripts/utils/colorizer.sh"

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
  local KEY="$1" max="${2:-0}"
  local name icon key comm glyph
  IFS="|" read -r name icon key comm < <(get_button "$KEY")
  glyph="$(get_icon "$icon")"

  printf "%s %s  %s%-${max}s  %s[%s%s%s] %s" \
  "$BUTTON_BGC" \
  "$ICONC$glyph" \
  "$TEXTC" \
  "$name" \
  "$BRACKETC" \
  "$KEYC" "$key" "$BRACKETC" \
  "$RESET"
 }

##-------------------------------------------------------
yqshow() {
  local file
  file="$2"
  [[ ! -n "$file" || ! -f "$file" ]]  && fatal "$file not found."
  yq e . "$file"
}


get_icon() {
  local name="$1"
  local glyph
                                                                                                                                                                                                                                                                                  glyph=$(yq e ".icons[] | select(.name == \"$name\") | .glyph" "$PLUGIN_ROOT/lib/icons.yaml")
  case "${#glyph}" in
    "4") echo -e "\u$glyph" ;;
    "5") echo -e "\U$glyph" ;;
    *)   echo "?" ;;
  esac
}
