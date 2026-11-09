#!/usr/bin/env bash
# Nastaví aktuální fázi běhu /team pro hlídač rozsahu.
# Použití: team-faze.sh <RUN> <navrh|kritika|implementace|review|konec>

run="${1:-}"; faze="${2:-}"
root="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "CHYBA: nejsem v git repozitáři" >&2; exit 2; }
znacka="$root/.team/active"

case "$faze" in
  konec)
    rm -f "$znacka"
    echo "Běh ukončen, hlídač rozsahu vypnut."
    ;;
  navrh|kritika|implementace|review)
    [[ -n "$run" && -d "$root/$run" ]] || { echo "CHYBA: složka běhu '$run' neexistuje" >&2; exit 2; }
    mkdir -p "$root/.team"
    printf 'RUN=%s\nFAZE=%s\nCAS=%s\n' "$run" "$faze" "$(date +%s)" > "$znacka"
    echo "Fáze: $faze"
    ;;
  *)
    echo "CHYBA: neznámá fáze '$faze'" >&2; exit 2 ;;
esac
