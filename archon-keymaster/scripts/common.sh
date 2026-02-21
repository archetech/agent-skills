#!/bin/bash
# common.sh — Shared environment loader for archon-keymaster scripts
#
# Sources archon environment (passphrase, wallet path, config dir).
# Supports both CLI (personal wallet) and API (node keymaster) modes.
#
# Usage: source "$(dirname "$0")/../common.sh"
#   or:  source "$(dirname "$0")/common.sh"   (from same dir)
#
# Environment variables (set before sourcing, or auto-detected):
#   ARCHON_MODE        "cli" (default) or "api"
#   ARCHON_API_URL     Keymaster API URL (default: http://localhost:4226)
#   ARCHON_CONFIG_DIR  Directory containing wallet.json (for CLI mode)
#   ARCHON_WALLET_PATH Path to wallet.json (for CLI mode)
#   ARCHON_PASSPHRASE  Wallet passphrase (for CLI mode)
#
# Environment files searched (first found wins):
#   $ARCHON_ENV_FILE (explicit override)
#   ~/.config/hex/archon.env
#   ~/.config/archon/archon.env
#   ~/.archon.env

# --- Environment loading ---

_archon_load_env() {
    # Already loaded?
    if [ -n "$_ARCHON_ENV_LOADED" ]; then
        return 0
    fi

    # Search for env file
    local env_file="${ARCHON_ENV_FILE:-}"
    if [ -z "$env_file" ]; then
        for candidate in \
            "$HOME/.config/hex/archon.env" \
            "$HOME/.config/archon/archon.env" \
            "$HOME/.archon.env"; do
            if [ -f "$candidate" ]; then
                env_file="$candidate"
                break
            fi
        done
    fi

    if [ -n "$env_file" ] && [ -f "$env_file" ]; then
        source "$env_file"
        export ARCHON_PASSPHRASE  # npx subprocesses need this
    fi

    # Set defaults
    export ARCHON_MODE="${ARCHON_MODE:-cli}"
    export ARCHON_API_URL="${ARCHON_API_URL:-http://localhost:4226}"

    _ARCHON_ENV_LOADED=1
}

# --- Mode detection ---

archon_is_api_mode() {
    [ "$ARCHON_MODE" = "api" ]
}

# --- CLI helpers ---

# Run a keymaster CLI command (personal wallet)
archon_cli() {
    if [ -z "$ARCHON_CONFIG_DIR" ] && [ -z "$ARCHON_WALLET_PATH" ]; then
        echo "ERROR: ARCHON_CONFIG_DIR or ARCHON_WALLET_PATH must be set for CLI mode" >&2
        return 1
    fi
    npx --yes @didcid/keymaster "$@"
}

# --- API helpers ---

# GET request to keymaster API
archon_api_get() {
    local path="$1"
    curl -sf "${ARCHON_API_URL}/api/v1${path}"
}

# POST request to keymaster API
archon_api_post() {
    local path="$1"
    local data="$2"
    if [ -n "$data" ]; then
        curl -sf -X POST "${ARCHON_API_URL}/api/v1${path}" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -sf -X POST "${ARCHON_API_URL}/api/v1${path}"
    fi
}

# DELETE request to keymaster API
archon_api_delete() {
    local path="$1"
    curl -sf -X DELETE "${ARCHON_API_URL}/api/v1${path}"
}

# --- Vault operations (mode-aware) ---

# List vault items (works in both modes)
archon_list_vault_items() {
    local vault_id="$1"
    if archon_is_api_mode; then
        archon_api_get "/vaults/${vault_id}/items"
    else
        archon_cli list-vault-items "$vault_id"
    fi
}

# Get vault item (works in both modes)
archon_get_vault_item() {
    local vault_id="$1"
    local item_name="$2"
    local output="$3"
    if archon_is_api_mode; then
        curl -sf "${ARCHON_API_URL}/api/v1/vaults/${vault_id}/items/${item_name}" -o "$output"
    else
        archon_cli get-vault-item "$vault_id" "$item_name" "$output"
    fi
}

# Add vault item (works in both modes)
archon_add_vault_item() {
    local vault_id="$1"
    local file_path="$2"
    if archon_is_api_mode; then
        local filename=$(basename "$file_path")
        curl -sf -X POST "${ARCHON_API_URL}/api/v1/vaults/${vault_id}/items" \
            -F "file=@${file_path};filename=${filename}"
    else
        archon_cli add-vault-item "$vault_id" "$file_path"
    fi
}

