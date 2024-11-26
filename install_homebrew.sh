#!/bin/bash

# Function to log messages
logme() {
    if [ -z "$1" ] ; then
        echo "$(date) - logme function call error: no text passed to function! Please recheck code!" | tee -a $LOG
        exit 1
    fi
    echo -e "$(date) - $1" | tee -a $LOG
}

# Set up log file
LOGFOLDER="/private/var/log/"
LOG="${LOGFOLDER}Homebrew.log"

if [ ! -d "$LOGFOLDER" ]; then
    mkdir -p $LOGFOLDER
fi

logme "Script started."

# Get the currently logged in user
currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
logme "Current logged-in user: $currentUser"

dialogBanner="/path/to/default/banner.png"
dialogTitle="Administrator Account Not Found"
dialogMessage="You do not have an administrator account assigned to your machine. \n Please contact your IT support team for assistance."



# Check if the admin username contains "admin" and exists on the machine
admin_prefix="admin."
userExists=false
admin_username=""
IFS='.' read -r first_name last_name <<< "$currentUser"
admin_prefix="admin."  # Assuming a prefix for demonstration
Possible_usernames=(
    "${admin_prefix}${first_name}.${last_name}"
    "${admin_prefix}${first_name:0:1}.${last_name}"
    "${admin_prefix}${first_name}.${last_name:0:1}"
    "${admin_prefix}${first_name:0:1}.${last_name:0:1}"
)


for Possible_username in "${Possible_usernames[@]}"; do
    echo "Checking: $Possible_username"  # Debug statement
    if id "$Possible_username" &>/dev/null; then
        echo "Account found: $Possible_username"
        userExists=true
        admin_username="$Possible_username"
        break
    fi
done

if ! $userExists; then
    echo "No admin account found"
    /usr/local/bin/dialog -t "$dialogTitle" --titlefont "colour=#248F86,weight=light,size=30" -m "$dialogMessage" --messagefont "weight=light,size=15" --alignment "center" --bannerimage "$dialogBanner" --button1text "Cancel" --moveable --ontop --small --position "center"
    logme "No corresponding admin username found for $currentUser."
    exit 1
fi


ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then
    HOMEBREW_PREFIX="/usr/local"
else
    HOMEBREW_PREFIX="/opt/homebrew"
fi
logme "Architecture detected: $ARCH, setting Homebrew prefix to $HOMEBREW_PREFIX."


add_brew_shellenv() {
    local user_profile=$1
    local brew_shellenv_command="eval \"\$(${HOMEBREW_PREFIX}/bin/brew shellenv)\""

    if ! grep -qF "$brew_shellenv_command" "$user_profile"; then
        echo "$brew_shellenv_command" >> "$user_profile"
        logme "Added Homebrew environment setup to $user_profile."
    else
        logme "Homebrew environment setup already present in $user_profile."
    fi
}

is_xcode_installed() {
    local clang_path="/Library/Developer/CommandLineTools/usr/bin/clang"
    if [ -f "$clang_path" ]; then
        return 0  # true, clang is installed
    else
        return 1  # false, clang is not found
    fi
}

install_xcode() {
    echo "Installing Xcode"
    logme "Installing Xcode"
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
    PROD=$(softwareupdate -l |
        grep "\*.*Command Line" |
        tail -n 1 | sed 's/^[^C]* //')
    softwareupdate -i "$PROD" --verbose;
}

verify_xcode_installation() {
    local max_retries=30
    local count=0

    while ! is_xcode_installed; do
        if [ "$count" -ge "$max_retries" ]; then
            logme "Xcode Command Line Tools installation timed out."
            return 1
        fi
        logme "Waiting for Xcode Command Line Tools to be installed..."
        sleep 20
        ((count++))
    done
    logme "Xcode Command Line Tools installed successfully."
    sleep 40
    return 0
}

# Main script logic
if is_xcode_installed; then
    logme "Xcode Command Line Tools are already installed."
else
    logme "Xcode Command Line Tools are not installed. Installing now..."
    install_xcode
    verify_xcode_installation
    if [ $? -ne 0 ]; then
        logme "Error: Xcode Command Line Tools installation failed or timed out."
        exit 1
    fi
