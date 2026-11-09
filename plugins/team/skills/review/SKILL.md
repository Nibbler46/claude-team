---
name: review
description: Review aktuálních změn v projektu agentním týmem – automatické kontroly, kritika Gemini a safety (Opus) paralelně, arbitr (Opus/Fable) ověří výtky; pádné výtky volitelně opraví. Použij, když uživatel chce zkontrolovat své změny, větev nebo commit.
---

# Review změn týmem

Argument (volitelný): $ARGUMENTS – větev, commit nebo tag, proti kterému se změny porovnávají.

Jsi **dirigent**. Sám nehodnotíš – spouštíš agenty a komunikuješ s uživatelem. Odpovídej česky a stručně.

**Zlaté pravidlo:** kdykoli se běh zastaví, spusť `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-faze.sh" "<RUN>" konec`.

## 1. Co se kontroluje
1. Přejdi do kořene git repozitáře.
2. Spusť `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-init.sh"`. Pokud vypíše `POTREBA_INICIALIZACE`, spusť **team:inicializace**, ukaž souhrn a zeptej se `Pokračovat` / `Upravím sám` / `Zastavit`.
3. Urči `BASE`:
   - je-li zadán argument → `git rev-parse <argument>`,
   - jinak, pokud aktuální větev není `main`/`master` → `git merge-base HEAD <main nebo master>` (dej přednost `origin/HEAD`, pokud existuje),
   - jinak `HEAD` (kontrolují se jen necommitnuté změny).
4. `git diff --stat BASE` – pokud je prázdný, řekni, že není co kontrolovat, a skonči. Pokud existují nesledované soubory (`git ls-files --others --exclude-standard`), upozorni, že do review nevstoupí, dokud nebudou přidané (`git add -N <soubor>`), a zeptej se, zda je přidat.
5. Vytvoř `RUN=.team/runs/<RRRR-MM-DD-HHMM>-review` a `RUN/stav.md` s řádky `BASE: <sha>`, `REZIM: review`, `ZACATEK: <datum a čas>`.
6. Ukaž jednou větou, co se kontroluje (větev, počet souborů, BASE).

## 2. Výběr
**AskUserQuestion** (jinak textem):
- **Kontroloři** (multiSelect): `Gemini (doporučeno)`, `Safety – Opus (doporučeno)`
- **Arbitr**: `Opus (doporučeno)`, `Fable – silnější, dražší`

Pokud je zvolen Gemini, ověř `command -v agy`. Arbitr = **team:arbitr**, při Fable **team:arbitr-fable**.

## 3. Fakta
1. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-faze.sh" "<RUN>" review`
2. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-kontroly.sh" "<RUN>" review` – výsledek si zapamatuj; review pokračuje i při selhání, ale selhání uveď na začátku výsledku.

## 4. Review a arbitráž
1. **Paralelně** zvolené: **team:kritik-gemini** (`diff`, `RUN`, 1) a **team:safety** (`diff`, `RUN`, 1).
2. **Arbitr**: fáze `diff`, `RUN`, kolo 1.

## 5. Výsledek
1. Notifikace:
   ```bash
   TEAM_NTFY_TOPIC="${user_config.ntfy_topic}" TEAM_NTFY_SERVER="${user_config.ntfy_server}" TEAM_TELEGRAM_TOKEN="${user_config.telegram_bot_token}" TEAM_TELEGRAM_CHAT_ID="${user_config.telegram_chat_id}" bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-notify.sh" "Review je hotové"
   ```
2. Ukaž na jednu obrazovku: výsledek kontrol, **PÁDNÉ výtky** (závažnost, soubor, co a proč, návrh opravy), NEJISTÉ výtky (co má uživatel posoudit), počet zamítnutých s odkazem na `RUN/verdikt-diff-1.md`.
3. Pokud jsou PÁDNÉ výtky, zeptej se: `Opravit pádné výtky`, `Nechat, opravím sám`.
4. **Opravy** (jen při souhlasu):
   1. `git diff --name-only BASE > RUN/scope.txt` (opravy smí měnit jen soubory, které už jsou ve změnách; plus testy, pokud je projekt má – doplň jejich složku).
   2. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-faze.sh" "<RUN>" implementace`
   3. **team:programator** v režimu `opravy` (`RUN`, kolo 1). Změny **necommituj** – nech je uživateli.
   4. Ukaž seznam oprav a výsledek kontrol a nabídni `/team:review` znovu pro ověření.
5. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-faze.sh" "<RUN>" konec`
