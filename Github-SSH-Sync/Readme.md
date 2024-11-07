## Manual: Setting Up Automated GitHub SSH Key Fetching on Your Server (Direct Download)

### Prerequisites
- **Debian 12** or a similar Linux distribution.
- **GitHub Personal Access Token** with at least read permissions to the GitHub organization’s public information.

### Step 1: Download and Set Up the Script with `curl`

1. **Open a terminal** on your server.
2. **Run the following `curl` command** to download and set up the script in one step:

   ```bash
   curl -o ~/update_github_org_ssh_keys.sh https://raw.githubusercontent.com/BabsyIT/Babsy-Infra_Public/refs/heads/main/Github-SSH-Sync/update_github_org_ssh_keys.sh
   ```

3. **Make the script executable**:

   ```bash
   chmod +x ~/update_github_org_ssh_keys.sh
   ```

4. **Edit the Script to Add Your GitHub Token**:

   Open the script to replace the placeholder token with your actual GitHub token.

   ```bash
   nano ~/update_github_org_ssh_keys.sh
   ```

5. Find this line in the script:

   ```bash
   GITHUB_TOKEN="your_personal_access_token_here"
   ```

   Replace `"your_personal_access_token_here"` with your actual GitHub token.

6. **Save and exit** the file in Nano by pressing `CTRL + X`, then `Y`, and `Enter`.

### Step 2: Run the Script Manually Once

Run the script manually to perform the initial setup:

```bash
~/update_github_org_ssh_keys.sh
```

The script will:
- **Install `jq`** if it's not already installed.
- Fetch SSH keys from the GitHub organization members.
- Create or update the `github_authorized_keys` file with these keys.
- Modify the `sshd_config` to include this file for SSH authentication.
- Set up a cron job to update the keys every hour.

**Note:** You may be prompted for `sudo` permissions to install `jq`, modify `sshd_config`, and restart the SSH service.

### Step 3: Verify the SSH Configuration

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

### Step 4: Verify the Cron Job

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

### Step 5: Test SSH Access (Optional)

Try connecting to the server using an SSH key from one of the GitHub organization members to verify that access is granted based on the updated `github_authorized_keys`.

---

### Final Script: `update_github_org_ssh_keys.sh`

Here’s the script with automatic installation of `jq`.

```bash
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
```

### Troubleshooting

- **Permission Denied Errors**: Ensure that `github_authorized_keys` has `600` permissions. Run `chmod 600 ~/.ssh/github_authorized_keys` if needed.
- **Rate Limits**: Without a GitHub token, the API requests may be limited for larger organizations or frequent updates. Ensure the `GITHUB_TOKEN` variable is correctly set.

### Notes

- This script is designed for use on a server you control, where you have permission to modify `sshd_config` and add cron jobs.
- Make sure you store your GitHub token securely and avoid exposing it.

With this setup, your server will automatically fetch and update GitHub organization member SSH keys every hour, allowing seamless access management.
