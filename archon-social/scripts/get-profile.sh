#!/bin/bash
set -e

# Get your archon.social profile (requires authentication)

ARCHON_SOCIAL="https://archon.social"

# Check environment
if [ -z "$ARCHON_WALLET_PATH" ] || [ -z "$ARCHON_PASSPHRASE" ]; then
    echo "Error: Archon environment not configured"
    echo "Required: ~/.archon.env with ARCHON_WALLET_PATH and ARCHON_PASSPHRASE"
    echo ""
    echo "Run: source ~/.archon.env"
    exit 1
fi

# Create temporary directory for cookies
TEMP_DIR=$(mktemp -d)
COOKIES="$TEMP_DIR/cookies.txt"
trap "rm -rf $TEMP_DIR" EXIT

echo "=== Archon.Social Profile ==="
echo ""

# 1. Get challenge
echo "Authenticating..."
CHALLENGE=$(curl -s -c "$COOKIES" "$ARCHON_SOCIAL/api/challenge" | jq -r '.challenge')

# 2. Sign challenge
RESPONSE=$(npx @didcid/keymaster sign-challenge "$CHALLENGE" 2>&1 | tail -n1)

if [ -z "$RESPONSE" ] || ! echo "$RESPONSE" | grep -q "^did:cid:"; then
    echo "Error: Failed to sign challenge"
    exit 1
fi

# 3. Login
AUTH_RESULT=$(curl -s -b "$COOKIES" -c "$COOKIES" \
    -X POST "$ARCHON_SOCIAL/api/login" \
    -H "Content-Type: application/json" \
    -d "{\"response\":\"$RESPONSE\"}")

AUTHENTICATED=$(echo "$AUTH_RESULT" | jq -r '.authenticated')
if [ "$AUTHENTICATED" != "true" ]; then
    echo "Error: Authentication failed"
    exit 1
fi

# 4. Get DID
AUTH_INFO=$(curl -s -b "$COOKIES" "$ARCHON_SOCIAL/api/check-auth")
DID=$(echo "$AUTH_INFO" | jq -r '.userDID')

# 5. Get profile
PROFILE=$(curl -s -b "$COOKIES" "$ARCHON_SOCIAL/api/profile/$DID")
echo "$PROFILE" | jq .

# Extract name for convenience
NAME=$(echo "$PROFILE" | jq -r '.name // empty')
if [ -n "$NAME" ]; then
    echo ""
    echo "Your handle: @$NAME"
    echo "Profile URL: https://archon.social/member/$NAME"
fi
