# Načítání nastavení pluginu (sourcuje se z ostatních skriptů).
# Pořadí: nastavení pluginu v Claude (proměnné prostředí)
#         → .team/config v projektu → ~/.config/claude-team/config
# Formát souborů: klic=hodnota, jeden na řádek, # = komentář.

# team_cfg <klic> – vypíše hodnotu z konfiguračních souborů (nebo nic)
team_cfg() {
  local klic="$1" soubor hodnota koren
  koren="$(git rev-parse --show-toplevel 2>/dev/null)"
  for soubor in "${koren:-.}/.team/config" "$HOME/.config/claude-team/config"; do
    [[ -f "$soubor" ]] || continue
    hodnota="$(sed -n "s/^[[:space:]]*${klic}[[:space:]]*=[[:space:]]*//p" "$soubor" | tail -n 1 \
      | sed -e 's/[[:space:]]*$//' -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'$/\1/")"
    if [[ -n "$hodnota" ]]; then printf '%s' "$hodnota"; return 0; fi
  done
  return 0
}

# team_nastav <PROMENNA> <klic> [<PROMENNA_Z_HOOKU>]
# Ponechá platnou hodnotu proměnné, jinak ji doplní z hooku nebo ze souborů.
team_nastav() {
  local promenna="$1" klic="$2" zaloha="${3:-}" hodnota
  hodnota="${!promenna:-}"
  [[ "$hodnota" == *'${user_config'* ]] && hodnota=""      # nevyplněné nastavení pluginu
  [[ -z "$hodnota" && -n "$zaloha" ]] && hodnota="${!zaloha:-}"
  [[ -z "$hodnota" ]] && hodnota="$(team_cfg "$klic")"
  printf -v "$promenna" '%s' "$hodnota"
}
