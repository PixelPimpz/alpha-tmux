#!/usr/bin/env bash
# shellcheck disable=SC2178
[[ -n $_ALPHA_STACK_SH ]] && return 0
_ALPHA_STACK_SH=1

Stack_push() {
  local -n __stack="$1"
  local __item="$2"
  __stack+=("$__item")
  return 0
}

Stack_pop() {
  local -n __stack="$1"
  local -n __out_var="$2"
  if (( ${#__stack[@]} == 0 )); then
    __out_var=""
    return 1
    fi
  __out_var="${__stack[-1]}"
  unset '__stack[-1]' #modifies the Stack
  return 0
}

Stack_peek() {
  local -n __stack="$1"
  local -n __out_var="$2"
  if (( ${#__stack[@]} == 0 )); then
    __out_var=""
  else
    __out_var="${__stack[-1]}"
  fi
  return 0
}

Stack_size() {
  local -n __stack="$1"
  local -n __out_var="$2"
  __out_var="${#__stack[@]}"
  return 0
}

is_empty(){
  local -n __stack="$1"
  local bool=0
  (( "${#__stack[@]}" == 0 )) && bool=1
  echo "$bool"
}

Stack_clear() {
  local -n __stack="$1"
  if (( ${#__stack[@]} > 0 )); then
    __stack=()
  fi
  return 0
}

Stack_join() {
  local -n __stack="$1"
  local -n __out_var="$2"
  local d delim
  printf -v d " \ue349 "
  delim="${3:-$d}"
  local out="" item
  for item in "${__stack[@]}"; do
    [[ -z "$out" ]] && out="$item" || out="${out}${delim}${item}"
  done
  __out_var="$out"
}

































































































































































































































