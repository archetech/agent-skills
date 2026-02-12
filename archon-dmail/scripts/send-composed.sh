#!/bin/bash
# Send a previously composed dmail
# Usage: send-composed.sh <dmail-did>

set -e

# Load environment
if [ -f ~/.archon.env ]; then
    source ~/.archon.env
fi
export ARCHON_WALLET_PATH="${ARCHON_WALLET_PATH:-$HOME/clawd/wallet.json}"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <dmail-did>"
    echo ""
    echo "Sends a dmail that was created with compose.sh"
    exit 1
fi

DMAIL_DID="$1"

# Show what we're sending
echo "Sending dmail: $DMAIL_DID"

# List attachments if any
ATTACHMENTS=$(npx @didcid/keymaster list-dmail-attachments "$DMAIL_DID" 2>/dev/null)
if [ -n "$ATTACHMENTS" ] && [ "$ATTACHMENTS" != "{}" ]; then
    echo "Attachments:"
    echo "$ATTACHMENTS" | jq -r 'keys[] | "  - \(.)"'
fi

# Send the dmail
NOTICE_DID=$(npx @didcid/keymaster send-dmail "$DMAIL_DID")
echo ""
echo "Sent! Notice: $NOTICE_DID"

# Tag as sent
npx @didcid/keymaster file-dmail "$DMAIL_DID" "sent" >/dev/null 2>&1

echo "$DMAIL_DID"
