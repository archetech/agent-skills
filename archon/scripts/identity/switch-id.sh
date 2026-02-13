#!/bin/bash
# Switch active DID (for multi-DID setups)
# Usage: ./switch-id.sh <did-name>

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <did-name>"
    echo ""
    echo "Available DIDs:"
    "$(dirname "$0")/list-ids.sh"
    exit 1
fi

DID_NAME="$1"

# Load environment
if [ -f ~/.archon.env ]; then
    source ~/.archon.env
else
    echo "ERROR: ~/.archon.env not found"
    exit 1
fi

# Check wallet exists
if [ ! -f ~/clawd/wallet.json ]; then
    echo "ERROR: No wallet found"
    exit 1
fi

# Verify DID exists
if ! (cd ~/clawd && npx @didcid/keymaster list-dids | grep -q "$DID_NAME"); then
    echo "ERROR: DID '$DID_NAME' not found in wallet"
    echo ""
    echo "Available DIDs:"
    cd ~/clawd && npx @didcid/keymaster list-dids
    exit 1
fi

echo "=== Switching Active DID ==="
echo ""
echo "Target: $DID_NAME"
echo ""
echo "Note: This updates environment variables for the current session."
echo "      To persist across sessions, update ~/.archon.env manually."
echo ""

# Set active DID for current session
export KEYMASTER_ACTIVE_DID="$DID_NAME"

echo "✓ Active DID: $DID_NAME"
echo ""
echo "Verify:"
echo "  npx @didcid/keymaster show-did --name $DID_NAME"
