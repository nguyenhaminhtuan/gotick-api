#!/usr/bin/env bash
set -euo pipefail

HOST="${FIREBASE_AUTH_EMULATOR_HOST:-localhost:9099}"
EMAIL="${1}"
PASS="${2}"

curl -s "http://$HOST/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\",\"returnSecureToken\":true}" \
  | jq -r .idToken