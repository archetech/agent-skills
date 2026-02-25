#!/bin/bash
set -e

# Check if a name is available on archon.social

if [ -z "$1" ]; then
    echo "Usage: $0 <name>"
    exit 1
fi

NAME="$1"
ARCHON_SOCIAL="https://archon.social"

# Validate name format
if ! echo "$NAME" | grep -Eq '^[a-z0-9_-]{3,32}$'; then
    echo "Error: Invalid name format"
    echo "Name must be 3-32 characters: lowercase letters, numbers, hyphens, underscores only"
    exit 1
fi

# Check availability
RESULT=$(curl -s "$ARCHON_SOCIAL/api/name/$NAME/available")
AVAILABLE=$(echo "$RESULT" | jq -r '.available')

if [ "$AVAILABLE" = "true" ]; then
    echo "✓ @$NAME is available"
    exit 0
else
    echo "✗ @$NAME is not available (already registered)"
    exit 1
fi
