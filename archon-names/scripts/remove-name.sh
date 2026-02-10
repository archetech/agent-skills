#!/bin/bash
# Remove a name mapping
# Usage: ./remove-name.sh <name>

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <name>"
    echo ""
    echo "Examples:"
    echo "  $0 alice"
    echo "  $0 old-schema"
    exit 1
fi

NAME="$1"

# Load environment
if [ -f ~/.archon.env ]; then
    source ~/.archon.env
else
    echo "ERROR: ~/.archon.env not found"
    exit 1
fi

# Remove name
cd ~/clawd
npx @didcid/keymaster remove-name "$NAME"

echo ""
echo "✓ Name '$NAME' removed"
