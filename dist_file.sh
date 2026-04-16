#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 <file_to_copy> <remote_path> [ssh_config_file] [host_pattern]"
  echo
  echo "Example:"
  echo "  $0 myfile.txt /tmp/"
  echo "  $0 myfile.txt /tmp/ ~/.ssh/myconfig idx"
  exit 1
}

[[ $# -lt 2 ]] && usage

FILE="$1"
REMOTE_PATH="$2"
SSH_CONFIG="${3:-$HOME/.ssh/config}"
PATTERN="${4:-.*}"

if [[ ! -f "$FILE" ]]; then
  echo "Error: File '$FILE' not found"
  exit 1
fi

if [[ ! -f "$SSH_CONFIG" ]]; then
  echo "Error: SSH config '$SSH_CONFIG' not found"
  exit 1
fi

echo "Using SSH config: $SSH_CONFIG"
echo "File to copy: $FILE"
echo "Remote path: $REMOTE_PATH"
echo "Host filter: $PATTERN"
echo

# Extract hosts
HOSTS=$(awk '
  $1 == "Host" {
    for (i = 2; i <= NF; i++) {
      if ($i != "*" && $i !~ /\*/) print $i
    }
  }
' "$SSH_CONFIG" | grep -E "$PATTERN" | sort -u)

if [[ -z "$HOSTS" ]]; then
  echo "No matching hosts found."
  exit 1
fi

AUTO_APPROVE=false

for HOST in $HOSTS; do
  if [[ "$AUTO_APPROVE" == false ]]; then
    read -rp "Copy to $HOST? [y/n/a/q]: " choice
    case "$choice" in
      y|Y) ;;
      n|N)
        echo "Skipping $HOST"
        echo
        continue
        ;;
      a|A)
        AUTO_APPROVE=true
        ;;
      q|Q)
        echo "Quitting."
        exit 0
        ;;
      *)
        echo "Invalid choice. Skipping $HOST"
        echo
        continue
        ;;
    esac
  fi

  echo "---- Copying to $HOST ----"

  if scp -F "$SSH_CONFIG" "$FILE" "$HOST:$REMOTE_PATH"; then
    echo "Success: $HOST"
  else
    echo "Failed: $HOST"
  fi

  echo
done

echo "Done."
