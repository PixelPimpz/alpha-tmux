#!/usr/bin/env bash
fatal() {
  local m="$1"
  printf "FATAL: %s\n" "$m"
  exit 1
}

main() {
  [[ ! -d "./.git" ]] && fatal "$(printf "%s is not a valid git-managed directory.\n" "$PWD")"
  local now
  now="$(date)"
  git add .
  git commit -m "Routine push: ${now}" 
  git push origin main
}
main
