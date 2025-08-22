#!/usr/bin/env bash

set -euo pipefail

c0=$(tput sgr0)
BOLD=$(tput bold)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

msg() {
    local type="$1"
    shift
    local color

    case "$type" in
        INFO)    color=6 ;;
        WARN)    color=3 ;;
        ERROR)   color=1 ;;
        SUCCESS) color=2 ;;
        DEBUG)   color=4 ;;
        HIGHLIGHT) color=5 ;;
        *)       color=7 ;;
    esac

    tput setaf "$color"
    printf -- "[%s] : %s%s\n" "$type" "$*" "$c0"
}

# === Ask user for remote_user and SSH key ===
msg INFO "Configuring Ansible remote user and SSH key"

read -rp "Enter remote user: " remote_user
read -rp "Enter path to private key file (e.g., ~/.ssh/id_rsa): " priv_key

# Backup before modifying

cp -- "$SCRIPT_DIR/../ansible.cfg" "$SCRIPT_DIR/../ansible.cfg.backup"

# Replace values

sed -i -- "s|^remote_user =.*|remote_user = ${remote_user}|g" "$SCRIPT_DIR/../ansible.cfg"
sed -i -- "s|^private_key_file =.*|private_key_file = ${priv_key}|g" "$SCRIPT_DIR/../ansible.cfg"

msg SUCCESS "Ansible configuration updated successfully:"
msg INFO " - remote_user = ${remote_user}"
msg INFO " - private_key_file = ${priv_key}"

# === Ask user for Vault password to encrypt DB root password ===

msg INFO "Setting up vault password for db_root_password"
read -srp "Enter the vault password to encrypt DB root password: " vault_pass

printf -- "\n"

echo "$vault_pass" > "$SCRIPT_DIR/../passwords/vault-pass.txt"

# Ask DB root password
read -srp "Enter the MariaDB root password: " db_root_pass

encrypted_pass=$(ansible-vault encrypt_string --encrypt-vault-id default --vault-password-file=<(echo "$vault_pass") "$db_root_pass" --name 'db_root_password')

# Backup before modifying

cp -- "$SCRIPT_DIR/../roles/domserver/defaults/main.yml" "$SCRIPT_DIR/../roles/domserver/defaults/main.yml.backup"
cp -- "$SCRIPT_DIR/../roles/judgehost/defaults/main.yml" "$SCRIPT_DIR/../roles/judgehost/defaults/main.yml.backup"

# Remove old db_root_password

sed -i -- '/^db_root_password:/,/^$/d' "$SCRIPT_DIR/../roles/domserver/defaults/main.yml"

echo -e "$encrypted_pass" >> "$SCRIPT_DIR/../roles/domserver/defaults/main.yml"

msg SUCCESS "db_root_password updated and encrypted"

# === Ask what to deploy ===

read -rp "Do you want to set up a domserver? (y/n): " setup_domserver
read -rp "Do you want to set up judgehosts? (y/n): " setup_judgehosts

# Domserver
[[ "$setup_domserver" == "y" ]] && read -rp "Enter the IP of the domserver: " domserver_ip
[[ "$setup_domserver" == "y" ]] && { echo "[domserver]" >> "$SCRIPT_DIR/../inventory/hosts.ini"; echo "$domserver_ip" >> "$SCRIPT_DIR/../inventory/hosts.ini"; msg INFO "Domserver IP $domserver_ip added to inventory" ; }

# Domserver options

# === Domserver options ===
[[ "$setup_domserver" == "y" ]] && read -rp "Do you want to install demo contest data? (y/N, default N): " demo_input
[[ "$setup_domserver" == "y" ]] && install_demo_contest="false"
[[ "$setup_domserver" == "y" ]] && [[ "$demo_input" == "y" ]] && install_demo_contest="true"

[[ "$setup_domserver" == "y" ]] && read -rp "Which webserver to use? (nginx/apache, default nginx): " web_input
[[ "$setup_domserver" == "y" ]] && webserver="${web_input:-nginx}"

[[ "$setup_domserver" == "y" ]] && read -rp "Enter server base URL (default http://localhost): " baseurl_input
[[ "$setup_domserver" == "y" ]] && server_baseurl="${baseurl_input:-http://localhost}"

[[ "$setup_domserver" == "y" ]] && {
    # Remove old options
    sed -i -- '/^install_demo_contest:/d' "$SCRIPT_DIR/../roles/domserver/defaults/main.yml"
    sed -i -- '/^webserver:/d' "$SCRIPT_DIR/../roles/domserver/defaults/main.yml"
    sed -i -- '/^server_baseurl:/d' "$SCRIPT_DIR/../roles/domserver/defaults/main.yml"
    # Append new options
    echo -e "install_demo_contest: $install_demo_contest\nwebserver: $webserver\nserver_baseurl: \"$server_baseurl\"" >> "$SCRIPT_DIR/../roles/domserver/defaults/main.yml"
}

[[ "$setup_domserver" == "y" ]] && msg SUCCESS "Domserver options updated"
[[ "$setup_domserver" == "y" ]] && msg INFO "install_demo_contest = $install_demo_contest" && msg INFO "webserver = $webserver" && msg INFO "server_baseurl = $server_baseurl"

# Judgehosts
[[ "$setup_judgehosts" == "y" ]] && read -rp "How many judgehosts? " num_judgehosts
[[ "$setup_judgehosts" == "y" ]] && { echo "[judgehosts]" >> "$SCRIPT_DIR/../inventory/hosts.ini"; for ((i=1; i<=num_judgehosts; i++)); do read -rp "Enter IP of judgehost #$i: " ip; echo "$ip" >> "$SCRIPT_DIR/../inventory/hosts.ini"; done; msg INFO "Judgehosts added to inventory" ; }

# === Judgehost options ===

[[ "$setup_judgehosts" == "y" ]] && read -rp "Enter CPU cores per judgehost (default 2): " cpu_input
[[ "$setup_judgehosts" == "y" ]] && judgehost_cpu_core="${cpu_input:-2}"

[[ "$setup_judgehosts" == "y" ]] && {
    # Remove old variable if exists
    sed -i -- '/^judgehost_cpu_core:/d' "$SCRIPT_DIR/../roles/judgehost/defaults/main.yml"
    # Append new variable
    echo -e "judgehost_cpu_core: $judgehost_cpu_core" >> "$SCRIPT_DIR/../roles/judgehost/defaults/main.yml"
}

[[ "$setup_judgehosts" == "y" ]] && msg SUCCESS "Judgehost option updated"
[[ "$setup_judgehosts" == "y" ]] && msg INFO "Judgehost CPU cores set to $judgehost_cpu_core"

# === Run Ansible playbooks ===
[[ "$setup_domserver" == "y" ]] && { msg INFO "Running domserver playbook..." ; ansible-playbook "$SCRIPT_DIR/../playbooks/domserver.yml" --ask-become-pass ; }

[[ "$setup_judgehosts" == "y" ]] && { msg INFO "Running judgehost playbook..." ; ansible-playbook "$SCRIPT_DIR/../playbooks/judgehost.yml" --ask-become-pass ; }

msg SUCCESS "Script execution finished"
