#!/usr/bin/env bash
fatal() {
  local E
  E="${1:-Unknown Error}"
  echo "Error: $E."
  read -r -p "Press any key to return to Alpha-Tmux." -n 1 key
  exit
}

main() {
  local key
  if [[ ! -d "$PROJECTS" ]]; then
    fatal "No \"Projects\" directory specified."
  else
    find "$PROJECTS" -mindepth 1 -maxdepth 1 -type d 
    ITEMC="$(find "$PROJECTS/" -mindepth 1 -maxdepth 1 -type d | wc -l)"
    REPO="$( git info | grep -e "(push)" | awk '{print $2}' )"
    read -rp "Push $ITEMC projects to $REPO? [Y|n]" -n 1 key 
    key="${key:-Y}"
    case "$key" in
      n|N)
        exit ;;
      y|Y)
        while read -r line; do
          echo "LINE: $line"
        done < <(find "$PROJECTS/" -mindepth 1 -maxdepth 1 -type d)
        ;;
      *)
        echo "$key no recognized" 
        exit ;;
    esac
  fi
}
main
