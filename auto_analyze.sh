#!/bin/bash

# Exit immediately if a command exits with a non-zero status for robustness.
set -e

echo "--- AI Failure Analyst (Automatic & Truncated) ---"


GH_TOKEN="${INPUT_GITHUB-TOKEN}"
API_URL="${INPUT_ANALYSIS-API-URL}"
SLACK_TOKEN="${INPUT_SLACK-BOT-TOKEN}"
SLACK_CHANNEL="${INPUT_SLACK-CHANNEL-ID}"


echo "Fetching job logs from the GitHub API..."
JOBS_API_URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}/jobs"
JOB_ID=$(curl -s -H "Authorization: token ${GH_TOKEN}" -H "Accept: application/vnd.github.v3+json" "${JOBS_API_URL}" | jq --arg job_name "${GITHUB_JOB}" '.jobs[] | select(.name == $job_name) | .id')

if [ -z "$JOB_ID" ]; then
  echo "Error: Could not find job ID for job name '${GITHUB_JOB}'."
  exit 1
fi

LOGS_DOWNLOAD_URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/jobs/${JOB_ID}/logs"
echo "Downloading logs from ${LOGS_DOWNLOAD_URL}..."
curl -L -o /tmp/logs.zip -H "Authorization: token ${GH_TOKEN}" -H "Accept: application/vnd.github.v3+json" "${LOGS_DOWNLOAD_URL}"

echo "Extracting full log..."
LOG_FILE_NAME=$(unzip -l /tmp/logs.zip | grep '.txt' | sort -n | head -n 1 | awk '{print $4}')
unzip -p /tmp/logs.zip "${LOG_FILE_NAME}" > /tmp/full_job.log


echo "Applying head/tail truncation to the log..."

HEAD_LINES=100
TAIL_LINES=300


TRUNCATED_LOG=$( (head -n "$HEAD_LINES" /tmp/full_job.log; echo -e "\n\n... (log truncated for brevity) ...\n\n"; tail -n "$TAIL_LINES" /tmp/full_job.log) )


echo "Cleaning the truncated log snippet..."

CLEANED_LOG=$(echo "$TRUNCATED_LOG" | sed 's/^.*Z //; s/^##\[group\].*//; s/^##\[endgroup\].*//')


CI_RUN_URL="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

JSON_PAYLOAD=$(jq -n \
                  --arg log "$CLEANED_LOG" \
                  --arg url "$CI_RUN_URL" \
                  --arg token "$SLACK_TOKEN" \
                  --arg channel "$SLACK_CHANNEL" \
                  '{log_content: $log, ci_run_url: $url, slack_bot_token: $token, slack_channel_id: $channel}')


echo "Sending final truncated analysis request to the API server..."
curl -X POST "${API_URL}/analyze" \
     -H "Content-Type: application/json" \
     -d "$JSON_PAYLOAD"

echo "Analysis request sent successfully."

