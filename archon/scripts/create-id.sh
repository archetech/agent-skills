#!/bin/bash
# Create your first Archon DID and set up secure environment
# Run this once when setting up Archon for the first time

set -e

echo "=== Archon Identity Setup ==="
echo ""

# Check if wallet already exists
if [ -f ~/clawd/wallet.json ]; then
    echo "ERROR: Wallet already exists at ~/clawd/wallet.json"
    echo ""
    echo "If you want to create a new identity in your existing wallet, use:"
    echo "  ./scripts/create-additional-id.sh <did-name>"
    echo ""
    echo "If you want to start over (WARNING: will lose existing DIDs), remove:"
    echo "  rm ~/clawd/wallet.json ~/.archon.env"
    exit 1
fi

# Check if .archon.env already exists
if [ -f ~/.archon.env ]; then
    echo "WARNING: ~/.archon.env already exists"
    read -p "Overwrite? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Aborted."
        exit 1
    fi
fi

# Generate secure passphrase (or let user provide one)
echo "Generating secure passphrase..."
PASSPHRASE=$(openssl rand -base64 32 | tr -d '/+=' | cut -c1-32)

# Create .archon.env
echo "Creating ~/.archon.env..."
cat > ~/.archon.env << EOF
# Archon passphrase - keeps your wallet encrypted
# DO NOT COMMIT THIS FILE TO GIT
export ARCHON_PASSPHRASE="$PASSPHRASE"
export ARCHON_GATEKEEPER_URL="https://archon.technology"  # Public gatekeeper (10MB limit)
# For local gatekeeper (unlimited): export ARCHON_GATEKEEPER_URL="http://localhost:4224"
export KEYMASTER_WALLET="$HOME/clawd/wallet.json"
EOF

chmod 600 ~/.archon.env
echo "✓ Passphrase saved to ~/.archon.env (chmod 600)"

# Source it for this session
source ~/.archon.env

# Create wallet directory
mkdir -p ~/clawd

# Create DID
echo ""
echo "Creating your Archon DID..."
echo "(This will prompt you to create a wallet and generate a mnemonic)"
echo ""

cd ~/clawd
npx @didcid/keymaster create-did

echo ""
echo "=== Setup Complete ==="
echo ""
echo "✓ Wallet created: ~/clawd/wallet.json"
echo "✓ Environment configured: ~/.archon.env"
echo ""
echo "CRITICAL: Your 12-word mnemonic was displayed above."
echo "         Write it down and store it offline (paper, metal plate, etc.)"
echo "         This is the ONLY way to recover your identity."
echo ""
echo "To use your DID in other terminal sessions, run:"
echo "  source ~/.archon.env"
echo ""
echo "Next steps:"
echo "  - Save your mnemonic securely (offline!)"
echo "  - Set up backups: archon-backup skill"
echo "  - Backup wallet to seed bank: npx @didcid/keymaster backup-wallet-did"
echo ""
echo "View your DID:"
echo "  npx @didcid/keymaster list-dids"
