#!/bin/bash
# Backup workspace, config, and hexmem to DID vault
# Run during heartbeat checks (daily)

set -e

# Load passphrase from .archon.env
if [ -f ~/clawd/.archon.env ]; then
    source ~/clawd/.archon.env
    export ARCHON_PASSPHRASE  # Must explicitly export for npx subprocesses
else
    echo "ERROR: ~/clawd/.archon.env not found"
    exit 1
fi

# Use public Gatekeeper by default (10MB limit)
# Override with local if needed: export ARCHON_GATEKEEPER_URL="http://localhost:4224"
export ARCHON_GATEKEEPER_URL="${ARCHON_GATEKEEPER_URL:-https://archon.technology}"

# Ensure Keymaster always uses the correct wallet regardless of cwd
export KEYMASTER_WALLET="$HOME/clawd/wallet.json"

echo "=== DID Vault Backup $(date) ==="

# Backup workspace (excludes .git, node_modules, etc per .backup-ignore)
echo "Backing up workspace..."
cd /tmp
rm -f workspace.zip
zip -q -r workspace.zip ~/clawd -x@$HOME/clawd/.backup-ignore
(cd ~/clawd && npx @didcid/keymaster add-vault-item backup /tmp/workspace.zip)
echo "✓ workspace.zip ($(du -h workspace.zip | cut -f1))"

# Backup config (excludes sessions, cache, logs per patterns)
echo "Backing up config..."
cd ~/.openclaw
rm -f /tmp/config.zip
zip -q -r /tmp/config.zip . \
  -x 'agents/*/sessions/*' \
  -x 'agents/*/cache/*' \
  -x 'logs/*' \
  -x '*.log' \
  -x 'browser/*' \
  -x 'media/*' \
  -x 'canvas/*'
(cd ~/clawd && npx @didcid/keymaster add-vault-item backup /tmp/config.zip)
echo "✓ config.zip ($(du -h /tmp/config.zip | cut -f1))"

# Backup hexmem database
echo "Backing up hexmem..."
cd ~/clawd
npx @didcid/keymaster add-vault-item backup hexmem/hexmem.db
echo "✓ hexmem.db ($(du -h hexmem/hexmem.db | cut -f1))"

# Verify
echo ""
echo "=== Vault Contents ==="
npx @didcid/keymaster list-vault-items backup | jq -r 'to_entries[] | "\(.key): \(.value.bytes / 1024 / 1024 | floor)MB (\(.value.added))"'

echo ""
echo "Backup complete."
