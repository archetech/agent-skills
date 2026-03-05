#!/usr/bin/env bash
set -euo pipefail

# lightning-zap.sh - Send sats via Lightning Address, DID, or alias
# Usage: ./lightning-zap.sh <recipient> <amount> [memo] [id]
# recipient: Lightning Address (user@domain.com), DID, or alias

source ~/.archon.env

npx @didcid/keymaster lightning-zap "$@"
