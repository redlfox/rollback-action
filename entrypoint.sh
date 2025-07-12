#!/bin/bash

function cleanup {
  echo "Cleaning up..."
  cd ..
  rm -rf repo
}

function error {
  echo "Error: $1"
  cleanup
  exit 1
}

trap 'error "An unexpected error occurred."' ERR

# Check if the action is triggered by workflow_dispatch
if [ "${GITHUB_EVENT_NAME}" != "workflow_dispatch" ]; then
  error "This action can only be run as a workflow dispatch."
fi


# Authenticate with GitHub
# Commenting this out. It seems no longer needed because we are using the GH_TOKEN variable
#echo "Authenticating with GitHub..."
#echo "${GITHUB_TOKEN}" | gh auth login --with-token || error "Failed to authenticate with GitHub."

# Set up repository
echo "Setting up repository..."
gh repo clone "${GITHUB_REPOSITORY}" repo || error "Failed to clone the repository."
cd repo

# Check if the branch is 'main'
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$current_branch" != "main" ]; then
  error "Current branch is not 'main'. This action only works on the 'main' branch."
fi

# Create a backup branch with a timestamp
timestamp=$(date +"%Y%m%d-%H%M%S")
backup_branch="backup-${timestamp}"
git checkout main
git checkout -b "${backup_branch}" || error "Failed to create a backup branch."
#dont know why but you need to set the url with a token and repo name.
git remote set-url origin https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}
git push origin "${backup_branch}" || error "Failed to push the backup branch."

# Rollback main to the previous commit and force push
git checkout main
git reset --hard HEAD~1 || error "Failed to reset the 'main' branch."
git push --force origin main || error "Failed to force push the 'main' branch."

# Clean up
cleanup

echo "Rollback complete."
