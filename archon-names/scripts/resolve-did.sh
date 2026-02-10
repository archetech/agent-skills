#!/bin/bash
# Resolve a name to its DID (or pass through a DID unchanged)
# Usage: ./resolve-did.sh <name-or-did>

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <name-or-did>"
    echo ""
    echo "Examples:"
    echo "  $0 alice"
    echo "  $0 did:cid:bagaaiera..."
    exit 1
fi

NAME_OR_DID="$1"

# Load environment
if [ -f ~/.archon.env ]; then
    source ~/.archon.env
else
    echo "ERROR: ~/.archon.env not found"
    exit 1
fi

# Resolve (works with both names and DIDs)
cd ~/clawd
npx @didcid/keymaster resolve-did "$NAME_OR_DID"
