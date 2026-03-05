#!/usr/bin/env bash
set -euo pipefail

# publish-lightning.sh - Publish Lightning endpoint to DID document
# Usage: ./publish-lightning.sh [id]

source ~/.nvm/nvm.sh
source ~/.archon.env

npx @didcid/keymaster publish-lightning "$@"
