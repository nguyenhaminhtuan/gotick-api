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
job="${job:=$image}"
tag="${tag:="latest"}"
image_uri="${region}-docker.pkg.dev/${project}/${repo}/${image}:${tag}"

# Only the image is touched. Everything else about the job belongs to Terraform,
# which ignores changes to this field precisely so the two do not fight.
echo "Pointing job ${job} at ${image_uri}..."
gcloud run jobs update "$job" \
  --image "$image_uri" \
  --region "$region" \
  --project "$project"

if [[ ${execute:="true"} != "true" ]]; then
  echo "Updated. Run it with:"
  echo "- gcloud run jobs execute ${job} --region ${region} --project ${project} --wait"
  exit 0
fi

echo "Executing ${job} and waiting for it to finish..."
if gcloud run jobs execute "$job" \
  --region "$region" \
  --project "$project" \
  --wait; then
  echo "Execution succeeded."
  exit 0
fi

# A job that cannot reach the database fails here rather than at deploy time, and
# the reason is only in the task log.
echo
echo "Execution failed. Read why with:"
echo "- gcloud beta run jobs logs tail ${job} --region ${region} --project ${project}"
echo "or in Logs Explorer:"
echo "- resource.type=\"cloud_run_job\" resource.labels.job_name=\"${job}\""
exit 1
