#!/usr/bin/env python3
"""Hlídač rozsahu pro /tym (PreToolUse hook pro Read/Edit/Write/MultiEdit/NotebookEdit).

- Bez aktivního běhu (.tym/active) nic nedělá.
- Během běhu vždy blokuje čtení a zápis .env* a zápis do .tym/kontroly.sh a .tym/pouceni.md.
- Ve fázi "implementace" povolí jen soubory ze scope.txt (a složku .tym/).
- V ostatních fázích (návrh, kritika, review) povolí jen zápis do .tym/.
Blokace = exit 2, zpráva na stderr se vrátí agentovi.
"""
import fnmatch
import json
import os
import subprocess
import sys
import time

MAX_STARI = 12 * 3600  # starší značka běhu se ignoruje (zapomenutý běh)


def blokuj(zprava: str) -> None:
    print(f"tym: {zprava}\n(Pokud žádný běh /tym neprobíhá, smažte soubor .tym/active.)", file=sys.stderr)
    sys.exit(2)


def koren_repa(cesta: str):
    d = os.path.dirname(cesta)
    while d and not os.path.isdir(d):
        d = os.path.dirname(d)
    try:
        return subprocess.run(["git", "-C", d or ".", "rev-parse", "--show-toplevel"],
                              capture_output=True, text=True, timeout=5).stdout.strip() or None
    except Exception:
        return None


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    vstup = data.get("tool_input") or {}
    cesta = vstup.get("file_path") or vstup.get("notebook_path")
    if not cesta:
        sys.exit(0)
    cwd = data.get("cwd") or os.getcwd()
    cesta = os.path.abspath(os.path.join(cwd, os.path.expanduser(cesta)))

    koren = koren_repa(cesta)
    if not koren:
        sys.exit(0)
    aktivni = os.path.join(koren, ".tym", "active")
    if not os.path.isfile(aktivni):
        sys.exit(0)

    stav = {}
    with open(aktivni, encoding="utf-8") as f:
        for radek in f:
            if "=" in radek:
                k, v = radek.strip().split("=", 1)
                stav[k] = v
    try:
        if time.time() - float(stav.get("CAS", "0")) > MAX_STARI:
            print("tym: značka běhu je starší než 12 h, hlídač ji ignoruje.", file=sys.stderr)
            sys.exit(0)
    except ValueError:
        pass

    rel = os.path.relpath(cesta, koren).replace(os.sep, "/")
    if rel.startswith("../"):
        sys.exit(0)  # mimo repozitář

    faze = stav.get("FAZE", "")
    jmeno = os.path.basename(rel)

    if jmeno.startswith(".env") and not jmeno.endswith(".example"):
        blokuj(f"práce se souborem {rel} je během běhu týmu zakázána.")
    if data.get("tool_name") == "Read":
        sys.exit(0)  # čtení ostatních souborů je vždy povolené
    if rel in (".tym/kontroly.sh", ".tym/pouceni.md"):
        blokuj(f"{rel} může upravit jen uživatel, ne agent během běhu.")
    if rel.startswith(".tym/"):
        sys.exit(0)

    if faze != "implementace":
        blokuj(f"ve fázi '{faze}' se kód aplikace nemění (pokus o zápis do {rel}).")

    run = stav.get("RUN", "")
    scope_soubor = os.path.join(koren, run, "scope.txt")
    if not os.path.isfile(scope_soubor):
        blokuj(f"chybí {run}/scope.txt – nelze ověřit rozsah.")

    with open(scope_soubor, encoding="utf-8") as f:
        vzory = [r.strip() for r in f if r.strip() and not r.strip().startswith("#")]
    for vzor in vzory:
        if vzor.startswith("./"):
            vzor = vzor[2:]
        if vzor.endswith("/"):
            vzor += "*"
        if fnmatch.fnmatch(rel, vzor.replace("**", "*")):
            sys.exit(0)

    blokuj(f"{rel} není v rozsahu plánu ({run}/scope.txt). "
           f"Vrať dirigentovi 'MIMO ROZSAH: {rel} – <důvod>' a nepokoušej se to obejít.")


if __name__ == "__main__":
    main()
