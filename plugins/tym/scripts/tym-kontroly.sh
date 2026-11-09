#!/usr/bin/env bash
# Spustí automatické kontroly projektu (.tym/kontroly.sh) a uloží log do běhu.
# Použití: tym-kontroly.sh <RUN> <oznaceni>   např. tym-kontroly.sh .tym/runs/... impl

run="${1:-}"; oznaceni="${2:-kontroly}"
root="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "CHYBA: nejsem v git repozitáři" >&2; exit 2; }
cd "$root" || exit 2
[[ -d "$run" ]] || { echo "CHYBA: složka běhu '$run' neexistuje" >&2; exit 2; }

log="$run/kontroly-$oznaceni.log"
if [[ ! -f .tym/kontroly.sh ]]; then
  echo "VAROVÁNÍ: .tym/kontroly.sh neexistuje – žádné automatické kontroly neproběhly." | tee "$log"
  exit 0
fi

bash .tym/kontroly.sh > "$log" 2>&1
rc=$?
tail -n 40 "$log"
echo
if [[ $rc -eq 0 ]]; then echo "KONTROLY: OK (log: $log)"; else echo "KONTROLY: SELHALY (kód $rc, log: $log)"; fi
exit $rc
