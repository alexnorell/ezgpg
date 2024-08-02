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

    echo "Requirements check:"
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
        echo "Some programs are not available. Prompting for installation..."
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
            echo "Some programs are still not available. Please install the necessary programs."
            echo -e "$final_results"
            exit 1
        else
            echo "All required programs are available."
        fi
    else
        echo "All required programs are available. No installation needed."
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
    echo "Checking git configuration"
    echo "👤 Name: $git_name"
    echo "✉️ Email: $git_email"

    user_input=$(prompt_user "Are these values correct? (y/N): ")

    if [[ "$user_input" =~ ^[Yy]$ ]]; then
        [ "$verbose" = true ] && echo "No changes made."
    else
        git_name=$(prompt_user "👤 New name: ")
        git_email=$(prompt_user "✉️ New email: ")

        echo "👤 Updated name: $git_name"
        echo "✉️ Updated email: $git_email"

        user_input=$(prompt_user "Do you want to configure git with these values? (y/N): ")

        if [[ "$user_input" =~ ^[Yy]$ ]]; then
            echo "% git config --global user.email \"$git_email\""
            git config --global user.email "$git_email"
            echo "% git config --glboal user.name \"$git_name\""
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

# Print logo
logo

#########################
# Initial Configuration #
#########################
print_section_title "Initial Configuration"

# Check programs
programs_to_check=(
    "gpg,gnupg"
    "ykman,ykman"
    "git,git"
)
check_programs "${programs_to_check[@]}"

# Check git config and set up if needed
check_git_config
user_name=$(get_git_name)
user_email=$(get_git_email)

# GPG key inputs
# GPG identity
identity="$user_name <$user_email>"
[ "$verbose" = true ] && echo "GPG Identity: $identity"

# Key types/algorithms
prompt_key_choice
key_type="${key_types[$?]%%:*}"  # Extract the key without the comment

# Put in best practices for GPG
harden_gpg_conf

# Set up temp-dir
gpg_temp=$(mktemp -d -t gnupg-$RANDOM)
cd $gpg_temp
[ "$verbose" = true ] && echo "GPG Temp dir: $gpg_temp"

##################
# Key Generation #
##################
print_section_title "Key generation"

echo "Best practice suggests that you disconnect from the internet. Check connection?"
internet_off_continue=$(prompt_user "Continue? (y/skip): ")
if [[ "$internet_off_continue" =~ ^[Ss][Kk][Ii][Pp]$ ]]; then
    echo "${YELLOW}!${RESET} Bypassing internet check"
elif [[ "$internet_off_continue" =~ ^[Yy]$ ]]; then
    loop_until_disconnected
fi

echo "Generating passphrase...\nWrite this down somewhere secure:"

# Create Primary (Certify) key passphrase
passphrase=$(generate_passphrase)

print_in_box $passphrase

echo "Generating primary certify key..."
[ "$verbose" = true ] && echo "% gpg --batch --passphrase "$passphrase" --quick-generate-key "$identity" "$key_type" cert never"
gpg --batch --passphrase "$passphrase" --quick-generate-key "$identity" "$key_type" cert never

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
    gpg --batch --pinentry-mode=loopback --passphrase "$passphrase" --quick-add-key "$primary_key_fingerprint" "$adjusted_key_type" "$subkey" $expire
done

echo "${CHECK} Subkeys generated"

cd $HOME
