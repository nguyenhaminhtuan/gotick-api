#!/usr/bin/env bash
set -eo pipefail

# Deploys by hand in the order the Deploy workflow uses: the migration job runs
# and is waited on first, then the background job takes the same image without
# running, then the services follow.
#
#   scripts/deploy.sh --project prj-gotick-dev-1234 --tag sha-4b51c53
#   scripts/deploy.sh --project prj-gotick-prd-1234 --environment prd --targets api

while [ $# -gt 0 ]; do
  if [[ $1 == "--"* ]]; then
    v="${1/--/}"
    declare "$v"="$2"
    shift
  fi
  shift
done

if [[ -z $project ]]; then
  echo "project is required"
  exit 1
fi

region="${region:="asia-southeast1"}"
repo="${repo:="containers"}"
environment="${environment:="dev"}"
tag="${tag:="latest"}"
targets="${targets:="migrate,api,docs"}"

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

selected() {
  case ",${targets}," in
  *",$1,"*) return 0 ;;
  esac
  return 1
}

common=(--project "$project" --region "$region" --repo "$repo" --tag "$tag")

echo "Deploying ${targets} to ${environment} (${project}) at tag ${tag}"
echo

if selected migrate; then
  echo "==> job migrate, executes"
  "$here/deploy-job.sh" "${common[@]}" \
    --image migrate \
    --job migrate \
    --execute true

  echo
  echo "==> job migrate-background, image only"
  "$here/deploy-job.sh" "${common[@]}" \
    --image migrate \
    --job migrate-background \
    --execute false
  echo
fi

# After migrate, and only because set -e stopped us if it failed: the new
# revision expects the new schema.
if selected api; then
  echo "==> api"
  "$here/deploy-service.sh" "${common[@]}" --image api
  echo
fi

if selected docs; then
  if [[ $environment == "dev" ]]; then
    echo "==> docs"
    "$here/deploy-service.sh" "${common[@]}" --image docs
  else
    echo "Skipping docs: only dev declares the service."
  fi
fi
