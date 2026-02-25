#!/bin/bash
# Archon Cashu Wallet — Configuration
# Usage: config.sh [--set KEY VALUE]
set -e

CONFIG_FILE="${ARCHON_CASHU_CONFIG:-$HOME/.config/hex/archon-cashu.env}"

# Defaults — auto-discover cashu binary
DEFAULT_CASHU_BIN="$(command -v cashu 2>/dev/null || echo "")"
DEFAULT_MINT_URL="https://mint.minibits.cash/Bitcoin"
DEFAULT_LNBITS_ENV=""
DEFAULT_ARCHON_CONFIG_DIR="${ARCHON_CONFIG_DIR:-}"
DEFAULT_ARCHON_WALLET_PATH=""
DEFAULT_ARCHON_PASSPHRASE="${ARCHON_PASSPHRASE:-}"

create_default_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
# Archon Cashu Wallet Configuration
# CASHU_BIN — path to cashu CLI (auto-detected if on PATH, or: pip install cashu)
CASHU_BIN="${DEFAULT_CASHU_BIN}"
# CASHU_MINT_URL — default Cashu mint
CASHU_MINT_URL="${DEFAULT_MINT_URL}"
# LNBITS_ENV — optional, for LNbits integration
LNBITS_ENV=""
# ARCHON_CONFIG_DIR — path to your Archon/keymaster wallet directory
ARCHON_CONFIG_DIR="${DEFAULT_ARCHON_CONFIG_DIR}"
# ARCHON_WALLET_PATH — path to wallet.json (leave empty to use ARCHON_CONFIG_DIR default)
ARCHON_WALLET_PATH=""
# ARCHON_PASSPHRASE — wallet passphrase (or set via environment variable)
ARCHON_PASSPHRASE=""
EOF
    chmod 600 "$CONFIG_FILE"
    echo "Created config at $CONFIG_FILE"
}

load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        create_default_config
    fi
    source "$CONFIG_FILE"
    
    # Auto-discover cashu if not configured
    if [ -z "$CASHU_BIN" ]; then
        CASHU_BIN="$(command -v cashu 2>/dev/null || echo "")"
    fi
    if [ -z "$CASHU_BIN" ] || [ ! -x "$CASHU_BIN" ]; then
        echo "ERROR: cashu CLI not found. Install with: pip install cashu" >&2
        echo "Then set CASHU_BIN in $CONFIG_FILE or ensure 'cashu' is on your PATH." >&2
        return 1 2>/dev/null || exit 1
    fi
    
    # Export for archon scripts
    export ARCHON_CONFIG_DIR ARCHON_WALLET_PATH ARCHON_PASSPHRASE
    export MINT_URL="$CASHU_MINT_URL"
    
    # Load LNbits if available
    if [ -f "$LNBITS_ENV" ]; then
        source "$LNBITS_ENV"
    fi
}

if [ "$1" = "--set" ] && [ -n "$2" ] && [ -n "$3" ]; then
    load_config
    sed -i "s|^$2=.*|$2=\"$3\"|" "$CONFIG_FILE"
    echo "Set $2=$3"
elif [ "$1" = "--create" ]; then
    create_default_config
else
    load_config
    echo "Archon Cashu Wallet Config"
    echo "========================="
    echo "Config:     $CONFIG_FILE"
    echo "Cashu CLI:  $CASHU_BIN"
    echo "Mint:       $CASHU_MINT_URL"
    echo "LNbits:     $LNBITS_ENV"
    echo "Archon Dir: $ARCHON_CONFIG_DIR"
    echo "Wallet:     $ARCHON_WALLET_PATH"
fi
