#!/usr/bin/env bash
# Pošle notifikaci na mobil (ntfy nebo Telegram) podle nastavení pluginu
# nebo souboru ~/.config/claude-team/config (viz team-config.sh).
# Použití: team-notify.sh "text"
# Jako Notification hook (bez argumentu, JSON na stdin) posílá jen během běhu /team.
# Vždy končí kódem 0 – notifikace nesmí zastavit práci.

source "$(dirname "$0")/team-config.sh"
team_nastav TEAM_NTFY_TOPIC ntfy_topic CLAUDE_PLUGIN_OPTION_NTFY_TOPIC
team_nastav TEAM_NTFY_SERVER ntfy_server CLAUDE_PLUGIN_OPTION_NTFY_SERVER
team_nastav TEAM_TELEGRAM_TOKEN telegram_bot_token CLAUDE_PLUGIN_OPTION_TELEGRAM_BOT_TOKEN
team_nastav TEAM_TELEGRAM_CHAT_ID telegram_chat_id CLAUDE_PLUGIN_OPTION_TELEGRAM_CHAT_ID
[[ -z "${TEAM_NTFY_TOPIC:-}" && -z "${TEAM_TELEGRAM_TOKEN:-}" ]] && exit 0

root="$(git rev-parse --show-toplevel 2>/dev/null)"
projekt="$(basename "${root:-$PWD}")"

if [[ $# -gt 0 ]]; then
  text="$1"
else
  # Režim hooku: jen když běží tým
  [[ -n "$root" && -f "$root/.team/active" ]] || exit 0
  text="$(python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("message","Claude čeká na vás"))
except Exception: print("Claude čeká na vás")' 2>/dev/null)"
fi

if [[ -n "${TEAM_NTFY_TOPIC:-}" ]]; then
  curl -s -m 10 -H "Title: Team - $projekt" -d "$text" \
    "${TEAM_NTFY_SERVER:-https://ntfy.sh}/$TEAM_NTFY_TOPIC" > /dev/null 2>&1
fi
if [[ -n "${TEAM_TELEGRAM_TOKEN:-}" && -n "${TEAM_TELEGRAM_CHAT_ID:-}" ]]; then
  curl -s -m 10 "https://api.telegram.org/bot${TEAM_TELEGRAM_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${TEAM_TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=[$projekt] $text" > /dev/null 2>&1
fi
exit 0
