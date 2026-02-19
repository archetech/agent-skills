#!/bin/bash
# Vote in a poll

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <poll-did> <vote> [spoil]"
    echo ""
    echo "Cast a vote in a poll"
    echo ""
    echo "Arguments:"
    echo "  poll-did  DID of the poll"
    echo "  vote      Your vote (must match one of the poll options)"
    echo "  spoil     Optional: any value to spoil the ballot"
    echo ""
    echo "Example:"
    echo "  $0 did:cid:bagaaier... yes"
    echo "  $0 did:cid:bagaaier... no spoil"
    exit 1
fi

POLL_DID=$1
VOTE=$2
SPOIL=${3:-}

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
if [ -z "$ARCHON_WALLET_PATH" ]; then
    echo "Error: ARCHON_WALLET_PATH not set in ~/.archon.env"
    exit 1
fi

# Vote
echo "Casting vote '$VOTE' in poll..."
if [ -n "$SPOIL" ]; then
    npx @didcid/keymaster vote-poll "$POLL_DID" "$VOTE" "$SPOIL"
else
    npx @didcid/keymaster vote-poll "$POLL_DID" "$VOTE"
fi
