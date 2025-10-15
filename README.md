AI CI/CD Failure Analyst Action
This GitHub Action supercharges your debugging workflow. When a job fails, it automatically captures the logs, sends them to a powerful AI backend for root cause analysis, and delivers a concise, actionable summary directly to your team's Slack channel.

✨ Features
🤖 Automated Root Cause Analysis: Stop digging through logs. Get an immediate, AI-powered explanation of what went wrong.

🚀 Zero-Configuration Log Capture: No need to modify your build scripts to save log files. The action automatically finds and downloads the correct logs for the failed job.

💬 Instant Slack Notifications: Delivers insights directly into your development workflow with a link back to the failed run.

🔒 Secure & Stateless: Your secrets (like the Slack token) are passed securely with every run and are never stored on the analysis server.

🌐 Language Agnostic: Works with any language or framework (Node.js, Python, Go, Docker, etc.).

⚙️ How It Works
The action follows a simple, robust workflow when a failure is detected:

GitHub Action: The if: failure() condition triggers this action in your workflow.

Fetch Logs: The action uses the GitHub API to securely download the logs of the failed job.

POST to API Server: The log snippet is sent to the dedicated analysis server.

Analyze with Gemini: The server sends the log to the Gemini API for root cause analysis.

Notify Slack: The final analysis is formatted and posted to the user's designated Slack channel.

🚀 Usage
1. Set Up Secrets
In your repository, go to Settings > Secrets and variables > Actions and add the following secrets:

SLACK_BOT_TOKEN: Your Slack bot token (starts with xoxb-).

SLACK_CHANNEL_ID: The ID of the Slack channel for notifications (starts with C).

2. Update Your Workflow
Modify your workflow to call this action as the very last step in any job that might fail.

Example 1: Node.js Project with npm test

name: Node.js CI

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    # CRITICAL: This permission is required to allow the action to read workflow logs.
    permissions:
      actions: read

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install Dependencies
        run: npm install

      - name: Run Failing Tests
        # Your normal test command. If it fails, the next step will run.
        run: npm test

      - name: Analyze Failure on Error
        # This step will only run if any of the previous steps have failed.
        if: failure()
        uses: moazakramkhan1/ci-failure-analyzer-action@v1
        with:
          # You must pass the GITHUB_TOKEN to allow the action to fetch logs.
          github-token: ${{ secrets.GITHUB_TOKEN }}
          slack-bot-token: ${{ secrets.SLACK_BOT_TOKEN }}
          slack-channel-id: ${{ secrets.SLACK_CHANNEL_ID }}

Example 2: Python Project with pytest

name: Python CI

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    permissions:
      actions: read

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install Dependencies
        run: pip install -r requirements.txt

      - name: Run Pytest
        run: pytest

      - name: Analyze Failure on Error
        if: failure()
        uses: moazakramkhan1/ci-failure-analyzer-action@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          slack-bot-token: ${{ secrets.SLACK_BOT_TOKEN }}
          slack-channel-id: ${{ secrets.SLACK_CHANNEL_ID }}

Inputs
github-token (Required): The GITHUB_TOKEN secret, used to fetch job logs via the API. You must pass ${{ secrets.GITHUB_TOKEN }}.

slack-bot-token (Required): Your Slack Bot Token.

slack-channel-id (Required): The ID of the Slack channel.
