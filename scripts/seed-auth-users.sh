#!/usr/bin/env bash
set -euo pipefail

HOST="${FIREBASE_AUTH_EMULATOR_HOST:-localhost:9099}"
BASE="http://$HOST/identitytoolkit.googleapis.com/v1"

signup() {
  local email="$1" password="$2"
  curl -s "$BASE/accounts:signUp?key=fake-api-key" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$email\",\"password\":\"$password\",\"returnSecureToken\":true}" \
    | jq -r '.localId // .error.message'
}

echo "creating users..."
signup "admin@gotick.example" "password@123"
signup "owner@gotick.example" "password@123"
signup "user@gotick.example" "password@123"
