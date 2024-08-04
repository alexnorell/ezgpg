#!/bin/zsh

# Define color variables
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
RESET='\033[0m'

# Random text color
COLORS=($RED $GREEN $YELLOW $BLUE $MAGENTA $CYAN)
RANDOM_INDEX=$(( $RANDOM % ${#COLORS[@]} ))
RAND_COLOR=${COLORS[RANDOM_INDEX+1]}

CHECK="${GREEN}✔${RESET}"
CROSS="${RED}✘${RESET}"

# Encryption types
key_types=("rsa4096: RSA key with 4096 bits" "ed25519: Ed25519 key")
expire="1y"

INSTRUCTIONS="
You'll need to have the following prepared before running this script to
completion:
1. Pen and paper to write down passphrases and pins
2. External disk plugged in and mounted
3. A single Yubikey plugged in

EZGPG will check for the presence of the necessary packages, and prompt to
install them if missing. You will only need an internet connection if the
packages are missing.

The PGP application on your Yubikey will be reset, wiping the keys stored
there.
"

logo() {
    echo "
    ${RAND_COLOR}███████${RESET}╗${RAND_COLOR}███████${RESET}╗ ${RAND_COLOR}██████${RESET}╗ ${RAND_COLOR}██████${RESET}╗  ${RAND_COLOR}██████${RESET}╗
    ${RAND_COLOR}██${RESET}╔════╝╚══${RAND_COLOR}███${RESET}╔╝${RAND_COLOR}██${RESET}╔════╝ ${RAND_COLOR}██${RESET}╔══${RAND_COLOR}██${RESET}╗${RAND_COLOR}██${RESET}╔════╝
    ${RAND_COLOR}█████${RESET}╗    ${RAND_COLOR}███${RESET}╔╝ ${RAND_COLOR}██${RESET}║  ${RAND_COLOR}███${RESET}╗${RAND_COLOR}██████${RESET}╔╝${RAND_COLOR}██${RESET}║  ${RAND_COLOR}███${RESET}╗
    ${RAND_COLOR}██${RESET}╔══╝   ${RAND_COLOR}███${RESET}╔╝  ${RAND_COLOR}██${RESET}║   ${RAND_COLOR}██${RESET}║${RAND_COLOR}██${RESET}╔═══╝ ${RAND_COLOR}██${RESET}║   ${RAND_COLOR}██${RESET}║
    ${RAND_COLOR}███████${RESET}╗${RAND_COLOR}███████${RESET}╗╚${RAND_COLOR}██████${RESET}╔╝${RAND_COLOR}██${RESET}║     ╚${RAND_COLOR}██████${RESET}╔╝
    ${RESET}╚══════╝╚══════╝ ╚═════╝ ╚═╝      ╚═════╝
           Quick and Easy GPG Set Up
               ${CYAN}https://ezgpg.com${RESET}
"
}

new_line() {
    echo ""
}

detect_os() {
    local os
    case "$(uname)" in
        "Darwin")
            os="macOS"
            ;;
        "Linux")
            os="Linux"
            ;;
        *)
            os="Unknown"
            ;;
    esac
    echo $os
}

