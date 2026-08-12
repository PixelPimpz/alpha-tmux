#!/usr/bin/env bash
fatal() {
  local E
  E="${1:-Unknown Error}"
  echo "Error: $E."
  read -r -p "Press any key to return to Alpha-Tmux." -n 1 key
  exit
}

if [[ ! -d "$PROJECTS" ]]; then
  fatal "No \"Projects\" directory specified."
else
  ls -1 "$PROJECTS/"
  ITEMC="$(find "$PROJECTS/" -type d | wc -l)"
  REPO="$( git info | grep -e "(push)" | awk '{print $2}' )"
  read -rp "Push $ITEMC projects to $REPO? [Y|n]" -n 1 key 
  case "$key" in
    [nN])
      exit ;;
    [yY])
      while read -r line; do
        echo "LINE: $line"
      done < <(find "$PROJECTS/" -type d)
      ;;
    *)
      echo "$key no recognized" 
      exit ;;
  esac
fi
