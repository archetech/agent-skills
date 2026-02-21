#!/bin/bash
# Archon Cashu Wallet — Configuration
# Usage: config.sh [--set KEY VALUE]
set -e

CONFIG_FILE="${ARCHON_CASHU_CONFIG:-$HOME/.config/hex/archon-cashu.env}"

# Defaults
DEFAULT_CASHU_BIN="/home/sat/.cache/pypoetry/virtualenvs/cashu-Mr2KwNb2-py3.12/bin/cashu"
DEFAULT_MINT_URL="https://bolverker.com/cashu"
DEFAULT_LNBITS_ENV="$HOME/.config/hex/lnbits.env"
DEFAULT_ARCHON_CONFIG_DIR="$HOME/clawd/archon-personal"
DEFAULT_ARCHON_WALLET_PATH="$HOME/clawd/archon-personal/wallet.json"
DEFAULT_ARCHON_PASSPHRASE="hex-daemon-lightning-hive-2026"

create_default_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
# Archon Cashu Wallet Configuration
CASHU_BIN="$DEFAULT_CASHU_BIN"
CASHU_MINT_URL="$DEFAULT_MINT_URL"
LNBITS_ENV="$DEFAULT_LNBITS_ENV"
ARCHON_CONFIG_DIR="$DEFAULT_ARCHON_CONFIG_DIR"
ARCHON_WALLET_PATH="$DEFAULT_ARCHON_WALLET_PATH"
ARCHON_PASSPHRASE="$DEFAULT_ARCHON_PASSPHRASE"
EOF
    chmod 600 "$CONFIG_FILE"
    echo "Created config at $CONFIG_FILE"
}

load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        create_default_config
    fi
    source "$CONFIG_FILE"
    
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
