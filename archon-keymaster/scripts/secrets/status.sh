#!/bin/bash
# Check secrets vault status
# Usage: status.sh [--vault NAME] [--did DID] [--api]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

VAULT_NAME="${SECRETS_VAULT_NAME:-secrets}"
VAULT_DID="${SECRETS_VAULT_DID:-}"

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
        --vault) VAULT_NAME="$2"; shift 2 ;;
        --did)   VAULT_DID="$2"; shift 2 ;;
        --api)   export ARCHON_MODE="api"; shift ;;
        -h|--help)
            echo "Usage: status.sh [OPTIONS]"
            echo "  --vault NAME   Vault name/alias (default: secrets)"
            echo "  --did DID      Vault DID directly"
            echo "  --api          Use keymaster API instead of CLI"
            exit 0 ;;
        *) echo "Unknown: $1" >&2; exit 1 ;;
    esac
done

# Validate inputs
_validate_name "$VAULT_NAME" "vault name"

if [ -n "$VAULT_DID" ] && [[ ! "$VAULT_DID" =~ ^did: ]]; then
    echo "ERROR: --did must be a DID (starts with 'did:')" >&2
    exit 1
fi

# Resolve vault DID
if [ -z "$VAULT_DID" ]; then
    VAULT_DID=$(archon_resolve_vault "$VAULT_NAME" 2>/dev/null) || VAULT_DID=""
fi

if [ -z "$VAULT_DID" ]; then
    echo "❌ No vault '$VAULT_NAME' found"
    echo "   Create: store.sh --vault $VAULT_NAME --dir /path/to/secrets"
    echo "   Shared: status.sh --did <vault-did>"
    exit 1
fi

echo "🔐 Secrets Vault: $VAULT_NAME"
echo "   DID: $VAULT_DID"
echo "   Mode: ${ARCHON_MODE:-cli}"
echo ""

echo "📦 Contents:"
archon_list_vault_items "$VAULT_DID" 2>/dev/null | jq -r '
    to_entries[] | "   \(.key) — \(.value.bytes // "?") bytes, added \(.value.added // "unknown")"
' 2>/dev/null || echo "   (unable to list — may need owner/member access)"

echo ""
echo "👥 Members:"
archon_list_vault_members "$VAULT_DID" 2>/dev/null | jq -r '
    to_entries[] | "   \(.key | .[0:50])... — added \(.value.added // "unknown")"
' 2>/dev/null || echo "   (unable to list — may need owner access)"

echo ""
echo "💾 Local status:"
if [ -d "/dev/shm/${VAULT_NAME}" ]; then
    local_count=$(find "/dev/shm/${VAULT_NAME}" -maxdepth 1 -name "*.env" 2>/dev/null | wc -l)
    echo "   RAM: ✅ $local_count files loaded (/dev/shm/${VAULT_NAME})"
else
    echo "   RAM: ❌ not loaded (run: restore.sh --to-ram)"
fi
