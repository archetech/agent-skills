#!/bin/bash
# List all DIDs in your wallet

set -e

# Load environment
if [ -f ~/.archon.env ]; then
    source ~/.archon.env
else
    echo "ERROR: ~/.archon.env not found"
    echo "Run ./scripts/create-id.sh first"
    exit 1
fi

# Check wallet exists
if [ ! -f ~/clawd/wallet.json ]; then
    echo "ERROR: No wallet found at ~/clawd/wallet.json"
    exit 1
fi

echo "=== Your Archon DIDs ==="
echo ""

cd ~/clawd
npx @didcid/keymaster list-dids

echo ""
echo "Switch active DID:"
echo "  ./scripts/switch-id.sh <did-name>"
