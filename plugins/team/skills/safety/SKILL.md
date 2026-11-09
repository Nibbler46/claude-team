---
name: safety
description: Jen bezpečnostní kontrola aktuálních změn v projektu (Opus) – nedůvěryhodné vstupy, oprávnění, injection, peníze, osobní údaje, tajemství; nálezy volitelně opraví. Použij, když uživatel chce bezpečnostní audit svých změn.
---

# Bezpečnostní kontrola změn

Argument (volitelný): $ARGUMENTS – větev, commit nebo tag, proti kterému se změny porovnávají.

Jsi **dirigent**. Sám nehodnotíš – spouštíš agenty a komunikuješ s uživatelem. Odpovídej česky a stručně.

**Zlaté pravidlo:** kdykoli se běh zastaví, spusť `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-faze.sh" "<RUN>" konec`.

## 1. Co se kontroluje
1. Přejdi do kořene git repozitáře.
2. Spusť `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-init.sh"`. Pokud vypíše `POTREBA_INICIALIZACE`, spusť **team:inicializace**, ukaž souhrn a zeptej se `Pokračovat` / `Upravím sám` / `Zastavit`.
3. Urči `BASE` stejně jako u review:
   - je-li zadán argument → `git rev-parse <argument>`,
   - jinak, pokud aktuální větev není `main`/`master` → `git merge-base HEAD <main nebo master>`,
   - jinak `HEAD` (jen necommitnuté změny).
4. Pokud je `git diff --stat BASE` prázdný, řekni to a skonči. Upozorni na nesledované soubory, které do kontroly nevstoupí.
5. Vytvoř `RUN=.team/runs/<RRRR-MM-DD-HHMM>-safety` a `RUN/stav.md` s řádky `BASE: <sha>`, `REZIM: safety`, `ZACATEK: <datum a čas>`.

## 2. Kontrola
1. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-faze.sh" "<RUN>" review`
2. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-kontroly.sh" "<RUN>" safety` (audit závislostí a statická analýza jsou podklad pro safety).
3. Spusť **team:safety** v režimu `diff` (`RUN`, kolo 1).

## 3. Výsledek
1. Ukaž nálezy z `RUN/safety-diff-1.md` seřazené podle závažnosti, u každého: soubor, problém, scénář, návrh opravy. Pokud nic závažného není, řekni to jednou větou.
2. Pokud jsou KRITICKÉ nebo DŮLEŽITÉ nálezy, zeptej se: `Opravit kritické a důležité`, `Nechat, opravím sám`.
3. **Opravy** (jen při souhlasu):
   1. Zapiš `RUN/vytky.md` jako tabulku `| ID | Zdroj | Fáze | Závažnost | Tvrzení | Důkaz | Stav | Zdůvodnění |`, kde vybrané nálezy dostanou ID S1, S2… a stav `PÁDNÁ`.
   2. `git diff --name-only BASE > RUN/scope.txt` (doplň složku testů, pokud ji projekt má).
   3. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-faze.sh" "<RUN>" implementace`
   4. **team:programator** v režimu `opravy` (`RUN`, kolo 1). Změny **necommituj**.
   5. Ukaž seznam oprav a výsledek kontrol a nabídni `/team:safety` znovu pro ověření.
4. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/team-faze.sh" "<RUN>" konec`
