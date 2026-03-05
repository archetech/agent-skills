#!/usr/bin/env bash
set -euo pipefail

# lightning-decode.sh - Decode BOLT11 invoice details
# Usage: ./lightning-decode.sh <bolt11>

source ~/.nvm/nvm.sh
source ~/.archon.env

npx @didcid/keymaster lightning-decode "$@"
