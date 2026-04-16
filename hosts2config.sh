#!/bin/bash

# Usage: ./hosts2config.sh [hosts_file] [key_file] > ~/.ssh/config

HOSTS_FILE="$1"
KEY_FILE="${2:-~/.ssh/bj-general-keys.pem}"

if [[ -z "$HOSTS_FILE" || ! -f "$HOSTS_FILE" ]]; then
    echo "Usage: $0 <hosts_file> [key_file]"
    exit 1
fi

while read -r IP HOST; do
    # Skip empty lines or comments
    [[ -z "$IP" || -z "$HOST" || "$IP" =~ ^# ]] && continue

    cat <<EOF
Host $HOST
  HostName $IP
  User ec2-user
  ForwardAgent Yes
  IdentityFile $KEY_FILE

EOF
done < "$HOSTS_FILE"
