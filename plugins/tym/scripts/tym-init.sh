#!/usr/bin/env bash
# Připraví strukturu .tym v projektu. Obsah (CLAUDE.md, kontroly) vytváří agent tym-inicializace.
# Vypíše "POTREBA_INICIALIZACE", pokud chybí .tym/kontroly.sh.

root="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "CHYBA: nejsem v git repozitáři" >&2; exit 2; }
cd "$root" || exit 2

mkdir -p .tym/runs

if [[ ! -f .tym/pouceni.md ]]; then
  printf '# Poučení týmu pro tento projekt\n\nPravidla schválená uživatelem po minulých bězích /tym.\n\n' > .tym/pouceni.md
  echo "Vytvořeno .tym/pouceni.md"
fi

touch .gitignore
for radek in ".tym/runs/" ".tym/active"; do
  grep -qxF "$radek" .gitignore || { echo "$radek" >> .gitignore; echo "Přidáno do .gitignore: $radek"; }
done

[[ -f .tym/kontroly.sh ]] || echo "POTREBA_INICIALIZACE"
exit 0