is_program_available() {
    local program=$1

    if command -v $program >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

prompt_installation() {
    local os_type=$1
    local program=$2
    local package=$3

    if [[ $os_type == "macOS" ]]; then
        printf "Do you want to install $program with brew? (y/N): "
        read response
        if [[ $response == "y" || $response == "Y" ]]; then
            echo "brew install --quiet $package"
            brew install --quiet $package
            if is_program_available $program; then
                echo "$CHECK $program: Installed successfully."
                return 0
            else
                echo "$CROSS $program: Failed to install."
                return 1
            fi
        else
            echo "$CROSS $program: Installation skipped."
            return 1
        fi
    elif [[ $os_type == "Linux" ]]; then
        echo "$CROSS $program: Not available. Please install using your package manager."
        echo "For example:"
        if command -v apt-get >/dev/null 2>&1; then
            echo "sudo apt-get install $package"
        elif command -v yum >/dev/null 2>&1; then
            echo "sudo yum install $package"
        elif command -v dnf >/dev/null 2>&1; then
            echo "sudo dnf install $package"
        elif command -v pacman >/dev/null 2>&1; then
            echo "sudo pacman -S $package"
        else
            echo "Please install $package using your package manager."
        fi
        return 1
    else
        echo "$CROSS Unsupported operating system."
        return 1
    fi
}

check_pinentry_on_linux() {
    local pinentry_programs=("pinentry-curses" "pinentry-fltk" "pinentry-gnome3" "pinentry-gtk2" "pinentry-qt" "pinentry-tty" "pinentry-x2go")
    local installed_program=""

    for program in "${pinentry_programs[@]}"; do
        if is_program_available $program; then
            installed_program=$program
            break
        fi
    done

    if [[ -n $installed_program ]]; then
        echo "$CHECK pinentry program found: $installed_program"
    else
        echo "$CROSS No pinentry program found. Please install one of the following using your package manager:"
        echo "pinentry-curses, pinentry-fltk, pinentry-gnome3, pinentry-gtk2, pinentry-qt, pinentry-tty, pinentry-x2go"
    fi
}

check_programs() {
    local programs=("$@")
    local unavailable_programs=()
    local os_type=$(detect_os)

    echo "Applications:"
    for program_package in "${programs[@]}"; do
        IFS=',' read -r program package <<< "$program_package"
        if ! is_program_available $program; then
            echo "$CROSS $program: Not available"
            unavailable_programs+=("$program,$package")
        else
            echo "$CHECK $program: Available"
        fi
    done

    if [[ $os_type == "Linux" ]]; then
        check_pinentry_on_linux
    elif [[ $os_type == "macOS" ]]; then
        if ! is_program_available "pinentry-mac"; then
            echo "$CROSS pinentry-mac: Not available"
            unavailable_programs+=("pinentry-mac,pinentry-mac")
        else
            echo "$CHECK pinentry-mac: Available"
        fi
    fi

    if [[ ${#unavailable_programs[@]} -gt 0 ]]; then
        echo "Some applications are not available. Prompting for installation..."
        for program_package in "${unavailable_programs[@]}"; do
            IFS=',' read -r program package <<< "$program_package"
            prompt_installation $os_type $program $package
        done

        local all_available=true
        local final_results=""
        for program_package in "${programs[@]}"; do
            IFS=',' read -r program package <<< "$program_package"
            if is_program_available $program; then
                final_results+="$CHECK $program: Available\n"
            else
                final_results+="$CROSS $program: Not available\n"
                all_available=false
            fi
        done

        if [[ $os_type == "Linux" ]]; then
            if check_pinentry_on_linux; then
                final_results+="$CHECK pinentry program: Available\n"
            else
                final_results+="$CROSS pinentry program: Not available\n"
                all_available=false
            fi
        elif [[ $os_type == "macOS" ]]; then
            if is_program_available "pinentry-mac"; then
                final_results+="$CHECK pinentry-mac: Available\n"
            else
                final_results+="$CROSS pinentry-mac: Not available\n"
                all_available=false
            fi
        fi

        if ! $all_available; then
            echo "Some applications are still not available. Please install the necessary applications."
            echo -e "$final_results"
            exit 1
        fi
    fi

}

# Function to prompt the user for input
prompt_user() {
    local prompt_message="$1"
    local user_input
    read -r "user_input?$prompt_message"
    echo "$user_input"
}

# Function to get GPG version
get_gpg_version() {
    gpg --version | awk '/^gpg \(GnuPG\)/ {print $3}'
}

# Function to retrieve the default global Git email
get_git_email() {
    git config --global user.email
}

# Function to retrieve the default global Git name
get_git_name() {
    git config --global user.name
}

# Function to check Git email and name
check_git_config() {
    local git_email
    local git_name
    local user_input

    git_email=$(get_git_email)
    git_name=$(get_git_name)
    echo "User configuration:"
    echo "${YELLOW}→${RESET} Name:  $git_name"
    echo "${YELLOW}→${RESET} Email: $git_email"

    user_input=$(prompt_user "Are these values correct? (y/N): ")

    if [[ "$user_input" =~ ^[Yy]$ ]]; then
        [ "$verbose" = true ] && echo "No changes made."
    else
         git_name=$(prompt_user "New name:  ")
        git_email=$(prompt_user "New email: ")

        echo "${YELLOW}→${RESET} Updated name:  $git_name"
        echo "${YELLOW}→${RESET} Updated email: $git_email"

        echo "GPG keys and git commits need to match exactly for the email and name to be valid."
        user_input=$(prompt_user "Do you want to configure git with these values? (y/N): ")

        if [[ "$user_input" =~ ^[Yy]$ ]]; then
            git config --global user.email "$git_email"
            git config --global user.name "$git_name"
            echo "$CHECK Git configuration updated."
        else
            [ "$verbose" = true ] && echo "No changes made."
        fi
    fi
}

harden_gpg_conf() {
    local gpg_conf_file="$HOME/.gnupg/gpg.conf"
    echo "Hardening GPG configuration"
    # Define the content to be added to gpg.conf
    local gpg_conf_content=$(cat <<EOF
personal-cipher-preferences AES256 AES192 AES
personal-digest-preferences SHA512 SHA384 SHA256
personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed
default-preference-list SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed
cert-digest-algo SHA512
s2k-digest-algo SHA512
s2k-cipher-algo AES256
charset utf-8
no-comments
no-emit-version
no-greeting
keyid-format 0xlong
list-options show-uid-validity
verify-options show-uid-validity
with-fingerprint
require-cross-certification
no-symkey-cache
armor
use-agent
throw-keyids
EOF
    )

    # Ensure the gpg.conf file exists
    touch "$gpg_conf_file"

    # Append lines only if they aren't already present
    while IFS= read -r line; do
        if ! grep -Fxq "$line" "$gpg_conf_file"; then
            echo "$line" >> "$gpg_conf_file"
        fi
    done <<< "$gpg_conf_content"
}

check_internet_connection() {
    local test_domain="ezgpg.com"
    local timeout=1
    echo "Checking for internet connection. This will take a few seconds."
    if nslookup -timeout=$timeout "$test_domain" > /dev/null 2>&1; then
        return 0  # Success status
    else
        return 1  # Failure status
    fi
}

loop_until_disconnected() {
    while check_internet_connection; do
        echo "${CROSS} Internet connection is available."
        user_input=$(prompt_user "Do you want to check again? (y/N/skip): ")
        if [[ "$user_input" =~ ^[Ss][Kk][Ii][Pp]$ ]]; then
            echo "Skipping the check."
            return 0
        elif [[ ! "$user_input" =~ ^[Yy]$ ]]; then
            echo "Stopping the check."
            return 0
        fi
    done

    echo "No internet connection detected."
}

prompt_key_choice() {
    local choice
    set +H  # Disable history expansion
    while true; do
        echo "Please choose a key type:"
        for ((i = 1; i <= ${#key_types[@]}; i++)); do
            key="${key_types[$i]%%:*}"
            comment="${key_types[$i]#*: }"
            echo "$((i))) $key - $comment"
        done
        read -r "choice?> "

        if [[ "$choice" -ge 1 && "$choice" -le ${#key_types[@]} ]]; then
            set -H  # Re-enable history expansion
            return $((choice))  # Return the index of the selected key type
        else
            echo "Invalid option. Please enter a number between 1 and ${#key_types[@]}."
        fi
    done
}

generate_passphrase() {
    LC_ALL=C tr -dc 'A-Z1-9' < /dev/urandom | \
    tr -d "1IOS5U" | head -c 32 | sed 's/.\{4\}/&-/g' | \
    sed 's/-$//'
}


print_in_box() {
    local message="$1"
    local length=${#message}
    local top_border="╔═$(printf '═%.0s' $(seq 1 $length))═╗"
    local bottom_border="╚═$(printf '═%.0s' $(seq 1 $length))═╝"
    local middle="║ $message ║"

    echo "$top_border"
    echo "$middle"
    echo "$bottom_border"
}

print_section_title() {
    local title="$1"
    local length=${#title}
    local underline=$(printf '─%.0s' $(seq 1 $((length))))

    echo "$underline"
    echo "$title"
    echo "$underline"
}

select_external_drive() {
    local selected_mount_point_var=$1
    mounted_filesystems=$(mount)
    # Get a list of all external drives using diskutil
    external_drives=$(diskutil list external | awk '/^\/dev/ {print $1}')
    external_drives=("${(@f)external_drives}")

    # Loop through each external drive and find its mount points
    available_mount_points=()
    for drive in $external_drives; do
        # Get the mount point(s) of the drive
        mount_points=$(echo "$mounted_filesystems" | grep "$drive" | awk '{print $3}')
        read_only=$(echo "$mounted_filesystems" | grep "$drive" | grep -q 'read-only' && echo true || echo false)
        # If there are mount points, store them
        if [[ "$read_only" == false && -n "$mount_points" ]]; then
            mount_points=("${(@f)mount_points}")
            for mount_point in $mount_points; do
                available_mount_points+=("$mount_point")
            done
        fi
    done

    # Prompt the user to select a mount point
    if [ ${#available_mount_points[@]} -eq 0 ]; then
        echo "External Drive:\n${CROSS} No writable external drives found."
        exit 1
    fi

    echo "Please select an external drive for key backup:"
    for i in {1..${#available_mount_points[@]}}; do
        echo "$i) ${available_mount_points[$((i))]}"
    done

    local valid_choice=0
    while [[ $valid_choice -eq 0 ]]; do
        read "user_choice?> "
        if [[ "$user_choice" =~ ^[0-9]+$ ]] && [ "$user_choice" -ge 1 ] && [ "$user_choice" -le ${#available_mount_points[@]} ]; then
            valid_choice=1
        else
            echo "Invalid selection. Please try again."
        fi
    done

    selected_mount_point="${available_mount_points[$((user_choice))]}"
    eval "$selected_mount_point_var='$selected_mount_point'"
}

ensure_yubikey() {
    local count
    count=$(ykman list | wc -l)
    echo "Yubikey:"
    if [ "$count" -eq 0 ]; then
        echo "${CROSS} No yubikey found"
        exit 1
    elif [ "$count" -eq 1 ]; then
        ykman list
    else
        echo "${CROSS} More than one yubikey found. Only one can be plugged in"
        exit 1
    fi
}

ensure_gpg_key() {
    local identity="$1"
    local output
    output=$(gpg --list-keys "$identity" 2>&1)

    if [[ ! "$output" == *"gpg: error reading key: No public key"* ]]; then
        echo "\n${CROSS} GPG key for identity '$identity' already exists."
        exit 1
    fi
}

####################
### SCRIPT START ###
####################

# Parse command-line arguments
verbose=false
while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -v | --verbose )
    verbose=true
    ;;
esac; shift; done
if [[ "$1" == '--' ]]; then shift; fi

# Print header
logo
echo $INSTRUCTIONS

print_section_title "Requirements"

# Check programs
programs_to_check=(
    "gpg,gnupg"
    "ykman,ykman"
    "git,git"
)
check_programs "${programs_to_check[@]}"

# Check drive
# Pick an external drive to use for key backup
new_line
selected_drive=""
select_external_drive selected_drive

# Check yubikey
new_line
ensure_yubikey

# Internet check
new_line
echo "Best practice suggests that you disconnect from the internet. Check connection?"
internet_off_continue=$(prompt_user "Continue? (y/skip): ")
if [[ "$internet_off_continue" =~ ^[Ss][Kk][Ii][Pp]$ ]]; then
    echo "${YELLOW}!${RESET} Bypassing internet check"
elif [[ "$internet_off_continue" =~ ^[Yy]$ ]]; then
    loop_until_disconnected
fi
new_line

#########################
# Initial Configuration #
#########################
print_section_title "Initial Configuration"

# Check git config and set up if needed
check_git_config
user_name=$(get_git_name)
user_email=$(get_git_email)

# GPG identity
identity="$user_name <$user_email>"
[ "$verbose" = true ] && echo "GPG Identity: $identity"
ensure_gpg_key $identity

# Key types/algorithms
new_line
prompt_key_choice
key_type="${key_types[$?]%%:*}"  # Extract the key without the comment

# Put in best practices for GPG
new_line
harden_gpg_conf

# Set up temp-dir
gpg_temp=$(mktemp -d -t gnupg-$RANDOM)
cd $gpg_temp
[ "$verbose" = true ] && echo "GPG Temp dir: $gpg_temp"

##################
# Key Generation #
##################
print_section_title "Key generation"

echo "Generating passphrase...\nWrite this down somewhere secure:"

# Create Primary (Certify) key passphrase
passphrase=$(generate_passphrase)

print_in_box $passphrase

echo "Generating primary certify key..."
[ "$verbose" = true ] && echo "% gpg --batch --passphrase "$passphrase" --quick-generate-key "$identity" "$key_type" cert never"
gpg --batch --yes --passphrase "$passphrase" --quick-generate-key --no-tty "$identity" "$key_type" cert never

if [ ! $? -eq 0 ]; then
    echo "${CROSS} Failed to generate gpg key"
    exit 1
fi

primary_key_id=$(gpg -k --with-colons "$identity" | awk -F: '/^pub:/ { print $5; exit }')

primary_key_fingerprint=$(gpg -k --with-colons "$identity" | awk -F: '/^fpr:/ { print $10; exit }')

echo "${CHECK} Key generated with fingerprint: ${primary_key_fingerprint}"

for subkey in sign encrypt auth; do
    if [[ "$key_type" == "ed25519" && "$subkey" == "encrypt" ]]; then
        adjusted_key_type="cv25519"
    else
        adjusted_key_type="$key_type"
    fi
    [ "$verbose" = true ] && echo "% gpg --batch --pinentry-mode=loopback --passphrase "$passphrase" --quick-add-key "$primary_key_fingerprint" "$adjusted_key_type" "$subkey" $expire"
    gpg --batch --yes --no-tty --pinentry-mode=loopback --passphrase "$passphrase" --quick-add-key "$primary_key_fingerprint" "$adjusted_key_type" "$subkey" $expire
    if [ ! $? -eq 0 ]; then
        echo "${CROSS} Failed to generate $subkey subkey"
        exit 1
    fi
done

echo "${CHECK} Subkeys generated"

# Export private keys

gpg --output $gpg_temp/$primary_key_id-primary.gpg --batch --pinentry-mode=loopback --passphrase "$passphrase" --armor --export-secret-keys $primary_key_id
if [ ! $? -eq 0 ]; then
    echo "${CROSS} Failed to export primary private key"
    exit 1
fi

gpg --output $gpg_temp/$primary_key_id-subkeys.gpg --batch --pinentry-mode=loopback --passphrase "$passphrase" --armor --export-secret-subkeys $primary_key_id
if [ ! $? -eq 0 ]; then
    echo "${CROSS} Failed to export subkeys"
    exit 1
fi

gpg --output $gpg_temp/$primary_key_id-$(date +%F).asc --armor --export $primary_key_id
if [ ! $? -eq 0 ]; then
    echo "${CROSS} Failed to export public key"
    exit 1
fi

mv $gpg_temp/$primary_key_id-primary.gpg $gpg_temp/$primary_key_id-subkeys.gpg $gpg_temp/$primary_key_id-$(date +%F).asc $selected_drive

if [ $? -eq 0 ]; then
    echo "${CHECK} Exported private keys and backed them up to $selected_drive"
else
    echo "${CROSS} Failed to exported private keys to $selected_drive"
    exit 1
fi

# Remove primary key
gpg --batch --yes --no-tty --pinentry-mode=loopback --passphrase "$passphrase" --delete-secret-keys $primary_key_fingerprint\!

if [ $? -eq 0 ]; then
    echo "${CHECK} Primary key removed"
else
    echo "${CROSS} Failed to remove primary key"
    exit 1
fi

###########
# Yubikey #
###########

print_section_title "Yubikey"

ykman config usb --disable otp --force > /dev/null
if [ $? -eq 0 ]; then
    echo "${CHECK} Disabled touch OTP"
    sleep 2
else
    echo "${CROSS} Disable touch OTP failed"
    exit 1
fi


# Reset PGP application to defaults
ykman openpgp reset --force > /dev/null
if [ $? -eq 0 ]; then
    echo "${CHECK} Reset PGP Application to defaults"
    sleep 2
else
    echo "${CROSS} Reset PGP Application to defaults failed"
    exit 1
fi

echo "Generating admin pin for yubikey...\nWrite this down somewhere"

admin_pin=$(LC_ALL=C tr -dc '0-9' < /dev/urandom | fold -w8 | head -1)

print_in_box $admin_pin

gpg --command-fd=0 --pinentry-mode=loopback --change-pin > /dev/null <<EOF
3
12345678
$admin_pin
$admin_pin
q
EOF

if [ $? -eq 0 ]; then
    echo "${CHECK} Admin pin set to $admin_pin"
else
    echo "${CROSS} Failed to set admin pin"
    exit 1
fi
echo "Generating user pin for yubikey...\nWrite this down somewhere"

user_pin=$(LC_ALL=C tr -dc '0-9' < /dev/urandom | fold -w6 | head -1)

print_in_box $user_pin

gpg --command-fd=0 --pinentry-mode=loopback --change-pin > /dev/null <<EOF
1
123456
$user_pin
$user_pin
q
EOF

if [ $? -eq 0 ]; then
    echo "${CHECK} User pin set to $user_pin"
else
    echo "${CROSS} Failed to set user pin"
    exit 1
fi

# Set Identity
gpg --command-fd=0 --pinentry-mode=loopback --edit-card <<EOF
admin
login
$identity
$admin_pin
quit
EOF
if [ $? -eq 0 ]; then
    echo "${CHECK} Configured Identity"
else
    echo "${CROSS} Failed to configure identity"
    exit 1
fi

# Transfer keys

gpg --command-fd=0 --pinentry-mode=loopback --edit-key $primary_key_id <<EOF
key 1
keytocard
1
$passphrase
$admin_pin
save
EOF

if [ $? -eq 0 ]; then
    echo "${CHECK} Moved signature subkey to yubikey"
else
    echo "${CROSS} Failed to move signature subkey"
    exit 1
fi

gpg --command-fd=0 --pinentry-mode=loopback --edit-key $primary_key_id <<EOF
key 2
keytocard
2
$passphrase
$admin_pin
save
EOF

if [ $? -eq 0 ]; then
    echo "${CHECK} Moved encryption subkey to yubikey"
else
    echo "${CROSS} Failed to move encryption subkey"
    exit 1
fi

gpg --command-fd=0 --pinentry-mode=loopback --edit-key $primary_key_id <<EOF
key 3
keytocard
3
$passphrase
$admin_pin
save
EOF

if [ $? -eq 0 ]; then
    echo "${CHECK} Moved authentication subkey to yubikey"
else
    echo "${CROSS} Failed to move authentication subkey"
    exit 1
fi
