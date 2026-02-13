#!/bin/bash
# Delete a dmail from inbox
# Usage: delete.sh <dmail-did>

set -e

# Load environment
if [ -f ~/.archon.env ]; then
    source ~/.archon.env
fi
export ARCHON_WALLET_PATH="${ARCHON_WALLET_PATH:-$HOME/clawd/wallet.json}"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <dmail-did>"
    exit 1
fi

DMAIL_DID="$1"

npx @didcid/keymaster remove-dmail "$DMAIL_DID"

echo "Deleted: $DMAIL_DID"
