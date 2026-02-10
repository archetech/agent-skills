#!/bin/bash
# List all name → DID mappings

set -e

# Load environment
if [ -f ~/.archon.env ]; then
    source ~/.archon.env
else
    echo "ERROR: ~/.archon.env not found"
    exit 1
fi

echo "=== Your Named DIDs ==="
echo ""

cd ~/clawd
npx @didcid/keymaster list-names

echo ""
echo "Add name: ./add-name.sh <name> <did>"
echo "Remove name: ./remove-name.sh <name>"
echo "Resolve: ./resolve-did.sh <name>"
