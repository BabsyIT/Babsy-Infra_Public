#!/bin/bash

# GitHub Organization name
ORG="BabsyIT"

# GitHub API token for authentication (replace with your GitHub personal access token)
GITHUB_TOKEN="your_personal_access_token_here"

# GitHub API URL to get members
GITHUB_API="https://api.github.com/orgs/$ORG/members"

# Paths for the keys file and sshd config
TEMP_KEYS_FILE="/tmp/github_ssh_keys"
GITHUB_AUTHORIZED_KEYS_FILE="$HOME/.ssh/github_authorized_keys"
SSHD_CONFIG="/etc/ssh/sshd_config"
CRON_JOB="0 * * * * /path/to/update_github_org_ssh_keys.sh"

# Ensure .ssh directory exists
mkdir -p "$HOME/.ssh"

# Install jq if not already installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Installing jq..."
    sudo apt-get update
    sudo apt-get install -y jq
    echo "jq installed successfully."
fi

# Clear temp keys file
> "$TEMP_KEYS_FILE"

# Fetch members of the organization
members=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$GITHUB_API" | jq -r '.[].login')

# Loop through each member and fetch their SSH keys
for member in $members; do
    # Fetch SSH keys for each member
    keys=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/users/$member/keys" | jq -r '.[].key')

    # Append each key to the temp keys file
    for key in $keys; do
        echo "# $member's SSH key" >> "$TEMP_KEYS_FILE"
        echo "$key" >> "$TEMP_KEYS_FILE"
    done
done

# Replace the github_authorized_keys file with the updated keys
mv "$TEMP_KEYS_FILE" "$GITHUB_AUTHORIZED_KEYS_FILE"
chmod 600 "$GITHUB_AUTHORIZED_KEYS_FILE"
echo "GitHub SSH keys updated at $(date)"

# Check and modify sshd_config if necessary
if ! grep -q "$GITHUB_AUTHORIZED_KEYS_FILE" "$SSHD_CONFIG"; then
    echo "Modifying $SSHD_CONFIG to include github_authorized_keys"
    echo "AuthorizedKeysFile .ssh/authorized_keys .ssh/github_authorized_keys" | sudo tee -a "$SSHD_CONFIG" > /dev/null
    sudo systemctl restart ssh
    echo "sshd_config updated and SSH service restarted."
else
    echo "$SSHD_CONFIG already configured for github_authorized_keys."
fi

# Add cron job if it doesn't already exist
(crontab -l | grep -q "$GITHUB_AUTHORIZED_KEYS_FILE") || (crontab -l; echo "$CRON_JOB") | crontab -
echo "Cron job created to run every hour."
