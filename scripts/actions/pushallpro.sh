#!/usr/bin/env bash
fatal() {
  local 
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
    read -rp "Push $ITEMC projects? [Y|n]" -n 1 key 
    key="${key:-Y}"
    case "$key" in
      n|N)
        exit ;;
      y|Y)
        while read -r line; do
          ( cd "$line" && push )
        done < <(find "$PROJECTS/" -mindepth 1 -maxdepth 1 -type d)
        echo "All projects are pushed to GitHub."
        read -rp "Press any key to return to Alpha-Tmux" -n 1 key
        exit
        ;;
      *)
        echo "$key no recognized" 
        exit ;;
    esac
  fi
}
main
