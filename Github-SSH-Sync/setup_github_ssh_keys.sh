#!/bin/bash

# GitHub Organization name
ORG="BabsyIT"

# GitHub PAT (Personal Access Token) - wird bei der ersten Ausführung abgefragt
read -p "Enter your GitHub Personal Access Token (PAT): " GITHUB_TOKEN
echo

# Setze Pfade und Dateien
BASE_DIR="/opt/github-ssh"
TOKEN_FILE="$BASE_DIR/.github_token"
SCRIPT_FILE="$BASE_DIR/update_github_org_ssh_keys.sh"
CRON_JOB="0 * * * * $SCRIPT_FILE"

# Verzeichnis erstellen und Berechtigungen setzen
echo "Setting up the directory and saving the GitHub token securely..."
sudo mkdir -p "$BASE_DIR"
echo "$GITHUB_TOKEN" | sudo tee "$TOKEN_FILE" > /dev/null
sudo chmod 600 "$TOKEN_FILE"

# Skript für die Aktualisierung der SSH-Keys erstellen
echo "Downloading the update script..."
sudo tee "$SCRIPT_FILE" > /dev/null << 'EOF'
#!/bin/bash

# GitHub Organization name
ORG="BabsyIT"

# GitHub API URL to get members
GITHUB_API="https://api.github.com/orgs/$ORG/members"

# Load GitHub token from file
GITHUB_TOKEN=$(cat /opt/github-ssh/.github_token)

# Paths for the keys file and sshd config
TEMP_KEYS_FILE="/tmp/github_ssh_keys"
GITHUB_AUTHORIZED_KEYS_FILE="$HOME/.ssh/github_authorized_keys"
SSHD_CONFIG="/etc/ssh/sshd_config"

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

# Check if members were retrieved successfully
if [ -z "$members" ]; then
    echo "Error: No members retrieved from GitHub. Check your GitHub token and organization name."
    exit 1
fi

# Loop through each member and fetch their SSH keys
for member in $members; do
    # Fetch SSH keys for each member, including the title
    keys=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/users/$member/keys")

    # Check if keys were retrieved successfully
    if [ -z "$keys" ]; then
        echo "Warning: No SSH keys found for $member"
        continue
    fi

    # Parse and append each key to the temp keys file as a single line
    echo "$keys" | jq -c '.[]' | while read key_entry; do
        key=$(echo "$key_entry" | jq -r '.key')
        title=$(echo "$key_entry" | jq -r '.title')

        # Ensure the key is on a single line and append the title as a comment
        echo "$key # $title" >> "$TEMP_KEYS_FILE"
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
EOF

# Skript ausführbar machen
sudo chmod +x "$SCRIPT_FILE"

# Cronjob hinzufügen, falls er nicht existiert
echo "Setting up the cron job to run the script every hour..."
(sudo crontab -l 2>/dev/null; echo "$CRON_JOB") | sudo crontab -

echo "Setup complete. The script will now run every hour to update SSH keys."
echo "You can manually run it with: sudo $SCRIPT_FILE"
