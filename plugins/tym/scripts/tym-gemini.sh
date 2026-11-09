#!/usr/bin/env bash
# Kritika plánu nebo diffu pomocí Gemini přes Antigravity CLI (agy).
# Použití: tym-gemini.sh <plan|diff> <RUN> <kolo>
# Výstup:  <RUN>/kritika-<režim>-<kolo>.md
# Návratové kódy: 0 OK, 2 špatné použití / chybí nástroj, 3 Gemini neodpověděl
# Kompatibilní s bash 3.2 (macOS).

rezim="${1:-}"; run="${2:-}"; kolo="${3:-}"
if [[ "$rezim" != "plan" && "$rezim" != "diff" ]] || [[ -z "$run" || -z "$kolo" ]]; then
  echo "CHYBA: použití: tym-gemini.sh <plan|diff> <RUN> <kolo>" >&2
  exit 2
fi

root="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "CHYBA: nejsem v git repozitáři" >&2; exit 2; }
cd "$root" || exit 2
[[ -d "$run" ]] || { echo "CHYBA: složka běhu $run neexistuje" >&2; exit 2; }
command -v agy >/dev/null 2>&1 || { echo "CHYBA: příkaz agy nenalezen – nainstalujte Antigravity CLI a přihlaste se (agy)" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "CHYBA: chybí python3" >&2; exit 2; }

# Nastavení z pluginu (TYM_GEMINI_MODEL, TYM_GEMINI_EFFORT) – prázdné = výchozí hodnoty agy
model_arg=(); [[ -n "${TYM_GEMINI_MODEL:-}" ]] && model_arg=(--model "$TYM_GEMINI_MODEL")
effort_arg=(); [[ -n "${TYM_GEMINI_EFFORT:-}" ]] && effort_arg=(--effort "$TYM_GEMINI_EFFORT")

vystup="$run/kritika-$rezim-$kolo.md"
predmet="$run/predmet-$rezim-$kolo.txt"
prompt_soubor="$run/.gemini-prompt-$rezim-$kolo.md"

# --- Předmět kritiky ---
if [[ "$rezim" == "plan" ]]; then
  [[ -f "$run/plan.md" ]] || { echo "CHYBA: chybí $run/plan.md" >&2; exit 2; }
  { cat "$run/plan.md"; echo; echo "--- Rozsah souborů (scope.txt) ---"; cat "$run/scope.txt" 2>/dev/null; } > "$predmet"
  nazev="PLÁN"
else
  base="$(sed -n 's/^BASE:[[:space:]]*//p' "$run/stav.md" 2>/dev/null | head -n1)"
  [[ -n "$base" ]] || { echo "CHYBA: v $run/stav.md chybí řádek 'BASE: <sha>'" >&2; exit 2; }
  git diff "$base" -- . ':(exclude).tym' > "$predmet"
  [[ -s "$predmet" ]] || { echo "CHYBA: diff proti $base je prázdný" >&2; exit 2; }
  nazev="DIFF"
fi

# Uzavřené výtky – Gemini je nesmí znovu otevírat
uzavrene="$(grep -E '\| *(NEPÁDNÁ|VYŘEŠENÁ|DUPLICITNÍ) *\|' "$run/vytky.md" 2>/dev/null || true)"
pravidla="$(head -c 15000 CLAUDE.md 2>/dev/null || true)"

# --- Sestavení zadání ---
{
cat <<EOF
Jsi zkušený senior reviewer a nezávislý kritik. Posuzuješ $nazev, který vytvořil jiný AI model.
NIC NEMĚŇ – žádné soubory ani příkazy, které cokoli upravují. Smíš jen číst soubory v repozitáři, abys ověřil svá tvrzení.

Hledej:
- chyby v logice, chybějící případy a nesplnitelná nebo netestovatelná kritéria
- bezpečnost: nedůvěryhodné vstupy (e-maily, formuláře, výstupy LLM), autorizace, injection, mass assignment, XSS
- peníze a data: ceny/slevy jen ze serveru, zaokrouhlení, nevratné operace, osobní údaje
- zbytečnou složitost a odchylky od pravidel projektu
- PRE-MORTEM: představ si, že řešení za 3 měsíce v produkci selhalo. Proč?

PRAVIDLA VÝSTUPU:
- Každá výtka MUSÍ mít důkaz: soubor:řádek, doslovnou citaci z plánu, nebo konkrétní scénář (vstup → co se stane). Výtky bez důkazu nepiš.
- Formát každé výtky:
  ### <krátký název>
  Závažnost: KRITICKÁ | DŮLEŽITÁ | DROBNÁ
  Tvrzení: ...
  Důkaz: ...
  Návrh: ...
- Nic nechval, nepiš úvod ani shrnutí.
- Pokud nenajdeš nic kritického ani důležitého, napiš přesně: Žádné kritické ani důležité výtky.
- Piš česky.
EOF
if [[ -n "$uzavrene" ]]; then
  echo
  echo "TYTO VÝTKY UŽ BYLY UZAVŘENY – neotevírej je znovu ani v jiné formulaci:"
  echo "$uzavrene"
fi
if [[ -n "$pravidla" ]]; then
  echo
  echo "--- PRAVIDLA PROJEKTU (CLAUDE.md) ---"
  echo "$pravidla"
fi
echo
if (( $(wc -c < "$predmet") <= 70000 )); then
  echo "--- $nazev ---"
  cat "$predmet"
else
  echo "$nazev je příliš dlouhý na vložení. Přečti ho celý ze souboru: $predmet"
fi
} > "$prompt_soubor"

prompt="$(cat "$prompt_soubor")"
if (( ${#prompt} > 100000 )); then
  prompt="Přečti zadání ze souboru $prompt_soubor a postupuj přesně podle něj."
fi

# --- Volání agy (prompt jako POSLEDNÍ argument, stdin zavřený – známá chyba agy v rourách) ---
tcmd=()
command -v timeout  >/dev/null 2>&1 && tcmd=(timeout 900)
command -v gtimeout >/dev/null 2>&1 && [[ ${#tcmd[@]} -eq 0 ]] && tcmd=(gtimeout 900)

surovy="$run/.gemini-raw-$rezim-$kolo.json"
chyby="$run/.gemini-err-$rezim-$kolo.log"

for pokus in 1 2; do
  "${tcmd[@]}" agy --output-format json "${model_arg[@]}" "${effort_arg[@]}" --print-timeout 900s --print "$prompt" \
    < /dev/null > "$surovy" 2> "$chyby"
  rc=$?

  python3 - "$surovy" "$vystup" <<'PY'
import json, sys
raw_path, out_path = sys.argv[1], sys.argv[2]
raw = open(raw_path, encoding="utf-8", errors="replace").read().strip()
if not raw:
    sys.exit(1)
text = None
try:
    d = json.loads(raw)
    status = str(d.get("status", "")).lower()
    if status in ("error", "failed", "failure"):
        sys.exit(1)
    text = d.get("response")
except json.JSONDecodeError:
    text = raw          # agy vrátil čistý text
if not isinstance(text, str) or not text.strip():
    sys.exit(1)
open(out_path, "w", encoding="utf-8").write(text.strip() + "\n")
PY
  if [[ $? -eq 0 ]]; then
    echo "OK: kritika uložena do $vystup"
    exit 0
  fi
  echo "Pokus $pokus: Gemini nevrátil odpověď (kód $rc)." >&2
done

echo "CHYBA: Gemini nevrátil použitelnou odpověď ani na 2. pokus (poslední kód $rc). Podrobnosti: $chyby, $surovy" >&2
tail -n 5 "$chyby" >&2 2>/dev/null
exit 3
