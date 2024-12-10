# ExoidRobotics Raspberry Pi Setup Script

## Features
- Configures NTP synchronization for accurate time settings.
- Updates and upgrades the Raspberry Pi system packages.
- Installs essential dependencies (`wget`, `tar`, `libunwind8`, `libicu-dev`).
- Sets up **Docker** and runs the **CodeProject.AI** container.
- Ensures the container auto-restarts on system reboot.
- Provides a clear progress indication during execution.

## Prerequisites
- A Raspberry Pi with Raspberry Pi OS installed.
- Administrative (`sudo`) privileges to run the script.

### Installation Instructions
1. **Clone or Download the Repository**:
   ```bash
   git clone https://github.com/riegojerey/ExoidBashScript.git
   cd RaspberryPiSetup
   ```

2. **Make the Script Executable**:
   ```bash
   chmod +x exoidsetup.sh
   ```

3. **Run the Script**:
   Execute the script as `root` to ensure all tasks are completed successfully:
   ```bash
   sudo ./exoidsetup.sh
   ```

