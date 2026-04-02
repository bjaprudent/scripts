#!/bin/bash

# Usage: ./generate_ssh_config.sh hosts.txt > ~/.ssh/config

HOSTS_FILE="$1"

if [[ -z "$HOSTS_FILE" || ! -f "$HOSTS_FILE" ]]; then
    echo "Usage: $0 <hosts_file>"
    exit 1
fi

while read -r IP HOST; do
    # Skip empty lines or lines starting with #
    [[ -z "$IP" || -z "$HOST" || "$IP" =~ ^# ]] && continue

    cat <<EOF
Host $HOST
  HostName $IP
  User ec2-user
  ForwardAgent Yes
  IdentityFile ~/.ssh/bj-general-keys.pem

EOF
done < "$HOSTS_FILE"
