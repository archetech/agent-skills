#!/bin/bash
# Restore secrets from an Archon vault
# Usage: restore.sh [--vault NAME] [--dir PATH] [--to-ram] [--api] [--dry-run]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

VAULT_NAME="${SECRETS_VAULT_NAME:-secrets}"
VAULT_DID="${SECRETS_VAULT_DID:-}"
SECRETS_DIR="${SECRETS_DIR:-$HOME/.config}"
LABEL="secrets-bundle"
DRY_RUN=false
TO_RAM=false

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
        --did)     VAULT_DID="$2"; shift 2 ;;
        --dir)     SECRETS_DIR="$2"; shift 2 ;;
        --label)   LABEL="$2"; shift 2 ;;
        --to-ram)  TO_RAM=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --api)     export ARCHON_MODE="api"; shift ;;
        -h|--help)
            echo "Usage: restore.sh [OPTIONS]"
            echo "  --vault NAME   Vault name/alias (default: secrets)"
            echo "  --did DID      Vault DID directly (for shared vaults)"
            echo "  --dir PATH     Restore destination (default: ~/.config)"
            echo "  --to-ram       Restore to /dev/shm (RAM) instead of disk"
            echo "  --api          Use keymaster API instead of CLI"
            echo "  --dry-run      Show contents without writing"
            exit 0 ;;
        *) echo "Unknown: $1" >&2; exit 1 ;;
    esac
done

# Validate inputs
_validate_name "$VAULT_NAME" "vault name"
_validate_name "$LABEL" "label"

if [ -n "$VAULT_DID" ] && [[ ! "$VAULT_DID" =~ ^did: ]]; then
    echo "ERROR: --did must be a DID (starts with 'did:')" >&2
    exit 1
fi

# Resolve vault DID
if [ -z "$VAULT_DID" ]; then
    VAULT_DID=$(archon_resolve_vault "$VAULT_NAME") || exit 1
fi

if [ "$TO_RAM" = true ]; then
    SECRETS_DIR="/dev/shm/${VAULT_NAME}"
fi

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT
BUNDLE="$WORK_DIR/${LABEL}.tar.gz"

echo "🔓 Downloading from vault..."
echo "   DID: ${VAULT_DID:0:50}..."
archon_get_vault_item "$VAULT_DID" "${LABEL}.tar.gz" "$BUNDLE"

if [ ! -f "$BUNDLE" ] || [ ! -s "$BUNDLE" ]; then
    echo "❌ Failed to retrieve '${LABEL}.tar.gz' from vault." >&2
    echo "   Available items:"
    archon_list_vault_items "$VAULT_DID" 2>/dev/null | jq -r 'keys[]' 2>/dev/null || true
    exit 1
fi

# Validate tarball — reject path traversal attempts
echo "📦 Validating bundle..."
if tar tzf "$BUNDLE" 2>/dev/null | grep -qE '(^/|\.\./)'; then
    echo "❌ SECURITY: Tarball contains absolute or traversal paths — aborting!" >&2
    exit 1
fi

echo "📦 Bundle contents:"
tar tzf "$BUNDLE" 2>/dev/null | sed 's/^/   /'

if [ "$DRY_RUN" = true ]; then
    echo ""; echo "🔍 Dry run — no files written."; exit 0
fi

mkdir -p "$SECRETS_DIR"
chmod 700 "$SECRETS_DIR"
tar xzf "$BUNDLE" -C "$SECRETS_DIR"
find "$SECRETS_DIR" -maxdepth 1 -name "*.env" -exec chmod 600 {} \;

COUNT=$(tar tzf "$BUNDLE" 2>/dev/null | wc -l)
LOCATION="disk ($SECRETS_DIR)"
[ "$TO_RAM" = true ] && LOCATION="RAM ($SECRETS_DIR — wiped on reboot)"
echo ""
echo "✅ Restored $COUNT files to $LOCATION"
