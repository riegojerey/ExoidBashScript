#!/bin/bash

CONFIG_FILE="/etc/systemd/timesyncd.conf"
BACKUP_FILE="/etc/systemd/timesyncd.conf.bak"
FALLBACK_NTP="FallbackNTP=time.nist.gov"
DOTNET_URL="https://download.visualstudio.microsoft.com/download/pr/93a7156d-01ef-40a1-b6e9-bbe7602f7e8b/3c93e90c63b494972c44f073e15bfc26/dotnet-sdk-9.0.101-linux-arm64.tar.gz"
DOTNET_FILE="dotnet-runtime.tar.gz"
DOTNET_DIR="$HOME/dotnet"

# Function to check the last command status
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
        exit 1
    fi
}

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root!"
    exit 1
fi

# Step 1: Backup the original configuration file
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo "Backup created: $BACKUP_FILE"
else
    echo "Configuration file not found at $CONFIG_FILE!"
    exit 1
fi

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

# Step 3: Enable NTP synchronization
echo "Enabling NTP synchronization..."
timedatectl set-ntp true
check_command "Failed to enable NTP synchronization."

# Step 4: Restart the systemd-timesyncd service
echo "Restarting systemd-timesyncd service..."
systemctl restart systemd-timesyncd
check_command "Failed to restart systemd-timesyncd service."

# Step 5: Update the package lists
echo "Updating package lists..."
apt update -y
check_command "Failed to update package lists."

# Step 6: Perform a full system upgrade
echo "Performing a full system upgrade..."
apt full-upgrade -y
check_command "Failed to perform system upgrade."

# Step 7: Install required packages
echo "Installing required packages..."
apt install -y wget tar libunwind8 libicu-dev
check_command "Failed to install required packages."

# Step 8: Download the .NET SDK
echo "Downloading .NET SDK..."
wget "$DOTNET_URL" -O "$DOTNET_FILE"
check_command "Failed to download .NET SDK."

# Step 9: Create the .NET directory and extract the SDK
echo "Setting up .NET SDK..."
if [ ! -d "$DOTNET_DIR" ]; then
    mkdir -p "$DOTNET_DIR"
    echo "Directory $DOTNET_DIR created."
fi
tar -zxf "$DOTNET_FILE" -C "$DOTNET_DIR"
check_command "Failed to extract .NET SDK to $DOTNET_DIR."

# Step 10: Update ~/.bashrc to include environment variables
echo "Configuring environment variables..."
BASHRC="$HOME/.bashrc"
if ! grep -q "export DOTNET_ROOT=$DOTNET_DIR" "$BASHRC"; then
    echo "export DOTNET_ROOT=$DOTNET_DIR" >> "$BASHRC"
    echo "export PATH=\$PATH:$DOTNET_DIR" >> "$BASHRC"
    echo "Environment variables added to $BASHRC."
else
    echo "Environment variables already present in $BASHRC."
fi

# Step 11: Reload ~/.bashrc
echo "Reloading environment variables..."
source "$BASHRC"
check_command "Failed to reload environment variables."

# Step 12: Test the dotnet installation
echo "Testing .NET installation..."
dotnet --version
check_command "dotnet command not found. Check your installation."

echo "All tasks completed successfully."
