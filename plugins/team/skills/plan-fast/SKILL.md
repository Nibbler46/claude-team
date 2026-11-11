---
name: plan-fast
description: Rychlý návrh bez dotazů – architekt (Opus) navrhne, Gemini jednou zkritizuje, arbitr (Opus) rozhodne, architekt případně jednou zapracuje. Jedno kolo, nic se neprogramuje. Použij, když uživatel chce rychlý návrh nebo plán bez nastavování týmu.
---

# Rychlý návrh (jedno kolo)

Úkol: $ARGUMENTS

Pokud je úkol prázdný, zeptej se, co má tým navrhnout. Jinak se na nic neptej – tým je pevně daný:

**architekt (Opus) → kritika Gemini → arbitr (Opus) → případně jedno zapracování → výsledek**

Jsi **dirigent**. Sám nenavrhuješ ani nehodnotíš – spouštíš agenty. Odpovídej česky a stručně, mezi kroky nekomentuj. Kód aplikace se v tomto režimu nemění.

**Zlaté pravidlo:** kdykoli se běh zastaví, spusť `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-faze.sh" "<RUN>" konec`.

## 1. Příprava
1. Přejdi do kořene git repozitáře (`git rev-parse --show-toplevel`).
2. Spusť `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-init.sh"`. Pokud vypíše `POTREBA_INICIALIZACE`, spusť agenta **team:inicializace**, ukaž jeho souhrn a zeptej se `Pokračovat` / `Upravím sám` / `Zastavit` (jediný povolený dotaz). Výstup inicializace necommituj.
3. Ověř `command -v agy`. Pokud chybí, řekni jednou větou, že kritika Gemini neproběhne, a pokračuj bez ní (kroky 4–5 přeskoč).
4. Vymysli slug (malá písmena, bez diakritiky, pomlčky, max. 40 znaků), vytvoř `RUN=.team/runs/<RRRR-MM-DD-HHMM>-<slug>` a do `RUN/zadani.md` zapiš úkol doslova.
5. Do `RUN/stav.md` zapiš na samostatné řádky: `BASE: <git rev-parse HEAD>`, `REZIM: plan-fast`, `ARBITR: opus`, `ZACATEK: <datum a čas>`.

## 2. Návrh
1. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-faze.sh" "<RUN>" navrh`
2. Spusť **team:architekt** (zadání, `RUN`). Ověř, že vznikly `RUN/plan.md` a `RUN/scope.txt`; pokud ne, spusť ho jednou znovu s upozorněním, co chybí.

## 3. Kritika
1. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-faze.sh" "<RUN>" kritika`
2. Spusť **team:kritik-gemini**: režim `plan`, `RUN`, kolo 1.
3. Pokud selže, spusť ho ještě jednou. Když selže znovu, pokračuj bez kritiky a ve výsledku to uveď jako první řádek.

## 4. Arbitráž
Pokud kritika proběhla, spusť **team:arbitr** (Opus): fáze `plan`, `RUN`, kolo 1.

## 5. Jedno zapracování
Podle `CELKOVÝ VERDIKT` v `RUN/verdikt-plan-1.md`:
- `POKRACOVAT` → přejdi na výsledek.
- `PREPRACOVAT` → `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-faze.sh" "<RUN>" navrh` a **team:architekt** v režimu přepracování (kolo 1). Další kritika už neproběhne.
- `ESKALOVAT` → nic nezapracovávej, NEJISTÉ výtky ukaž ve výsledku.

## 6. Výsledek
1. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-faze.sh" "<RUN>" konec`
2. Notifikace (uprav jen text):
   ```bash
   TEAM_NTFY_TOPIC="${user_config.ntfy_topic}" TEAM_NTFY_SERVER="${user_config.ntfy_server}" TEAM_TELEGRAM_TOKEN="${user_config.telegram_bot_token}" TEAM_TELEGRAM_CHAT_ID="${user_config.telegram_chat_id}" bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-notify.sh" "Rychlý návrh <slug> je hotový"
   ```
3. Ukaž souhrn na jednu obrazovku:
   - cíl (1–2 věty) a návrh řešení v 5–8 bodech,
   - akceptační kritéria (jen názvy),
   - výtky Gemini: **přijaté** (co se změnilo) a **zamítnuté** (proč), po jednom řádku,
   - **NEJISTÉ výtky a námitky architekta** – u každé obě strany,
   - otevřené otázky.
4. Řekni, kde je celý plán (`RUN/plan.md`), a nabídni:
   - „Důkladnější posouzení: `/team:plan <úkol>` (víc kritiků, 2 kola).“
   - „Implementaci spustíte příkazem `/team:start <RUN>` – naváže na tento plán.“

Poučení (`RUN/pouceni-kandidati.md`) v tomto režimu neukládej – jen uveď, pokud nějaká vznikla.
