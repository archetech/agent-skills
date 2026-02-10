#!/bin/bash
# Sign a JSON file with your DID
# Usage: ./sign-file.sh <file>

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <file>"
    echo ""
    echo "Examples:"
    echo "  $0 manifest.json"
    echo "  $0 contract.json"
    echo ""
    echo "Note: File must be valid JSON. The signature (proof) is added to the file."
    exit 1
fi

FILE="$1"

# Check file exists
if [ ! -f "$FILE" ]; then
    echo "ERROR: File not found: $FILE"
    exit 1
fi

# Check it's JSON
if ! jq empty "$FILE" 2>/dev/null; then
    echo "ERROR: File is not valid JSON"
    exit 1
fi

# Load environment
if [ -f ~/.archon.env ]; then
    source ~/.archon.env
else
    echo "ERROR: ~/.archon.env not found"
    exit 1
fi

echo "Signing: $FILE"
echo ""

# Create backup
BACKUP_FILE="${FILE}.backup"
cp "$FILE" "$BACKUP_FILE"

# Sign file (modifies in place)
cd ~/clawd
if npx @didcid/keymaster sign-file "$FILE" > /dev/null 2>&1; then
    echo "✓ File signed"
    echo ""
    echo "Signature added to: $FILE"
    echo "Backup saved to: $BACKUP_FILE"
    echo ""
    echo "Others can verify with:"
    echo "  ./verify-file.sh $FILE"
    
    # Clean up backup if signing succeeded
    rm "$BACKUP_FILE"
else
    echo "✗ Signing failed"
    echo "Original file preserved at: $BACKUP_FILE"
    mv "$BACKUP_FILE" "$FILE"
    exit 1
fi
