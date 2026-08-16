#!/usr/bin/env bash
[[ -n "$_ALPHA_BOXER_SH" ]] && return 0
_ALPHA_BOXER_SH=1

source "$PLUGIN_ROOT/scripts/utils/formats.sh"
source "$PLUGIN_ROOT/scripts/utils/colorizer.sh"

## -----------------------------------------------------------------
# BOXER: Universal Unicode box frame renderer.
# Reads multiline input from stdin or argument, pads lines evenly,
# surrounds with Unicode borders (┌ ─ ┐ │ └ ─ ┘), and centers output.
## -----------------------------------------------------------------
boxer() {
  local color="${1:-$BORDERC}"
  local lines=()
  local max_len=0 plain len

  # 1. Read input lines from stdin or argument
  if [[ -n "$2" ]]; then
    while IFS= read -r line; do
      lines+=("$line")
    done <<< "$2"
  else
    while IFS= read -r line; do
      lines+=("$line")
    done
  fi

  [[ "${#lines[@]}" -eq 0 ]] && return

  # 2. Calculate maximum visible text width (ignoring ANSI escape codes)
  for line in "${lines[@]}"; do
    plain=$(echo -e "$line" | sed -E 's/\x1b\[[0-9;]*m//g')
    len="${#plain}"
    (( len > max_len )) && max_len="$len"
  done

  # 3. Build horizontal top and bottom border bars
  local hline
  printf -v hline "%*s" "$((max_len + 2))" ""
  hline="${hline// /─}"

  # 4. Print top border
  center "┌${hline}┐" "$color"

  # 5. Print rows with side borders and right-padding
  for line in "${lines[@]}"; do
    plain=$(echo -e "$line" | sed -E 's/\x1b\[[0-9;]*m//g')
    local pad_spaces=$(( max_len - ${#plain} ))
    local pad=""
    (( pad_spaces > 0 )) && printf -v pad "%*s" "$pad_spaces" ""
    center "${color}│${RESET} ${line}${pad} ${color}│"
  done

  # 6. Print bottom border
  center "└${hline}┘" "$color"
}