fi

if [[ ! -e "${HOMEBREW_PREFIX}/bin/brew" ]]; then
    logme "Installing Homebrew."

    mkdir -p "${HOMEBREW_PREFIX}/Homebrew"
    curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C "${HOMEBREW_PREFIX}/Homebrew"
    logme "Homebrew downloaded and unpacked."

    mkdir -p "${HOMEBREW_PREFIX}/Cellar" "${HOMEBREW_PREFIX}/Homebrew"
    mkdir -p "${HOMEBREW_PREFIX}/Caskroom" "${HOMEBREW_PREFIX}/Frameworks" "${HOMEBREW_PREFIX}/bin"
    mkdir -p "${HOMEBREW_PREFIX}/include" "${HOMEBREW_PREFIX}/lib" "${HOMEBREW_PREFIX}/opt" "${HOMEBREW_PREFIX}/etc" "${HOMEBREW_PREFIX}/sbin"
    mkdir -p "${HOMEBREW_PREFIX}/share/zsh/site-functions" "${HOMEBREW_PREFIX}/var"
    mkdir -p "${HOMEBREW_PREFIX}/share/doc" "${HOMEBREW_PREFIX}/man/man1" "${HOMEBREW_PREFIX}/share/man/man1"
    logme "Homebrew directories created."

    chown -R "$admin_username" "${HOMEBREW_PREFIX}"
    chmod -R g+rwx "${HOMEBREW_PREFIX}/*"
    chmod 755 "${HOMEBREW_PREFIX}/share/zsh" "${HOMEBREW_PREFIX}/share/zsh/site-functions"
    logme "Homebrew directories permissions set."

    mkdir -p /Library/Caches/Homebrew
    chmod g+rwx /Library/Caches/Homebrew
    chown "${admin_username}" /Library/Caches/Homebrew
    logme "Homebrew cache directory created."

    ln -s "${HOMEBREW_PREFIX}/Homebrew/bin/brew" "${HOMEBREW_PREFIX}/bin/brew"
    logme "Homebrew binary linked."


    # Set environment variables to make the brew install command non-interactive
    export HOMEBREW_NO_AUTO_UPDATE=1
    export HOMEBREW_NO_INSTALL_CLEANUP=1

    # Run the Homebrew install command non-interactively
    brew_output=$(su -l "$admin_username" -c "HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 ${HOMEBREW_PREFIX}/bin/brew install md5sha1sum" 2>&1)
    # Log the output using the logme function
    logme "Homebrew install md5sha1sum output: $brew_output"
    echo "export PATH=\"${HOMEBREW_PREFIX}/opt/openssl/bin:\$PATH\"" >> "/Users/$admin_username/.zprofile"
    logme "Appended OpenSSL path to .zprofile"
    echo "export PATH=\"${HOMEBREW_PREFIX}/opt/openssl/bin:\$PATH\"" >> "/Users/$admin_username/.bash_profile"
    logme "Appended OpenSSL path to .bash_profile"
    chown ${admin_username} /Users/${admin_username}/.bash_profile /Users/${admin_username}/.zshrc
    logme "Changed ownership of profile files"
    
fi

logme "Finished Homebrew install script. Out of function."
admin_profiles=("/Users/$admin_username/.zprofile" "/Users/$admin_username/.bash_profile")
current_user_profiles=("/Users/$currentUser/.zprofile" "/Users/$currentUser/.bash_profile")

for profile in "${admin_profiles[@]}"; do
    add_brew_shellenv "$profile"
done

for profile in "${current_user_profiles[@]}"; do
    add_brew_shellenv "$profile"
done

logme "Updated profile files for Homebrew environment."

sudo chown "$admin_username" "/Users/$admin_username/.zprofile" "/Users/$admin_username/.bash_profile"
sudo chown "$currentUser" "/Users/$currentUser/.zprofile" "/Users/$currentUser/.bash_profile"
logme "Corrected ownership of profile files."

logme "Brew installation and configuration completed."
