# ExoidRobotics Raspberry Pi Setup Script

### Overview
Welcome to the official Raspberry Pi setup script by **ExoidRobotics**. This script automates the installation and configuration process for setting up **CodeProject.AI** and the .NET SDK on a Raspberry Pi, along with necessary system updates and configurations.

### Features
- Configures NTP synchronization for accurate time settings.
- Updates and upgrades the Raspberry Pi system packages.
- Installs essential dependencies (\`wget\`, \`tar\`, \`libunwind8\`, \`libicu-dev\`).
- Downloads and extracts the .NET SDK.
- Configures environment variables for .NET.
- Prepares your Raspberry Pi for **CodeProject.AI** integration.

### Prerequisites
- A Raspberry Pi with Raspberry Pi OS installed.
- Administrative (\`sudo\`) privileges to run the script.

### Installation Instructions
1. **Clone or Download the Repository**:
   \`\`\`bash
   git clone https://github.com/riegojerey/ExoidBashScript.git
   cd RaspberryPiSetup
   \`\`\`

2. **Make the Script Executable**:
   \`\`\`bash
   chmod +x exoidsetup.sh
   \`\`\`

3. **Run the Script**:
   Execute the script as \`root\` to ensure all tasks are completed successfully:
   \`\`\`bash
   sudo ./exoidsetup.sh
   \`\`\`

### Script Workflow
1. **Time Synchronization**:
   - Configures \`/etc/systemd/timesyncd.conf\` to use \`FallbackNTP=time.nist.gov\`.
   - Enables NTP synchronization and restarts the time synchronization service.

2. **System Update**:
   - Updates the package list and performs a full system upgrade.

3. **Dependency Installation**:
   - Installs required packages: \`wget\`, \`tar\`, \`libunwind8\`, \`libicu-dev\`.

4. **.NET SDK Setup**:
   - Downloads the .NET SDK from the official Microsoft source.
   - Extracts the SDK to \`$HOME/dotnet\`.

5. **Environment Configuration**:
   - Adds environment variables to \`~/.bashrc\`:
     - \`DOTNET_ROOT=$HOME/dotnet\`
     - Updates the \`PATH\` to include \`$HOME/dotnet\`.
   - Reloads the environment variables.

### Post-Setup Verification
After running the script, verify the setup:

1. **Check .NET Installation**:
   \`\`\`bash
   dotnet --version
   \`\`\`
   You should see the installed version of the .NET SDK.

2. **Check Time Synchronization**:
   \`\`\`bash
   timedatectl
   \`\`\`
   Ensure NTP is active and synchronized.