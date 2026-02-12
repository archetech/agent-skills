#!/bin/bash
# Compose a dmail from JSON (create without sending)
# Usage: compose.sh <json-file>
# Then use attach.sh to add files, and send-composed.sh to send

set -e

# Load environment
if [ -f ~/.archon.env ]; then
    source ~/.archon.env
fi
export ARCHON_WALLET_PATH="${ARCHON_WALLET_PATH:-$HOME/clawd/wallet.json}"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <json-file>"
    echo ""
    echo "JSON format:"
    echo '{'
    echo '    "to": ["did:cid:recipient1", "did:cid:recipient2"],'
    echo '    "cc": ["did:cid:cc-recipient"],'
    echo '    "subject": "Subject line",'
    echo '    "body": "Message body",'
    echo '    "reference": ""'
    echo '}'
    echo ""
    echo "Creates a dmail without sending. Use attach.sh to add files,"
    echo "then send-composed.sh to send."
    exit 1
fi

JSON_FILE="$1"

if [ ! -f "$JSON_FILE" ]; then
    echo "Error: File not found: $JSON_FILE"
    exit 1
fi

# Validate JSON has required fields
if ! jq -e '.to | length > 0' "$JSON_FILE" >/dev/null 2>&1; then
    echo "Error: JSON must have at least one recipient in 'to' array"
    exit 1
fi

if ! jq -e '.subject' "$JSON_FILE" >/dev/null 2>&1; then
    echo "Error: JSON must have 'subject' field"
    exit 1
fi

if ! jq -e '.body' "$JSON_FILE" >/dev/null 2>&1; then
    echo "Error: JSON must have 'body' field"
    exit 1
fi

# Ensure optional fields exist (add defaults if missing)
TMPFILE=$(mktemp /tmp/dmail-XXXXXX.json)
trap "rm -f $TMPFILE" EXIT

jq '{
    to: .to,
    cc: (.cc // []),
    subject: .subject,
    body: .body,
    reference: (.reference // "")
}' "$JSON_FILE" > "$TMPFILE"

# Create the dmail (but don't send)
DMAIL_DID=$(npx @didcid/keymaster create-dmail "$TMPFILE")

echo "Created draft: $DMAIL_DID"
echo ""
echo "Next steps:"
echo "  Add attachments: ./scripts/attach.sh $DMAIL_DID <file>"
echo "  Send when ready: ./scripts/send-composed.sh $DMAIL_DID"
