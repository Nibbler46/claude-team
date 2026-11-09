#!/usr/bin/env bash
# Pošle notifikaci na mobil (ntfy nebo Telegram) podle nastavení pluginu.
# Použití: tym-notify.sh "text"
# Jako Notification hook (bez argumentu, JSON na stdin) posílá jen během běhu /tym.
# Vždy končí kódem 0 – notifikace nesmí zastavit práci.

TYM_NTFY_TOPIC="${TYM_NTFY_TOPIC:-${CLAUDE_PLUGIN_OPTION_NTFY_TOPIC:-}}"
TYM_NTFY_SERVER="${TYM_NTFY_SERVER:-${CLAUDE_PLUGIN_OPTION_NTFY_SERVER:-}}"
TYM_TELEGRAM_TOKEN="${TYM_TELEGRAM_TOKEN:-${CLAUDE_PLUGIN_OPTION_TELEGRAM_BOT_TOKEN:-}}"
TYM_TELEGRAM_CHAT_ID="${TYM_TELEGRAM_CHAT_ID:-${CLAUDE_PLUGIN_OPTION_TELEGRAM_CHAT_ID:-}}"
[[ -z "${TYM_NTFY_TOPIC:-}" && -z "${TYM_TELEGRAM_TOKEN:-}" ]] && exit 0

root="$(git rev-parse --show-toplevel 2>/dev/null)"
projekt="$(basename "${root:-$PWD}")"

if [[ $# -gt 0 ]]; then
  text="$1"
else
  # Režim hooku: jen když běží tým
  [[ -n "$root" && -f "$root/.tym/active" ]] || exit 0
  text="$(python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("message","Claude čeká na vás"))
except Exception: print("Claude čeká na vás")' 2>/dev/null)"
fi

if [[ -n "${TYM_NTFY_TOPIC:-}" ]]; then
  curl -s -m 10 -H "Title: Tym - $projekt" -d "$text" \
    "${TYM_NTFY_SERVER:-https://ntfy.sh}/$TYM_NTFY_TOPIC" > /dev/null 2>&1
fi
if [[ -n "${TYM_TELEGRAM_TOKEN:-}" && -n "${TYM_TELEGRAM_CHAT_ID:-}" ]]; then
  curl -s -m 10 "https://api.telegram.org/bot${TYM_TELEGRAM_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${TYM_TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=[$projekt] $text" > /dev/null 2>&1
fi
exit 0
