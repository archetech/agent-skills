#!/usr/bin/env bash
set -euo pipefail

# lightning-check.sh - Verify payment status
# Usage: ./lightning-check.sh <paymentHash> [id]
# Returns: {"paid": true|false, ...}

source ~/.nvm/nvm.sh
source ~/.archon.env

npx @didcid/keymaster lightning-check "$@"
