#!/bin/bash
# Decrypt an encrypted file
# Usage: ./decrypt-file.sh <encrypted-file> <output-file>

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <encrypted-file> <output-file>"
    echo ""
    echo "Examples:"
    echo "  $0 encrypted.json secret.pdf"
    echo "  $0 secure.json document.txt"
    exit 1
fi

ENCRYPTED_FILE="$1"
OUTPUT_FILE="$2"

# Check encrypted file exists
if [ ! -f "$ENCRYPTED_FILE" ]; then
    echo "ERROR: Encrypted file not found: $ENCRYPTED_FILE"
    exit 1
fi

# Load environment
if [ -f ~/.archon.env ]; then
    source ~/.archon.env
else
    echo "ERROR: ~/.archon.env not found"
    exit 1
fi

echo "Decrypting: $ENCRYPTED_FILE"
echo "Output: $OUTPUT_FILE"
echo ""

# Decrypt (decrypt-json writes to stdout, we redirect to file)
cd ~/clawd
npx @didcid/keymaster decrypt-json "$(cat $ENCRYPTED_FILE)" > "$OUTPUT_FILE"

FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)

echo "✓ File decrypted"
echo ""
echo "Decrypted file: $OUTPUT_FILE ($FILE_SIZE)"
