# Homebrew Self-Service Installer

A script designed for Jamf Pro deployment to streamline the installation of Homebrew on macOS devices. This script ensures proper setup for both Intel and ARM architectures, automates Xcode Command Line Tools installation, and configures user environments.

## Features
- Seamless deployment via Jamf Pro Self Service.
- Installs Homebrew on macOS (Intel and ARM architectures supported).
- Automatically sets up Xcode Command Line Tools if missing.
- Configures user shell profiles to include Homebrew in the PATH.
- Assigns ownership of Homebrew files to the user's admin account to adhere to **Security Essentials certification** requirements.
- Generates logs for easy troubleshooting.

## Prerequisites
- Jamf Pro environment for deployment.
- Network connectivity to download Homebrew and Xcode tools.

## Usage
1. Add the script to your Jamf Pro server:
   - Navigate to **Settings > Computer Management > Scripts**.
   - Upload `install_homebrew.sh` as a new script.

2. Configure a Jamf Pro policy:
   - Go to **Computers > Policies**.
   - Create a new policy and assign it to the target devices.
   - Add the script under the **Scripts** payload.
   - Optionally, make it available in **Self Service** with a user-friendly name.

3. Deploy or make the policy available in Self Service.

## Logs
- Logs are stored at `/private/var/log/Homebrew.log` for troubleshooting.

## Customisation
- Modify the `dialogMessage` or `dialogBanner` paths in the script to customise messaging or branding for your organisation.
- Adjust script variables for unique deployment needs.

## Contributing
Feel free to submit issues or pull requests to improve this tool.

## License
This project is licensed under the MIT License - see the LICENSE file for details.
