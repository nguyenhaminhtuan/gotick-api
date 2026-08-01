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
elif [[ -z $file ]]; then
  echo "file is required"
  exit 1
elif [[ -z $image ]]; then
  echo "image is required"
  exit 1
fi

image_uri="${region:="asia-southeast1"}-docker.pkg.dev/${project}/${repo}/${image}"
IFS=',' read -r -a tags_arr <<< "${tags:="latest"}"
primary="${tags_arr[0]}"

echo "Start building Docker image..."

docker build \
  -f $file \
  --platform=linux/amd64 \
  -t "${image_uri}:${primary}" \
  .

echo "Image tagged ${image_uri}:${primary}"
for tag in "${tags_arr[@]:1}"; do
  docker image tag "${image_uri}:${primary}" "${image_uri}:${tag}"
  echo "Image tagged ${image_uri}:${tag}"
done

if [[ ${push:="true"} != "true" ]]; then
  echo "Build image successfully, please run the following command to push image with all tags to registry:"
  echo "- docker image push --all-tags ${image_uri}"
  exit 0
fi

echo "Pushing ${image_uri} with all tags..."
docker image push --all-tags "$image_uri"

echo "Pushed successfully:"
for tag in "${tags_arr[@]}"; do
  echo "- ${image_uri}:${tag}"
done
