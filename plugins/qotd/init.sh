#!/usr/bin/env bash
[[ -n "$_ALPHA_QOTD_SH" ]] && return 0
_ALPHA_QOTD_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"

source "$UTILS/formats.sh"
source "$UTILS/colorizer.sh"
source "$UTILS/plugtools.sh"
source "$UTILS/boxer.sh"
source "$UTILS/icons.sh"

qotd_dharma() {
  local picked cache_f fallback
  fallback="The first Noble Truth: All life is suffering."
  cache_f="$A_CACHE/${FUNCNAME[0]}_$(date +%Y%m%d).txt"
  if [[ -s "$cache_f" ]]; then 
    cat "$cache_f"
    return 0
  else
    mkdir -p "$A_CACHE"
    picked="$(  curl -sf --max-time 2 "https://suttacentral.net/api/epigraphs" | yq_each ".[].epigraph" | shuf -n 1)"
  fi
  printf "%s\n" "${picked:-$fallback}" > "$cache_f"
  cat "$cache_f"
}

qotd_newage() {
  local n_mass=(
    "consciousness" "nature" "beauty" "knowledge" "truth" "life" "healing"
    "potential" "freedom" "purpose" "coherence" "choice" "passion" "understanding"
    "balance" "growth" "togetherness" "sharing" "serenity" "oniomania" "stardust"
    "spacetime" "synchronicity" "chakras" "quantum-foam" "chi" "rebirth"
  )
  local adj=(
    "quantum" "infinite" "unified" "enlightened" "celestial" "cosmic" "transformative"
    "harmonic" "divine" "holistic" "astral" "non-local" "sentient" "ethereal"
    "intergalactic" "karmic" "spiritual" "consciousness-expanding" "zero-point"
  )
  local vt=(
    "awakens" "illuminates" "manifests" "transcends" "harmonizes" "activates"
    "nurtures" "transforms" "purifies" "energizes" "aligns"
  )
  local ing=(
    "flowering" "unfolding" "blossoming" "awakening" "deepening" "refining"
    "evolving" "summoning" "unveiling" "reimagining"
  )

  # Helper to pick a random item from an array passed by name
  pick() {
    local -n arr="$1"
    printf "%s" "${arr[RANDOM % ${#arr[@]}]}"
  }

local templates=(
  "$(pick n_mass) is the driver of $(pick n_mass)."
  "$(pick n_mass) is a constant. By $(pick ing), we vibrate."
  "Nothing is impossible. Today, science tells us that the essence of nature is $(pick n_mass)."
  "To roam the $(pick adj) circuit is to become one with it."
  "$(pick ing) is the truth of $(pick n_mass), and of us."
  "We exist as $(pick adj) $(pick n_mass). $(pick vt) your $(pick n_mass)!"
  "Through $(pick n_mass), our $(pick n_mass) $(pick vt) $(pick adj) $(pick n_mass)."
  "The $(pick adj) soup of $(pick n_mass) $(pick vt) the $(pick ing) of $(pick n_mass)."
)

local sentence="${templates[RANDOM % ${#templates[@]}]}"
  # Capitalize the first letter using Bash parameter expansion: ${var^}
  printf "%s\n" "${sentence^}"
}

qotd_draw() {
  local src header quote icon
  icon="$( get_icon "om" )"
  src="$( get_opt "qotd" "source" "dharma" )"
  case "${src,,}" in
    off|none|0) return 0 ;;
    dharma) 
      header="Daily Dharma"
      quote="$( qotd_dharma )" ;;
    newage)
      header="Newage Bullshit"
      quote="$( qotd_newage )" ;;
  esac
  local box_w="${LAST_BOX_W:-52}" body="" line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    [[ -n "$body" ]] && body+=$'\n'
    body+="${TAGLINEC}${line}${RESET}"
  done < <(fold -s -w $(( box_w - 4 )) <<< "$quote")

  printf "\n"
  boxer "$BORDERC" "$body" "${MUTEDC}${icon}  ${TEXTC}${header}  ${MUTEDC}${icon}${RESET} " "$box_w"
}
