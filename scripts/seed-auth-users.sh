#!/usr/bin/env bash
set -euo pipefail

HOST="${FIREBASE_AUTH_EMULATOR_HOST:-localhost:9099}"
BASE="http://$HOST/identitytoolkit.googleapis.com/v1"
PASSWORD="${SEED_PASSWORD:-password@123}"

if ! curl -sf -m 2 "http://$HOST/" -o /dev/null; then
  echo "auth emulator not reachable at $HOST" >&2
  exit 1
fi

# The emulator answers 400 with a JSON error body; -f would swallow it and the
# script would die without saying why.
api() {
  local body
  body=$(curl -s "$BASE/$1" \
    -H 'Authorization: Bearer owner' \
    -H 'Content-Type: application/json' \
    -d "$2")

  local message
  message=$(jq -r '.error.message // empty' <<<"$body")
  if [[ -n "$message" ]]; then
    echo "$1 failed: $message" >&2
    return 1
  fi

  echo "$body"
}

uid_for() {
  api "accounts:lookup" "{\"email\":[\"$1\"]}" | jq -r '.users[0].localId // empty'
}

seed_user() {
  local email="$1" phone="$2" uid

  uid=$(uid_for "$email")
  if [[ -z "$uid" ]]; then
    uid=$(api "accounts:signUp?key=fake-api-key" \
      "{\"email\":\"$email\",\"password\":\"$PASSWORD\",\"returnSecureToken\":true}" |
      jq -r '.localId')
  fi

  api "accounts:update" \
    "{\"localId\":\"$uid\",\"emailVerified\":true,\"phoneNumber\":\"$phone\"}" >/dev/null

  echo "$email -> $uid"
}

seed_user "admin@gotick.example" "+84900000001"
seed_user "owner@gotick.example" "+84900000002"
seed_user "user@gotick.example" "+84900000003"
