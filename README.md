# Agentní tým – plugin pro Claude Code

Univerzální tým agentů pro libovolný projekt. Technologie zjistí sám z `CLAUDE.md` projektu, Gemini volá přes Antigravity CLI (`agy`).

## Instalace (v Claude Code, žádné skripty)

**Varianta A – ze složky**
1. Rozbalte `tym-plugin.zip` do trvalého umístění, např. `~/claude-pluginy/` (plugin se načítá přímo odtud, složku nemažte).
2. V Claude Code:
   ```
   /plugin marketplace add ~/claude-pluginy/tym-marketplace
   /plugin install tym@tym-marketplace
   /plugin configure tym@tym-marketplace
   ```
   V nastavení vyplňte model Gemini (slug z příkazu `agy models`) a volitelně notifikace.
3. Restartujte Claude Code (nebo `/reload-plugins`).

**Varianta B – z GitHubu (doporučeno pro více počítačů)**
Nahrajte obsah složky `tym-marketplace` do repozitáře (může být soukromý) a na libovolném počítači:
```
/plugin marketplace add <váš-účet>/<repozitář>
/plugin install tym@tym-marketplace
```
Aktualizace pak dostanete přes `/plugin marketplace update tym-marketplace`.

**Předpoklady:** `git`, `python3`, `curl`; pro kritiku Gemini nainstalované a jednou interaktivně přihlášené `agy`.

## Použití
V kořeni projektu:
```
/tym:start tvorba konceptů nabídek z e-mailů přes MCP server
```
Jednotlivé agenty lze volat i samostatně, např. `@agent-tym:architekt`.

## Průběh
```
0. Příprava        čistý git, .tym/
   Inicializace    jen poprvé: technologie z CLAUDE.md / projektu → kontroly
                   ⏸ potvrzení souhrnu
1. Triáž           Sonnet odhadne riziko a předvyplní tým
2. Výběr týmu      zaškrtnete fáze a arbitra (Opus / Fable)
3. Návrh           Opus → plan.md + scope.txt + akceptační kritéria
4. Kritika plánu   Gemini + Safety (Opus) paralelně         ┐
5. Arbitráž        Opus/Fable: PÁDNÁ / NEPÁDNÁ / NEJISTÁ     ┘ max 2 kola
⏸  Schválení plánu (notifikace na mobil)
6. Testy napřed    Sonnet napíše testy z kritérií → commit
7. Implementace    Sonnet + automatické kontroly → commit
8. Review diffu    Gemini + Safety (Opus) paralelně         ┐
9. Arbitráž        → opravy → kontroly → commit              ┘ max 2 kola
⏸  Závěrečná zpráva na jednu obrazovku + uložení poučení
```
Vše běží ve větvi `tym/<úkol>`. Merge a push děláte vždy vy.

## Agenti
| Agent | Model | Úloha |
|---|---|---|
| `tym:inicializace` | Sonnet | jednou za projekt: technologie, doplnění CLAUDE.md, `.tym/kontroly.sh` |
| `tym:triage` | Sonnet | odhad rizika, doporučené fáze |
| `tym:architekt` | Opus | návrh, akceptační kritéria, rozsah souborů |
| `tym:kritik-gemini` | Haiku → Gemini | kritika plánu i diffu přes `agy` |
| `tym:arbitr` / `tym:arbitr-fable` | Opus / Fable | nestranný verdikt, registr výtek, poučení |
| `tym:safety` | Opus | bezpečnost plánu i diffu |
| `tym:programator` | Sonnet | testy napřed, implementace, opravy |

## Pojistky
- **Výtka bez důkazu neplatí** – kritici musí uvést soubor/řádek nebo scénář, arbitr ho ověří.
- **Registr výtek** – uzavřené výtky se v dalším kole nevracejí.
- **Hlídač rozsahu** (hook) – mimo fázi implementace se kód nemění; v implementaci jen soubory ze `scope.txt`; během běhu je zakázán `.env` a agenti nesmí upravit `.tym/kontroly.sh`.
- **Fakta před názory** – review diffu až po úspěšných kontrolách.

## Struktura v projektu
```
CLAUDE.md                pravidla projektu (čtou všichni agenti)
.tym/kontroly.sh         automatické kontroly – upravujete jen vy
.tym/pouceni.md          schválená poučení z minulých běhů
.tym/runs/<datum-úkol>/  plán, výtky, verdikty, logy, zpráva (v .gitignore)
```

## Omezení
- Hlídač kontroluje nástroje Edit/Write/Read, ne zápisy přes shell.
- `agy -p` má známou chybu s prázdným výstupem v rourách; skript to zkouší dvakrát, pak dirigent nabídne pokračovat bez Gemini.
- Plán a diff odcházejí i do Gemini.
- Pokud běh spadne a hlídač blokuje úpravy, smažte `.tym/active` (po 12 h se ignoruje sám).
