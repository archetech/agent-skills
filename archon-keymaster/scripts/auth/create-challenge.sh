#!/bin/bash
# Create an authorization challenge
# Usage: create-challenge.sh [file] [--alias <alias>]
# Example: create-challenge.sh
# Example: create-challenge.sh challenge.json
# Example: create-challenge.sh --alias myDID

set -e

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

# Create challenge
npx @didcid/keymaster create-challenge "$@"
