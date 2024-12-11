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
        sed -i "/^\[Time\]/a\\$FALLBACK_NTP" "$CONFIG_FILE"
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
apt install -y wget tar unzip > /dev/null
check_command "Failed to install required packages."

progress 60 "Downloading and installing .NET 9..."
# Step 8: Download and install .NET 9
mkdir -p "$DOTNET_INSTALL_DIR"
DOTNET_URL="https://download.visualstudio.microsoft.com/download/pr/93a7156d-01ef-40a1-b6e9-bbe7602f7e8b/3c93e90c63b494972c44f073e15bfc26/dotnet-sdk-9.0.101-linux-arm64.tar.gz"
DOTNET_INSTALL_DIR="$HOME/dotnet"

wget -O dotnet-sdk.tar.gz "$DOTNET_URL"
check_command "Failed to download .NET SDK."


tar zxf dotnet-sdk.tar.gz -C "$DOTNET_INSTALL_DIR"
check_command "Failed to extract .NET SDK."

export DOTNET_ROOT="$DOTNET_INSTALL_DIR"
export PATH="$PATH:$DOTNET_INSTALL_DIR"

# Add to bashrc
echo "export DOTNET_ROOT=$DOTNET_INSTALL_DIR" >> "$HOME/.bashrc"
echo "export PATH=\$PATH:$DOTNET_INSTALL_DIR" >> "$HOME/.bashrc"
source "$HOME/.bashrc"

progress 70 "Downloading and installing CodeProject.AI..."
# Step 9: Download and install CodeProject.AI
CODEPROJECT_URL="https://codeproject-ai-bunny.b-cdn.net/server/installers/linux/codeproject.ai-server_2.9.5_Ubuntu_arm64.zip"

wget -O codeproject.zip "$CODEPROJECT_URL"
check_command "Failed to download CodeProject.AI."

unzip codeproject.zip
check_command "Failed to unzip CodeProject.AI package."

CODEPROJECT_DEB="codeproject.ai-server_2.9.5_Ubuntu_arm64.deb"
sudo dpkg -i "$CODEPROJECT_DEB"
check_command "Failed to install CodeProject.AI."

progress 100 "All tasks completed successfully!"
echo -e "\nNTP synchronization configured, .NET 9 installed, and CodeProject.AI setup completed successfully."

# Display total elapsed time
ELAPSED_TIME=$SECONDS
echo -e "\nScript completed in $(($ELAPSED_TIME / 60)) minutes and $(($ELAPSED_TIME % 60)) seconds."