#!/bin/bash
# Archon Cashu Wallet — Configuration
# Usage: config.sh [--set KEY VALUE] [--create]
#
# Configuration is stored in $ARCHON_CASHU_CONFIG (default: ~/.config/archon/cashu.env)
# On first run, creates a template config that you must edit with your paths/credentials.
set -e

CONFIG_FILE="${ARCHON_CASHU_CONFIG:-$HOME/.config/archon/cashu.env}"

# Defaults — override in config file
DEFAULT_CASHU_BIN="${CASHU_BIN:-cashu}"
DEFAULT_MINT_URL="https://bolverker.com/cashu"
DEFAULT_LNBITS_ENV="$HOME/.config/lnbits.env"
DEFAULT_ARCHON_CONFIG_DIR="${ARCHON_CONFIG_DIR:-$HOME/.config/archon}"
DEFAULT_ARCHON_WALLET_PATH="${ARCHON_WALLET_PATH:-$HOME/.config/archon/wallet.json}"
DEFAULT_ARCHON_PASSPHRASE="${ARCHON_PASSPHRASE:-}"

create_default_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
# Archon Cashu Wallet Configuration
# Edit these values for your setup

# Path to nutshell cashu CLI binary
CASHU_BIN="$DEFAULT_CASHU_BIN"

# Default mint URL (Cashu mint to use)
CASHU_MINT_URL="$DEFAULT_MINT_URL"

# LNbits environment file (for auto-minting via Lightning)
# Should export LNBITS_HOST, LNBITS_ADMIN_KEY, LNBITS_INVOICE_KEY
LNBITS_ENV="$DEFAULT_LNBITS_ENV"

# Archon keymaster wallet settings
ARCHON_CONFIG_DIR="$DEFAULT_ARCHON_CONFIG_DIR"
ARCHON_WALLET_PATH="$DEFAULT_ARCHON_WALLET_PATH"
ARCHON_PASSPHRASE="$DEFAULT_ARCHON_PASSPHRASE"
EOF
    chmod 600 "$CONFIG_FILE"
    echo "Created config at $CONFIG_FILE"
    echo "⚠️  Edit $CONFIG_FILE with your paths and credentials before use."
}

load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        create_default_config
    fi
    source "$CONFIG_FILE"

    # Validate required settings
    if [ -z "$CASHU_BIN" ] || ! command -v "$CASHU_BIN" &> /dev/null; then
        if [ "$1" != "quiet" ]; then
            echo "⚠️  CASHU_BIN not found: $CASHU_BIN"
            echo "Install nutshell: pip install cashu"
            echo "Then set CASHU_BIN in $CONFIG_FILE"
        fi
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
    load_config quiet
    sed -i "s|^$2=.*|$2=\"$3\"|" "$CONFIG_FILE"
    echo "Set $2=$3"
elif [ "$1" = "--create" ]; then
    create_default_config
else
    load_config quiet
    echo "Archon Cashu Wallet Config"
    echo "========================="
    echo "Config:     $CONFIG_FILE"
    echo "Cashu CLI:  ${CASHU_BIN:-not set}"
    echo "Mint:       ${CASHU_MINT_URL:-not set}"
    echo "LNbits:     ${LNBITS_ENV:-not set}"
    echo "Archon Dir: ${ARCHON_CONFIG_DIR:-not set}"
    echo "Wallet:     ${ARCHON_WALLET_PATH:-not set}"
fi
