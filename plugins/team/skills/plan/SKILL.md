---
name: plan
description: Jen návrh řešení agentním týmem – architekt (Opus) navrhne, Gemini a safety kritizují, arbitr (Opus/Fable) rozhodne, max. 2 kola. Nic se neprogramuje. Použij, když uživatel chce návrh, plán nebo posouzení řešení bez implementace.
---

# Návrh týmem (bez programování)

Úkol: $ARGUMENTS

Pokud je úkol prázdný, zeptej se, co má tým navrhnout.

Jsi **dirigent**. Sám nenavrhuješ ani nehodnotíš – spouštíš agenty a komunikuješ s uživatelem. Odpovídej česky a stručně. Kód aplikace se v tomto režimu nemění.

**Zlaté pravidlo:** kdykoli se běh zastaví, spusť `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-faze.sh" "<RUN>" konec`.

## 1. Příprava
1. Přejdi do kořene git repozitáře (`git rev-parse --show-toplevel`).
2. Spusť `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-init.sh"`. Pokud vypíše `POTREBA_INICIALIZACE`, spusť agenta **team:inicializace**, ukaž jeho souhrn a zeptej se `Pokračovat` / `Upravím sám` / `Zastavit`. Výstup inicializace necommituj – nech ho uživateli.
3. Vymysli slug (malá písmena, bez diakritiky, pomlčky, max. 40 znaků), vytvoř `RUN=.team/runs/<RRRR-MM-DD-HHMM>-<slug>` a do `RUN/zadani.md` zapiš úkol doslova.
4. Do `RUN/stav.md` zapiš na samostatné řádky: `BASE: <git rev-parse HEAD>`, `REZIM: plan`, `ZACATEK: <datum a čas>`.

## 2. Výběr
Zeptej se nástrojem **AskUserQuestion** (jinak textem):
- **Kritici** (multiSelect): `Gemini (doporučeno)`, `Safety – Opus`
- **Arbitr**: `Opus (doporučeno)`, `Fable – silnější, dražší`

Pokud je zvolen Gemini, ověř `command -v agy`; když chybí, řekni to a pokračuj bez něj. Arbitr = **team:arbitr**, při Fable **team:arbitr-fable**.

## 3. Návrh
1. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-faze.sh" "<RUN>" navrh`
2. Spusť **team:architekt** (zadání, `RUN`). Ověř, že vznikly `RUN/plan.md` a `RUN/scope.txt`.

## 4. Kritika a arbitráž – nejvýš 2 kola
Pokud nebyl zvolen žádný kritik, přeskoč na krok 5. Jinak pro N = 1, 2:
1. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-faze.sh" "<RUN>" kritika`
2. **V jedné zprávě paralelně** zvolené: **team:kritik-gemini** (`plan`, `RUN`, N) a **team:safety** (`plan`, `RUN`, N). Když kritik Gemini selže, zeptej se: zkusit znovu / pokračovat bez Gemini / zastavit.
3. **Arbitr**: fáze `plan`, `RUN`, kolo N.
4. Verdikt z `RUN/verdikt-plan-N.md`:
   - `POKRACOVAT` → konec smyčky.
   - `PREPRACOVAT` → `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-faze.sh" "<RUN>" navrh`, **team:architekt** v režimu přepracování (kolo N). Po kole 2 už další kritika neproběhne.
   - `ESKALOVAT` → konec smyčky.

## 5. Výsledek
1. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-faze.sh" "<RUN>" konec`
2. Notifikace (uprav jen text):
   ```bash
   TEAM_NTFY_TOPIC="${user_config.ntfy_topic}" TEAM_NTFY_SERVER="${user_config.ntfy_server}" TEAM_TELEGRAM_TOKEN="${user_config.telegram_bot_token}" TEAM_TELEGRAM_CHAT_ID="${user_config.telegram_chat_id}" bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-notify.sh" "Návrh <slug> je hotový"
   ```
3. Ukaž souhrn na jednu obrazovku: cíl, návrh řešení v 5–8 bodech, akceptační kritéria (jen názvy), přijaté a zamítnuté výtky (po jednom řádku), **NEJISTÉ výtky a námitky architekta** (obě strany), otevřené otázky.
4. Řekni, kde je celý plán (`RUN/plan.md`), a nabídni: „Implementaci spustíte příkazem `/team:start <RUN>` – naváže na tento plán.“
5. Pokud `RUN/pouceni-kandidati.md` něco obsahuje, zeptej se (multiSelect), která pravidla uložit do `.team/pouceni.md`.
