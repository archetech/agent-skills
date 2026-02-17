#!/bin/bash
# Reveal poll results (showing individual ballots)

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <poll-did>"
    echo ""
    echo "Publish poll results with individual ballots visible"
    echo ""
    echo "For private voting, use publish-poll.sh instead"
    echo ""
    echo "Example:"
    echo "  $0 did:cid:bagaaier..."
    exit 1
fi

POLL_DID=$1

# Ensure environment is loaded
if [ -z "$ARCHON_PASSPHRASE" ]; then
    if [ -f ~/.archon.env ]; then
        source ~/.archon.env
    else
        echo "Error: ARCHON_PASSPHRASE not set. Run create-id.sh first."
        exit 1
    fi
fi

# Set wallet path
export ARCHON_WALLET_PATH="${ARCHON_WALLET_PATH:-$HOME/clawd/wallet.json}"

# Reveal results
echo "Revealing poll results (ballots visible)..."
npx @didcid/keymaster reveal-poll "$POLL_DID"
