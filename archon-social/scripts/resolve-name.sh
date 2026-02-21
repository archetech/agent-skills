#!/bin/bash
set -e

# Resolve an archon.social name to a DID (public endpoint, no auth required)

if [ -z "$1" ]; then
    echo "Usage: $0 <name>"
    echo "Example: $0 morningstar"
    exit 1
fi

NAME="$1"
ARCHON_SOCIAL="https://archon.social"

# Resolve name
RESULT=$(curl -s "$ARCHON_SOCIAL/api/name/$NAME")
echo "$RESULT" | jq .

# Extract DID for easier use
DID=$(echo "$RESULT" | jq -r '.did // empty')
if [ -n "$DID" ]; then
    echo ""
    echo "DID: $DID"
fi
