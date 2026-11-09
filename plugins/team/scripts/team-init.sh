#!/usr/bin/env bash
# Připraví strukturu .team v projektu. Obsah (CLAUDE.md, kontroly) vytváří agent team-inicializace.
# Vypíše "POTREBA_INICIALIZACE", pokud chybí .team/kontroly.sh.

root="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "CHYBA: nejsem v git repozitáři" >&2; exit 2; }
cd "$root" || exit 2

mkdir -p .team/runs

if [[ ! -f .team/pouceni.md ]]; then
  printf '# Poučení týmu pro tento projekt\n\nPravidla schválená uživatelem po minulých bězích /team.\n\n' > .team/pouceni.md
  echo "Vytvořeno .team/pouceni.md"
fi

touch .gitignore
for radek in ".team/runs/" ".team/active"; do
  grep -qxF "$radek" .gitignore || { echo "$radek" >> .gitignore; echo "Přidáno do .gitignore: $radek"; }
done

[[ -f .team/kontroly.sh ]] || echo "POTREBA_INICIALIZACE"
exit 0
