#!/usr/bin/env bash
set -eo pipefail

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
elif [[ -z $repo ]]; then
  echo "repo is required"
  exit 1
elif [[ -z $image ]]; then
  echo "image is required"
  exit 1
fi

region="${region:="asia-southeast1"}"
service="${service:=$image}"
tag="${tag:="latest"}"
image_uri="${region}-docker.pkg.dev/${project}/${repo}/${image}:${tag}"

args=(--image "$image_uri" --region "$region" --project "$project")

if [[ -n $revision_tag ]]; then
  args+=(--tag "$revision_tag" --no-traffic)
  echo "Deploying ${service} as revision tag ${revision_tag}, no traffic..."
else
  echo "Deploying ${service} and sending traffic to it..."
fi

gcloud run services update "$service" "${args[@]}"

echo
echo "Revisions now:"
gcloud run services describe "$service" \
  --region "$region" \
  --project "$project" \
  --format='table(status.traffic.revisionName,status.traffic.percent,status.traffic.tag)'
