 #!/usr/bin/env bash
 ## -----------------------------------------------------------------
 # MENU_GEN responsible for generating the main/base alpha-tmux menu
 ## -----------------------------------------------------------------
 menu_gen() {
   local len max; max=0
   local menu="${1:-$PLUGIN_ROOT/lib/menu-main.yaml}"
   local Buttons=()

   # 1. Calculate max label width across buttons
   while read -r name; do
     len="${#name}"
       (( len > max )) && max="$len"
     done < <(yq e '.Buttons[].name' "$menu")

     # 2. Build formatted button strings into Buttons array
     while read -r key; do
       Buttons+=("$(make_button "$key" "$max")")
     done < <(yq e '.Buttons[].key' "$menu")

     # 3. Render grid & print selection prompt
     render_grid "${Buttons[@]}"
     center "Enter menu selection or press [ENTER] for a ${SHELL##*/} prompt"
 }
