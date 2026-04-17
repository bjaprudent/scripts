#!/opt/homebrew/bin/bash

# Usage: ./hosts2config.sh <hosts_file> [key_file] > ~/.ssh/config

HOSTS_FILE="$1"
KEY_FILE="${2:-~/.ssh/bj-general-keys.pem}"

if [[ -z "$HOSTS_FILE" || ! -f "$HOSTS_FILE" ]]; then
    echo "Usage: $0 <hosts_file> [key_file]"
    exit 1
fi

declare -A FORWARD_HOST
declare -A FORWARD_PORTS

while IFS= read -r line; do
    if [[ "$line" =~ ^#[[:space:]]+([^[:space:]]+)[[:space:]]+([0-9]+):([0-9]+) ]]; then
        hint_host="${BASH_REMATCH[1]}"
        local_port="${BASH_REMATCH[2]}"
        remote_port="${BASH_REMATCH[3]}"
        FORWARD_HOST[$hint_host]=""          # placeholder; IP resolved below
        FORWARD_PORTS[$hint_host]="$local_port:$remote_port"
    fi
done < "$HOSTS_FILE"

# Resolve IPs for forwarded hosts
declare -A HOST_IP
while read -r IP HOST; do
    [[ -z "$IP" || -z "$HOST" || "$IP" =~ ^# ]] && continue
    HOST_IP[$HOST]="$IP"
done < "$HOSTS_FILE"

if [[ ${#FORWARD_PORTS[@]} -gt 0 ]]; then
    echo "Host bastion"
    # Sort by local port for deterministic output
    for hint_host in $(for h in "${!FORWARD_PORTS[@]}"; do
                           echo "${FORWARD_PORTS[$h]%%:*} $h"
                       done | sort -n | awk '{print $2}'); do
        ports="${FORWARD_PORTS[$hint_host]}"
        local_port="${ports%%:*}"
        remote_port="${ports##*:}"
        ip="${HOST_IP[$hint_host]}"
        echo "  LocalForward $local_port ${ip}:${remote_port}"
    done
    echo ""
fi

while read -r IP HOST; do
    [[ -z "$IP" || -z "$HOST" || "$IP" =~ ^# ]] && continue

    cat <<EOF
Host $HOST
  HostName $IP
  User ec2-user
  IdentityFile $KEY_FILE
  ProxyJump bastion

EOF
done < "$HOSTS_FILE"
