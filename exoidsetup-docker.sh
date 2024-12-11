#!/bin/bash

CONFIG_FILE="/etc/systemd/timesyncd.conf"
BACKUP_FILE="/etc/systemd/timesyncd.conf.bak"
FALLBACK_NTP="FallbackNTP=time.nist.gov"

# Initialize the timer
SECONDS=0

# Function to check the last command status
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
        exit 1
    fi
}

# Progress function
progress() {
    echo -ne "[$1%] $2\r"
}

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root!"
    exit 1
fi

progress 5 "Backing up timesyncd configuration..."
# Step 1: Backup the original configuration file
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo "Backup created: $BACKUP_FILE"
else
    echo "Configuration file not found at $CONFIG_FILE!"
    exit 1
fi

progress 10 "Configuring NTP settings..."
# Step 2: Add FallbackNTP under [Time] section if not already present
if grep -q "^\[Time\]" "$CONFIG_FILE"; then
    if ! grep -q "$FALLBACK_NTP" "$CONFIG_FILE"; then
        sed -i '/^\[Time\]/a\'"$FALLBACK_NTP" "$CONFIG_FILE"
        echo "Added $FALLBACK_NTP to $CONFIG_FILE."
    else
        echo "$FALLBACK_NTP is already present in $CONFIG_FILE."
    fi
else
    echo "[Time] section not found in $CONFIG_FILE. Adding it."
    echo -e "\n[Time]\n$FALLBACK_NTP" >> "$CONFIG_FILE"
fi

progress 15 "Enabling NTP synchronization..."
# Step 3: Enable NTP synchronization
timedatectl set-ntp true
check_command "Failed to enable NTP synchronization."

progress 20 "Restarting systemd-timesyncd service..."
# Step 4: Restart the systemd-timesyncd service
systemctl restart systemd-timesyncd
check_command "Failed to restart systemd-timesyncd service."

progress 30 "Updating package lists..."
# Step 5: Update the package lists
apt update -y > /dev/null
check_command "Failed to update package lists."

progress 40 "Performing a full system upgrade..."
# Step 6: Perform a full system upgrade
apt full-upgrade -y > /dev/null
check_command "Failed to perform system upgrade."

progress 50 "Installing required packages..."
# Step 7: Install required packages
apt install -y wget tar libunwind8 libicu-dev > /dev/null
check_command "Failed to install required packages."

progress 55 "Removing conflicting packages for Docker..."
# Step 8: Uninstall conflicting packages
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    apt-get remove -y "$pkg" > /dev/null
done
check_command "Failed to remove conflicting packages."

progress 60 "Setting up Docker's APT repository..."
# Step 9: Set up Docker's apt repository
apt-get install -y ca-certificates curl > /dev/null
check_command "Failed to install dependencies for Docker."

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
check_command "Failed to configure Docker's GPG key."

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y > /dev/null
check_command "Failed to set up Docker's APT repository."

progress 70 "Installing Docker..."
# Step 10: Install Docker
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null
check_command "Failed to install Docker."

progress 80 "Pulling CodeProject.AI image..."
# Step 11: Pull Docker image for CodeProject.AI
docker pull codeproject/ai-server:rpi64-2.9.5
check_command "Failed to pull CodeProject.AI Docker image."

progress 90 "Running CodeProject.AI container..."
# Step 12: Run Docker container and set to restart on boot
docker run --name CodeProject.AI -d --restart unless-stopped -p 32168:32168 codeproject/ai-server:rpi64-2.9.5
check_command "Failed to start CodeProject.AI container."

progress 100 "All tasks completed successfully!"
echo -e "\nNTP synchronization configured, Docker installed, and CodeProject.AI container setup completed successfully."

# Display total elapsed time
ELAPSED_TIME=$SECONDS
echo -e "\nScript completed in $(($ELAPSED_TIME / 60)) minutes and $(($ELAPSED_TIME % 60)) seconds."
