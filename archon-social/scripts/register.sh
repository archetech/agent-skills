#!/bin/bash
set -e

# Archon.Social Registration Script
# Complete registration flow: auth, name claim, credential request

# Check arguments
if [ -z "$1" ]; then
    echo "Usage: $0 <name>"
    echo "Example: $0 morningstar"
    exit 1
fi

NAME="$1"
ARCHON_SOCIAL="https://archon.social"

# Validate name format
if ! echo "$NAME" | grep -Eq '^[a-z0-9_-]{3,32}$'; then
    echo "Error: Invalid name format"
    echo "Name must be 3-32 characters: lowercase letters, numbers, hyphens, underscores only"
    exit 1
fi

# Check environment
if [ -z "$ARCHON_WALLET_PATH" ] || [ -z "$ARCHON_PASSPHRASE" ]; then
    echo "Error: Archon environment not configured"
    echo "Required: ~/.archon.env with ARCHON_WALLET_PATH and ARCHON_PASSPHRASE"
    echo ""
    echo "Run: source ~/.archon.env"
    exit 1
fi

# Check keymaster availability
if ! command -v npx &> /dev/null; then
    echo "Error: npx not found (Node.js required)"
    exit 1
fi

# Create temporary directory for cookies
TEMP_DIR=$(mktemp -d)
COOKIES="$TEMP_DIR/cookies.txt"
trap "rm -rf $TEMP_DIR" EXIT

echo "=== Archon.Social Registration ==="
echo "Name: @$NAME"
echo ""

# 1. Check name availability
echo "[1/6] Checking name availability..."
AVAILABLE=$(curl -s "$ARCHON_SOCIAL/api/name/$NAME/available" | jq -r '.available')

if [ "$AVAILABLE" != "true" ]; then
    echo "Error: Name '@$NAME' is not available (case-insensitive check)"
    echo ""
    echo "Try a different variation:"
    echo "  - Add numbers: ${NAME}42"
    echo "  - Add hyphen: my-$NAME"
    echo "  - Add underscore: ${NAME}_ai"
    exit 1
fi
echo "✓ Name '@$NAME' is available"
echo ""

# 2. Get challenge
echo "[2/6] Requesting challenge..."
CHALLENGE=$(curl -s -c "$COOKIES" "$ARCHON_SOCIAL/api/challenge" | jq -r '.challenge')
echo "Challenge DID: $CHALLENGE"
echo ""

# 3. Sign challenge
echo "[3/6] Signing challenge with your DID..."

# Use keymaster to create a response to the challenge
RESPONSE=$(npx @didcid/keymaster create-response "$CHALLENGE" 2>&1 | tail -n1)

if [ -z "$RESPONSE" ] || ! echo "$RESPONSE" | grep -q "^did:cid:"; then
    echo "Error: Failed to sign challenge"
    echo "Output: $RESPONSE"
    exit 1
fi
echo "Response DID: $RESPONSE"
echo ""

# 4. Login
echo "[4/6] Authenticating..."
AUTH_RESULT=$(curl -s -b "$COOKIES" -c "$COOKIES" \
    -X POST "$ARCHON_SOCIAL/api/login" \
    -H "Content-Type: application/json" \
    -d "{\"response\":\"$RESPONSE\"}")

AUTHENTICATED=$(echo "$AUTH_RESULT" | jq -r '.authenticated')
if [ "$AUTHENTICATED" != "true" ]; then
    echo "Error: Authentication failed"
    echo "Response: $AUTH_RESULT"
    exit 1
fi
echo "✓ Authenticated"
echo ""

# 5. Get DID and set name
echo "[5/6] Setting name to @$NAME..."
AUTH_INFO=$(curl -s -b "$COOKIES" "$ARCHON_SOCIAL/api/check-auth")
DID=$(echo "$AUTH_INFO" | jq -r '.userDID')
echo "Your DID: $DID"

NAME_RESULT=$(curl -s -b "$COOKIES" \
    -X PUT "$ARCHON_SOCIAL/api/profile/$DID/name" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$NAME\"}")

NAME_OK=$(echo "$NAME_RESULT" | jq -r '.ok')
if [ "$NAME_OK" != "true" ]; then
    echo "Error: Failed to set name"
    echo "Response: $NAME_RESULT"
    exit 1
fi
echo "✓ Name set to @$NAME"
echo ""

# 6. Request credential
echo "[6/6] Requesting verifiable credential..."
CRED_RESULT=$(curl -s -b "$COOKIES" \
    -X POST "$ARCHON_SOCIAL/api/credential/request")

CRED_DID=$(echo "$CRED_RESULT" | jq -r '.credentialDID // empty')
if [ -z "$CRED_DID" ]; then
    echo "Warning: Credential request returned unexpected response"
    echo "Response: $CRED_RESULT"
    echo ""
    echo "You may need to request the credential manually:"
    echo "  curl -s -b cookies.txt -X POST https://archon.social/api/credential/request"
else
    echo "✓ Credential issued: $CRED_DID"
fi
echo ""

# Success
echo "==================================="
echo "✓ Registration complete!"
echo ""
echo "Your Archon.Social identity:"
echo "  @$NAME"
echo "  DID: $DID"
echo "  Profile: https://archon.social/member/$NAME"
echo ""
echo "Public endpoints:"
echo "  Resolve:  https://archon.social/api/name/$NAME"
echo "  Document: https://archon.social/member/$NAME"
echo ""
echo "Decentralized:"
echo "  IPNS: https://ipfs.io/ipns/archon.social"
echo "==================================="
