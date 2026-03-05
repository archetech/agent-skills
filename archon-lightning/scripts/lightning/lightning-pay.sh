#!/usr/bin/env bash
set -euo pipefail

# lightning-pay.sh - Pay BOLT11 invoice
# Usage: ./lightning-pay.sh <bolt11> [id]
# Returns: {"paymentHash": "..."} - ALWAYS VERIFY WITH lightning-check.sh!

source ~/.nvm/nvm.sh
source ~/.archon.env

npx @didcid/keymaster lightning-pay "$@"
