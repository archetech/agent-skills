# Archon Cashu Wallet

DID-native ecash wallet that encrypts cashu tokens to Archon DIDs and delivers them via dmail.

## Prerequisites

- [Nutshell](https://github.com/cashubtc/nutshell) (`pip install cashu`) — cashu protocol CLI
- [Archon](https://github.com/ArcHive-tech/archon) node with keymaster running
- Archon keymaster wallet with at least one DID identity
- (Optional) [LNbits](https://lnbits.com) for auto-minting via Lightning

## Setup

```bash
# Create config (edit with your paths)
./config.sh --create

# Edit the config
nano ~/.config/archon/cashu.env

# Verify
./config.sh
```

## Scripts

| Script | Description |
|--------|-------------|
| `config.sh` | Configuration management |
| `balance.sh` | Show cashu wallet balance |
| `mint.sh <amount>` | Mint tokens (auto-pays from LNbits if configured) |
| `send.sh <did> <amount> [memo]` | Send ecash via encrypted dmail |
| `receive.sh [--auto]` | Scan inbox for cashu tokens, redeem them |
| `p2pk-send.sh <did> <amount> [memo]` | Send P2PK-locked tokens (only recipient DID can redeem) |
| `p2pk-receive.sh <token>` | Redeem P2PK-locked tokens with DID private key |

## Usage

```bash
# Check balance
./balance.sh

# Mint 100 sats (pays Lightning invoice from LNbits)
./mint.sh 100

# Send 50 sats to a DID via encrypted dmail
./send.sh did:cid:bagaaiera... 50 "Payment for services"

# Check inbox and redeem any received tokens
./receive.sh

# Send P2PK-locked tokens (only the DID holder can redeem)
./p2pk-send.sh did:cid:bagaaiera... 25 "Locked payment"
```

## How It Works

1. **Send**: Creates a cashu token → wraps it in an encrypted dmail → delivers via Archon hyperswarm
2. **Receive**: Scans dmail inbox for `cashuA.../cashuB...` tokens → swaps with mint → credits balance
3. **P2PK**: Locks tokens to the recipient's DID secp256k1 public key — even if intercepted, only the DID holder can redeem

## Configuration

Edit `~/.config/archon/cashu.env`:

```bash
CASHU_BIN="cashu"                              # Path to nutshell CLI
CASHU_MINT_URL="https://your-mint.com/cashu"   # Default mint
LNBITS_ENV="~/.config/lnbits.env"              # LNbits credentials (optional)
ARCHON_CONFIG_DIR="~/.config/archon"           # Archon keymaster config
ARCHON_WALLET_PATH="~/.config/archon/wallet.json"
ARCHON_PASSPHRASE=""                           # Wallet passphrase
```

Override config location: `export ARCHON_CASHU_CONFIG=/path/to/config.env`

## Security

- Tokens are **end-to-end encrypted** via DID keys in dmail
- P2PK tokens add a second layer: only the DID's secp256k1 key can sign for redemption
- Config file is created with `chmod 600` (owner-only read/write)
- **Receive tokens promptly** — unswapped bearer tokens can be double-spent by the sender
- Back up both `~/.cashu/` (cashu proofs) and your Archon wallet together
