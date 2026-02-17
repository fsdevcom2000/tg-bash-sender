#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

CONFIG_FILE="./config.json"
LOCK_FILE="/run/telegram_sender.lock"

MAX_RETRIES=5
BASE_DELAY=2
CURL_TIMEOUT=20
CONNECT_TIMEOUT=10

usage() {
  cat <<EOF
Usage: $0 [--token TOKEN] [--chat_id CHAT_ID] [--message MESSAGE]
EOF
}

log() {
  local level="$1"
  shift
  logger -t telegram_sender "[$level] $*"
}

error_exit() {
  log "ERROR" "$*"
  printf "Error: %s\n" "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || error_exit "Command '$1' not found."
}

# --- Dependency check ---
for cmd in curl jq flock logger; do
  require_command "$cmd"
done

# --- Configuration check ---
[[ -f "$CONFIG_FILE" ]] || error_exit "Configuration file not found: $CONFIG_FILE"

TOKEN=$(jq -r '.token // empty' "$CONFIG_FILE")
CHAT_ID=$(jq -r '.chat_id // empty' "$CONFIG_FILE")
MESSAGE=""

# --- Argument parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --token) TOKEN="${2:-}"; shift 2 ;;
    --chat_id) CHAT_ID="${2:-}"; shift 2 ;;
    --message|-m) MESSAGE="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) error_exit "Unknown parameter: $1" ;;
  esac
done

[[ -z "$TOKEN" ]] && error_exit "Token not set."
[[ -z "$CHAT_ID" ]] && error_exit "Chat_id not set."

# --- Reading message ---
if [[ -z "$MESSAGE" ]]; then
  if [[ -t 0 ]]; then
    echo "Enter message text:"
  fi
  MESSAGE=$(cat || true)
fi

[[ -z "$MESSAGE" ]] && error_exit "Message is empty."

# --- Lock ---
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  log "WARN" "Script is already running. Skipping execution."
  exit 0
fi

# --- Send function ---
send_message() {
  curl -sS --fail-with-body \
    --connect-timeout "$CONNECT_TIMEOUT" \
    --max-time "$CURL_TIMEOUT" \
    -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    --data-urlencode "text=${MESSAGE}" \
    -w "\n%{http_code}"
}

# --- Main loop ---
attempt=1
delay=$BASE_DELAY

while (( attempt <= MAX_RETRIES )); do
  log "INFO" "Send attempt #$attempt"

  HTTP_RESPONSE=$(send_message || true)
  HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
  HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)

  # --- Success ---
  if [[ "$HTTP_CODE" == "200" ]]; then
    if jq -e '.ok == true' >/dev/null <<<"$HTTP_BODY"; then
      log "INFO" "Message sent successfully."
      echo "Message sent."
      exit 0
    fi

    # --- Telegram API error ---
    ERROR_CODE=$(jq -r '.error_code // 0' <<<"$HTTP_BODY")
    DESCRIPTION=$(jq -r '.description // "unknown error"' <<<"$HTTP_BODY")

    # --- Rate limit ---
    if [[ "$ERROR_CODE" == "429" ]]; then
      RETRY_AFTER=$(jq -r '.parameters.retry_after // 5' <<<"$HTTP_BODY")
      log "WARN" "Rate limit. Waiting $RETRY_AFTER seconds."
      sleep "$RETRY_AFTER"
      ((attempt++))
      continue
    fi

    error_exit "Telegram API error: $DESCRIPTION"
  fi

  # --- Retry only for 5xx or network errors ---
  if [[ "$HTTP_CODE" =~ ^5 ]] || [[ -z "$HTTP_CODE" ]]; then
    log "WARN" "HTTP $HTTP_CODE. Retry in ${delay}s."
    sleep "$delay"
    delay=$(( delay * 2 ))
    ((attempt++))
    continue
  fi

  # --- Other errors are fatal ---
  error_exit "HTTP error: $HTTP_CODE"
done

error_exit "Maximum retry attempts exceeded ($MAX_RETRIES)."