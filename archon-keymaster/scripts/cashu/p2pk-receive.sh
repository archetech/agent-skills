#!/bin/bash
# Archon Cashu Wallet — Receive P2PK-locked tokens
# Signs with DID private key to prove ownership
# Usage: p2pk-receive.sh <token>
#
# Note: This requires the cashu CLI to have access to the signing key.
# For nutshell 0.17+, P2PK receive uses --privkey flag.
# The private key is derived from the DID's secp256k1 key.
set -e

TOKEN="${1:?Usage: p2pk-receive.sh <token>}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh" > /dev/null 2>&1

echo "🔐 Attempting P2PK token redemption..."

# Step 1: Extract DID private key (hex)
# The keymaster stores keys encrypted; we need to derive the signing key
PRIVKEY=$(npx --yes @didcid/keymaster export-key 2>/dev/null | grep -oP '[0-9a-f]{64}' | head -1)

if [ -z "$PRIVKEY" ]; then
    echo "⚠️  Could not extract DID private key automatically."
    echo "Trying standard receive (works if token is not P2PK-locked)..."
    $CASHU_BIN receive "$TOKEN" 2>&1
    exit $?
fi

# Step 2: Receive with private key
echo "🔑 Signing with DID key..."
RESULT=$($CASHU_BIN receive "$TOKEN" --privkey "$PRIVKEY" 2>&1)

if echo "$RESULT" | grep -q "Received"; then
    SATS=$(echo "$RESULT" | grep -oP '\d+(?= sat)' | head -1)
    echo "✅ Received $SATS sats (P2PK-locked token redeemed)"
else
    echo "Result: $RESULT"
fi

echo ""
echo "💰 Balance:"
$CASHU_BIN balance 2>&1
