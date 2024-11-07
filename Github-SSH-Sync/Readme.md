## Manual: Setting Up Automated GitHub SSH Key Fetching on Your Server (Direct Download)

### Prerequisites
- **Debian 12** or a similar Linux distribution.
- **GitHub Personal Access Token (PAT)** with the following permissions:
  - `read:org`: To read organization membership and public information.
  - `read:user`: To read public user information, including SSH keys.

### Step 1: Generate a GitHub Personal Access Token (PAT)

1. **Go to GitHub** and navigate to **Settings** > **Developer settings** > **Personal access tokens**.
2. Click **Generate new token** (or **Generate new token (classic)**, depending on your GitHub version).
3. Set a **token name** and expiration date as desired.
4. Under **Select scopes**, enable:
   - `read:org` for organization membership.
   - `read:user` for reading public user information, including SSH keys.
5. Click **Generate token**.
6. **Copy the token** and save it somewhere safe; you’ll need it in the setup process.

### Step 2: Download and Set Up the Script with `curl`

1. **Open a terminal** on your server.
2. **Run the following `curl` command** to download the script:

   ```bash
   curl -o ~/update_github_org_ssh_keys.sh https://example.com/path/to/update_github_org_ssh_keys.sh
   ```

3. **Make the script executable**:

   ```bash
   chmod +x ~/update_github_org_ssh_keys.sh
   ```

### Step 3: Run the Script Manually Once

Run the script manually to perform the initial setup. The script will prompt you for your GitHub PAT if it’s not provided as an environment variable.

```bash
~/update_github_org_ssh_keys.sh
```

The script will:
- **Install `jq`** if it's not already installed.
- Fetch SSH keys from the GitHub organization members.
- Create or update the `github_authorized_keys` file with these keys and set it to `600` permissions.
- Modify the `sshd_config` to include this file for SSH authentication.
- Set up a cron job to update the keys every hour.

**Note:** You may be prompted for `sudo` permissions to install `jq`, modify `sshd_config`, and restart the SSH service.

### Step 4: Verify the SSH Configuration

To ensure the SSH configuration was modified successfully:

1. Open `sshd_config`:
   ```bash
   sudo nano /etc/ssh/sshd_config
   ```

2. Look for the line:
   ```plaintext
   AuthorizedKeysFile .ssh/authorized_keys .ssh/github_authorized_keys
   ```

3. If the line exists, then the SSH server is configured to check both `authorized_keys` and `github_authorized_keys` for allowed SSH keys.

4. Close the file by pressing `CTRL + X`.

### Step 5: Verify the Cron Job

To confirm that the cron job was created:

1. Open the cron jobs list:
   ```bash
   crontab -l
   ```

2. You should see an entry like this:
   ```plaintext
   0 * * * * /path/to/update_github_org_ssh_keys.sh
   ```
   This ensures the script will run every hour to fetch and update SSH keys.

---

### Final Script: `update_github_org_ssh_keys.sh`

Here’s the script with automatic installation of `jq`, a prompt for the GitHub token, and setting `600` permissions on `github_authorized_keys`.

```bash
#!/bin/bash

# GitHub Organization name
ORG="BabsyIT"

# Prompt for GitHub token if not set
if [ -z "$GITHUB_TOKEN" ]; then
    read -sp "Enter your GitHub Personal Access Token (PAT): " GITHUB_TOKEN
    echo
fi

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
```

### Troubleshooting

- **Rate Limits**: Without a GitHub token, the API requests may be limited for larger organizations or frequent updates. Ensure the `GITHUB_TOKEN` variable is correctly set.

### Notes

- This script is designed for use on a server you control, where you have permission to modify `sshd_config` and add cron jobs.
- Make sure you store your GitHub token securely and avoid exposing it.

With this setup, your server will automatically fetch and update GitHub organization member SSH keys every hour, allowing seamless access management.
