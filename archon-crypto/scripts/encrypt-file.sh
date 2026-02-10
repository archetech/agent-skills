#!/bin/bash
# Encrypt a file for a specific DID
# Usage: ./encrypt-file.sh <input-file> <recipient-name-or-did> [output-file]

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <input-file> <recipient-name-or-did> [output-file]"
    echo ""
    echo "Examples:"
    echo "  $0 secret.pdf alice"
    echo "  $0 document.txt bob encrypted.json"
    echo "  $0 data.csv did:cid:bagaaiera... secure.json"
    exit 1
fi

INPUT_FILE="$1"
RECIPIENT="$2"
OUTPUT_FILE="${3:-${INPUT_FILE}.encrypted.json}"

# Check input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "ERROR: Input file not found: $INPUT_FILE"
    exit 1
fi

# Load environment
if [ -f ~/.archon.env ]; then
    source ~/.archon.env
else
    echo "ERROR: ~/.archon.env not found"
    exit 1
fi

# Resolve recipient name to DID if needed
cd ~/clawd
RECIPIENT_DID=$(npx @didcid/keymaster resolve-did "$RECIPIENT" 2>/dev/null || echo "$RECIPIENT")

echo "Encrypting: $INPUT_FILE"
echo "For: $RECIPIENT_DID"
echo "Output: $OUTPUT_FILE"
echo ""

# Encrypt file
npx @didcid/keymaster encrypt-file "$INPUT_FILE" "$RECIPIENT_DID" > "$OUTPUT_FILE"

FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)

echo "✓ File encrypted"
echo ""
echo "Encrypted file: $OUTPUT_FILE ($FILE_SIZE)"
echo ""
echo "Send this file to the recipient. Only they can decrypt it."
echo ""
echo "Recipient decrypts with:"
echo "  ./decrypt-file.sh $OUTPUT_FILE <output-filename>"
