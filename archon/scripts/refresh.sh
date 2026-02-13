#!/bin/bash
# Check for new dmails
# Usage: refresh.sh

set -e

# Load environment
if [ -f ~/.archon.env ]; then
    source ~/.archon.env
fi
export ARCHON_WALLET_PATH="${ARCHON_WALLET_PATH:-$HOME/clawd/wallet.json}"

echo "Checking for new messages..."
npx @didcid/keymaster refresh-dmail

# Count unread
UNREAD=$(npx @didcid/keymaster list-dmail 2>/dev/null | jq '[to_entries[] | select(.value.tags | contains(["unread"]))] | length')

if [ "$UNREAD" -gt 0 ]; then
    echo "You have $UNREAD unread message(s)."
else
    echo "No new messages."
fi