# Remove vault item (works in both modes)
archon_remove_vault_item() {
    local vault_id="$1"
    local item_name="$2"
    if archon_is_api_mode; then
        archon_api_delete "/vaults/${vault_id}/items/${item_name}"
    else
        archon_cli remove-vault-item "$vault_id" "$item_name"
    fi
}

# List vault members (works in both modes)
archon_list_vault_members() {
    local vault_id="$1"
    if archon_is_api_mode; then
        archon_api_get "/vaults/${vault_id}/members"
    else
        archon_cli list-vault-members "$vault_id"
    fi
}

# Add vault member (works in both modes)
archon_add_vault_member() {
    local vault_id="$1"
    local member="$2"
    if archon_is_api_mode; then
        archon_api_post "/vaults/${vault_id}/members" "{\"member\": \"$member\"}"
    else
        archon_cli add-vault-member "$vault_id" "$member"
    fi
}

# Remove vault member (works in both modes)
archon_remove_vault_member() {
    local vault_id="$1"
    local member="$2"
    if archon_is_api_mode; then
        archon_api_delete "/vaults/${vault_id}/members/${member}"
    else
        archon_cli remove-vault-member "$vault_id" "$member"
    fi
}

# --- Group operations (mode-aware) ---

# Create group
archon_create_group() {
    local name="$1"
    local registry="${2:-hyperswarm}"
    if archon_is_api_mode; then
        archon_api_post "/groups" "{\"name\": \"$name\", \"registry\": \"$registry\"}"
    else
        archon_cli create-group "$name" -r "$registry"
    fi
}

# Add group member
archon_add_group_member() {
    local group="$1"
    local member="$2"
    if archon_is_api_mode; then
        archon_api_post "/groups/${group}/add" "{\"member\": \"$member\"}"
    else
        archon_cli add-group-member "$group" "$member"
    fi
}

# Test group membership
archon_test_group_member() {
    local group="$1"
    local member="$2"
    if archon_is_api_mode; then
        archon_api_get "/groups/${group}/test/${member}" | jq -r '.member // false'
    else
        archon_cli test-group-member "$group" "$member"
    fi
}

# Get group info
archon_get_group() {
    local group="$1"
    if archon_is_api_mode; then
        archon_api_get "/groups/${group}"
    else
        archon_cli resolve-did "$group" 2>/dev/null | jq '.didDocumentData.group'
    fi
}

# --- Alias operations (mode-aware) ---

archon_add_alias() {
    local alias="$1"
    local did="$2"
    if archon_is_api_mode; then
        archon_api_post "/aliases" "{\"alias\": \"$alias\", \"did\": \"$did\"}"
    else
        archon_cli add-alias "$alias" "$did"
    fi
}

archon_list_aliases() {
    if archon_is_api_mode; then
        archon_api_get "/aliases" | jq -r '.aliases'
    else
        archon_cli list-aliases
    fi
}

# --- Transfer operations ---

archon_transfer_asset() {
    local asset="$1"
    local controller="$2"
    if archon_is_api_mode; then
        archon_api_post "/assets/${asset}/transfer" "{\"controller\": \"$controller\"}"
    else
        archon_cli transfer-asset "$asset" "$controller"
    fi
}

# --- Passphrase operations ---

archon_change_passphrase() {
    local new_passphrase="$1"
    if archon_is_api_mode; then
        archon_api_post "/wallet/passphrase" "{\"passphrase\": \"$new_passphrase\"}"
    else
        archon_cli change-passphrase "$new_passphrase"
    fi
}

# --- Utility ---

# Resolve a vault name to DID (checks aliases, then treats as DID)
archon_resolve_vault() {
    local vault_ref="$1"
    if [[ "$vault_ref" == did:* ]]; then
        echo "$vault_ref"
        return 0
    fi
    # Try alias lookup
    local did
    if archon_is_api_mode; then
        did=$(archon_api_get "/aliases" 2>/dev/null | jq -r ".aliases.\"$vault_ref\" // empty")
    else
        did=$(archon_cli list-aliases 2>/dev/null | jq -r ".\"$vault_ref\" // empty")
    fi
    if [ -n "$did" ]; then
        echo "$did"
    else
        echo "ERROR: Could not resolve vault '$vault_ref'" >&2
        return 1
    fi
}

# Auto-load on source
_archon_load_env
