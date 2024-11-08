Absolutely! Here’s a detailed manual for setting up the script to automatically fetch GitHub SSH keys from an organization and store them in a designated `authorized_keys` file on your server.

---

## Manual: Setting Up Automated GitHub SSH Key Fetching on Your Server

This guide will walk you through setting up a script that retrieves public SSH keys of all members in a GitHub organization and stores them in an authorized keys file on a server. The script will run every hour to update the SSH keys automatically.

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
- **Install `jq`** if it's not already installed (used for JSON parsing).
- **Fetch SSH keys** from the GitHub organization members.
- **Create or update** the `github_authorized_keys` file with these keys, ensuring each key is on a single line with an identifier for easy reference.
- **Modify `sshd_config`** to include this file for SSH authentication.
- **Set up a cron job** to update the keys every hour automatically.

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

3. If the line exists, the SSH server is configured to check both `authorized_keys` and `github_authorized_keys` for allowed SSH keys.

4. Close the file by pressing `CTRL + X`.

### Step 5: Verify the Cron Job

To confirm that the cron job was created:

1. Open the cron jobs list:
   ```bash
   crontab -l
   ```

2. You should see an entry similar to:
   ```plaintext
   0 * * * * /path/to/update_github_org_ssh_keys.sh
   ```
   This ensures the script will run every hour to fetch and update SSH keys.

### Script Explanation

Each time the script runs, it:
1. **Retrieves all members** of the specified GitHub organization.
2. **Fetches each member’s public SSH keys** and stores them in the `github_authorized_keys` file.
3. **Adds the key title as a comment** next to each key for identification.
4. **Restarts the SSH service** (if needed) to apply the updated configuration.

### Script Source Code

Here's the source code of the script you just set up. Feel free to modify the file path for the authorized keys file or change the frequency of the cron job as needed.

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

# Add cron job if it doesn't already exist
(crontab -l | grep -q "$GITHUB_AUTHORIZED_KEYS_FILE") || (crontab -l; echo "$CRON_JOB") | crontab -
echo "Cron job created to run every hour."
```

### Troubleshooting

- **Permission Denied Errors**: Ensure that `github_authorized_keys` has `600` permissions. The script sets these automatically.
- **Rate Limits**: Without a GitHub token, the API requests may be limited for larger organizations or frequent updates. Ensure the `GITHUB_TOKEN` variable is correctly set.

### Notes

- This setup assumes you have root access or sudo privileges to modify `sshd_config` and manage cron jobs.
- Make sure you store your GitHub token securely and avoid exposing it.

With this setup, your server will automatically fetch and update GitHub organization member SSH keys every hour, allowing seamless access management.
