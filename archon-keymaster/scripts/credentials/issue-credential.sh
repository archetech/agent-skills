#!/bin/bash
# Issue a verifiable credential from a bound credential file

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <bound-credential-file.json> [options]"
    echo ""
    echo "Issue a verifiable credential from a filled-in bound credential"
    echo ""
    echo "Options:"
    echo "  --registry TEXT  Registry URL (default: hyperswarm)"
    echo ""
    echo "The bound credential file should contain filled-in credentialSubject data"
    echo ""
    echo "Example:"
    echo "  $0 did-cid-bagaaierb...BOUND.json"
    exit 1
fi

CREDENTIAL_FILE=$1
shift

if [ ! -f "$CREDENTIAL_FILE" ]; then
    echo "Error: Credential file not found: $CREDENTIAL_FILE"
    exit 1
fi

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

# Issue credential
echo "Issuing credential from $CREDENTIAL_FILE..."
npx @didcid/keymaster issue-credential "$CREDENTIAL_FILE" "$@"
