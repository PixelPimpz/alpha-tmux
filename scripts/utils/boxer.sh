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

## GLOBAL ARRAYS
BOX_QUEUE=()
BOX_WIDTHS=()

boxer() {
  local  row_size=1
  if [[ "$1" == "-r" ]]; then
    row_size="${2:-1}"
    shift 2
  fi
  local color="${1:-$BORDERC}"
  local lines=()
  local max_len="${4:-0}" plain len

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

  local title="$3"
  if [[ -n "$title" ]]; then
    local plain_title title_len
    plain_title=$(echo -e "$title" | sed -E 's/\x1b\[[0-9;]*m//g')
    title_len="${#plain_title}"

    # Micro-justification: If button width and title length have opposite parity,
    # absorb the 1-character difference around the separator glyph for optical balance!
    if (( (max_len % 2) != (title_len % 2) )); then
      local glyph_sep
      printf -v glyph_sep "\ue349"
      if [[ "$title" == *"$glyph_sep"* ]]; then
        title="${title/$glyph_sep/ $glyph_sep}"
      else
        title="${title/ /  }"
      fi
      plain_title=$(echo -e "$title" | sed -E 's/\x1b\[[0-9;]*m//g')
      title_len="${#plain_title}"
    fi
    if [[ -z "$4" ]]; then
      (( title_len + 6 > max_len )) && max_len=$(( title_len + 6 ))
      (( (max_len - title_len) % 2 != 0 )) && (( max_len++ ))
    fi
  fi

  LAST_BOX_W="$max_len"
  
  # 3. Build horizontal top and bottom border bars
  local hline
  printf -v hline "%*s" "$((max_len + 2))" ""
  hline="${hline// /─}"
  
  local cur_box=()
  
  # 4. Print top border (Centered title with matching left & right dashes)
  if [[ -n "$title" ]]; then
    local total_dashes=$(( max_len + 2 - title_len - 2 ))
    local left_w=$(( total_dashes / 2 ))
    local right_w=$(( total_dashes - left_w ))
    local left_bar right_bar
    printf -v left_bar "%*s" "$left_w" ""
    printf -v right_bar "%*s" "$right_w" ""
    cur_box+=("${color}╭${left_bar// /─} ${title} ${color}${right_bar// /─}╮${RESET}")
  else
    cur_box+=("${color}╭${hline}╮${RESET}")
  fi

  # 5. Print rows with side borders and centered content padding
  for line in "${lines[@]}"; do
    plain=$(echo -e "$line" | sed -E 's/\x1b\[[0-9;]*m//g')
    local diff=$(( max_len - ${#plain} ))
    local pad_l=$(( diff / 2 ))
    local pad_r=$(( diff - pad_l ))
    local pl="" pr=""
    (( pad_l > 0 )) && printf -v pl "%*s" "$pad_l" ""
    (( pad_r > 0 )) && printf -v pr "%*s" "$pad_r" ""
    cur_box+=("${color}│${RESET} ${pl}${line}${pr} ${color}│${RESET}")
  done

  # 6. Print bottom border
  cur_box+=("${color}╰${hline}╯${RESET}")

  # 7. Print single box immediately, or queue for multi-box row
  if (( row_size <= 1 )); then
    for line in "${cur_box[@]}"; do
      center "$line"
    done
  else
    BOX_QUEUE+=("$(printf "%s\n" "${cur_box[@]}")")
    BOX_WIDTHS+=("$(( max_len + 4 ))")
    (( ${#BOX_QUEUE[@]} >= row_size )) && flush_boxes
  fi
}
flush_boxes() {
  local b r max_h=0 b_lines row_str cell

  for b in "${!BOX_QUEUE[@]}"; do
    mapfile -t b_lines <<< "${BOX_QUEUE[$b]}"
    (( ${#b_lines[@]} > max_h )) && max_h="${#b_lines[@]}"
  done

  for (( r = 0; r < max_h; r++ )); do
    row_str=""
    for b in "${!BOX_QUEUE[@]}"; do
      mapfile -t b_lines <<< "${BOX_QUEUE[$b]}"
      if [[ -n "${b_lines[$r]}" ]]; then
        cell="${b_lines[$r]}"
      else
        printf -v cell "%*s" "${BOX_WIDTHS[$b]}" ""
      fi
      (( b > 0 )) && row_str+="  "
      row_str+="$cell"
    done
    center "$row_str"
  done

    BOX_QUEUE=()
    BOX_WIDTHS=()
}
