#!/bin/bash
# Store secrets in an Archon vault
# Usage: store.sh [--vault NAME] [--dir PATH] [--pattern "*.env"] [--member DID]...
#
# Packs matching files, encrypts via Archon vault.
# Creates the vault if needed, adds members for shared access.
# Supports group-based access: use --group to set group ownership.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

VAULT_NAME="${SECRETS_VAULT_NAME:-secrets}"
SECRETS_DIR="${SECRETS_DIR:-$HOME/.config}"
PATTERN="${SECRETS_PATTERN:-*.env}"
LABEL="secrets-bundle"
MEMBERS=()
GROUP=""

# --- Input validation ---
_validate_name() {
    local name="$1" field="$2"
    if [[ ! "$name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        echo "ERROR: Invalid $field: '$name' (alphanumeric, dots, hyphens, underscores only)" >&2
        exit 1
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --vault)   VAULT_NAME="$2"; shift 2 ;;
        --dir)     SECRETS_DIR="$2"; shift 2 ;;
        --pattern) PATTERN="$2"; shift 2 ;;
        --label)   LABEL="$2"; shift 2 ;;
        --member)  MEMBERS+=("$2"); shift 2 ;;
        --group)   GROUP="$2"; shift 2 ;;
        --api)     export ARCHON_MODE="api"; shift ;;
        -h|--help)
            echo "Usage: store.sh [OPTIONS]"
            echo "  --vault NAME     Vault name/alias (default: secrets)"
            echo "  --dir PATH       Directory containing secrets (default: ~/.config)"
            echo "  --pattern GLOB   File pattern (default: *.env)"
            echo "  --label NAME     Bundle label (default: secrets-bundle)"
            echo "  --member DID     Add DID as vault member (repeatable)"
            echo "  --group NAME     Group for shared vault ownership"
            echo "  --api            Use keymaster API instead of CLI"
            exit 0 ;;
        *) echo "Unknown: $1" >&2; exit 1 ;;
    esac
done

# Validate inputs to prevent path traversal
_validate_name "$VAULT_NAME" "vault name"
_validate_name "$LABEL" "label"

# Validate members are DIDs
for member in "${MEMBERS[@]}"; do
    if [[ ! "$member" =~ ^did: ]]; then
        echo "ERROR: Member must be a DID (starts with 'did:'): $member" >&2
        exit 1
    fi
done

# Validate secrets directory exists
if [ ! -d "$SECRETS_DIR" ]; then
    echo "ERROR: Secrets directory does not exist: $SECRETS_DIR" >&2
    exit 1
fi

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

BUNDLE="$WORK_DIR/${LABEL}.tar.gz"

echo "📦 Packing secrets from $SECRETS_DIR (pattern: $PATTERN)..."

# Build file list safely (null-delimited)
mapfile -d '' FILES < <(find "$SECRETS_DIR" -maxdepth 1 -name "$PATTERN" -type f -print0 2>/dev/null)
if [ ${#FILES[@]} -eq 0 ]; then
    echo "ERROR: No files matching '$PATTERN' in $SECRETS_DIR" >&2
    exit 1
fi

# Create tar with files relative to SECRETS_DIR
tar czf "$BUNDLE" -C "$SECRETS_DIR" "${FILES[@]##*/}"
COUNT=${#FILES[@]}
echo "   Packed $COUNT files"

# Resolve or create vault
VAULT_DID=$(archon_resolve_vault "$VAULT_NAME" 2>/dev/null) || VAULT_DID=""

if [ -z "$VAULT_DID" ]; then
    echo "🔨 Creating vault '$VAULT_NAME'..."
    if archon_is_api_mode; then
        VAULT_DID=$(archon_api_post "/vaults" "{\"alias\": \"$VAULT_NAME\"}" | jq -r '.did // .')
    else
        VAULT_DID=$(archon_cli create-vault -a "$VAULT_NAME")
    fi
    echo "   Vault: $VAULT_DID"
fi

# Add members
for member in "${MEMBERS[@]}"; do
    echo "👤 Adding member: ${member:0:40}..."
    if ! archon_add_vault_member "$VAULT_DID" "$member" >/dev/null 2>&1; then
        echo "⚠️  Failed to add member (may already exist or vault size limit)"
    fi
done

# Transfer to group if specified
if [ -n "$GROUP" ]; then
    echo "🔗 Setting group ownership: $GROUP"
    if ! archon_transfer_asset "$VAULT_DID" "$GROUP" >/dev/null 2>&1; then
        echo "⚠️  Group transfer not supported — vault remains under current owner"
    fi
fi

echo "🔐 Uploading encrypted bundle..."
archon_add_vault_item "$VAULT_DID" "$BUNDLE"

HASH=$(sha256sum "$BUNDLE" | cut -d' ' -f1)
MEMBER_COUNT=$(archon_list_vault_members "$VAULT_DID" 2>/dev/null | jq 'keys | length' 2>/dev/null || echo "?")
echo ""
echo "✅ Secrets stored in vault '$VAULT_NAME'"
echo "   Vault DID: $VAULT_DID"
echo "   Bundle: ${LABEL}.tar.gz ($COUNT files)"
echo "   Members: $MEMBER_COUNT (+ owner)"
echo "   SHA256: ${HASH:0:16}..."
