---
name: archon-keymaster
description: Complete Archon DID toolkit - identity management, encrypted messaging (dmail), Nostr integration, file encryption/signing, aliasing, and vault backups. Use for any Archon/DID operations including creating identities, sending encrypted messages between DIDs, deriving Nostr keypairs from DID, encrypting/signing files, managing DID aliases, or backing up to distributed vaults.
---

# Archon Keymaster - Complete DID Toolkit

Comprehensive toolkit for Archon decentralized identities (DIDs). Manages identity lifecycle, encrypted communication, cryptographic operations, and secure backups.

## Capabilities

- **Identity Management** - Create, manage multiple DIDs, recover from mnemonic
- **Encrypted Messaging (Dmail)** - Send/receive end-to-end encrypted messages between DIDs
- **Nostr Integration** - Derive Nostr keypairs from your DID (same secp256k1 key)
- **File Encryption** - Encrypt files for specific DIDs
- **Digital Signatures** - Sign and verify files with your DID
- **DID Aliasing** - Friendly names for DIDs (contacts, schemas, vaults)
- **Vault Backups** - Encrypted, distributed backups of workspace/config/memory

## Prerequisites

- Node.js installed (for `npx @didcid/keymaster`)
- Environment: `~/.archon.env` with `ARCHON_PASSPHRASE` (created by setup)
- Wallet: `~/clawd/wallet.json` (created by setup)

## Quick Start

### First-Time Setup

```bash
./scripts/identity/create-id.sh
```

Creates your first DID, generates passphrase, saves to `~/.archon.env`. **Write down your 12-word mnemonic** - it's your master recovery key.

### Load Environment

All scripts require environment variables:

```bash
source ~/.archon.env
export ARCHON_WALLET_PATH="${ARCHON_WALLET_PATH:-$HOME/clawd/wallet.json}"
```

## Identity Management

### Create Additional Identity

```bash
./scripts/identity/create-additional-id.sh <name>
```

Create pseudonymous personas or role-separated identities (all share same mnemonic).

### List All DIDs

```bash
./scripts/identity/list-ids.sh
```

### Switch Active Identity

```bash
./scripts/identity/switch-id.sh <name>
```

### Recovery

**Complete disaster recovery:**
```bash
./scripts/backup/disaster-recovery.sh "word1 word2 ... word12" [target-dir]
```

Recovers everything from just your 12-word mnemonic.

**Restore from existing wallet:**
```bash
./scripts/backup/restore-from-vault.sh [target-dir]
```

If you already have your wallet, use this to restore workspace/config/memory from vault backups.

## Encrypted Messaging (Dmail)

End-to-end encrypted messages between DIDs with attachment support.

### Send Message

```bash
./scripts/messaging/send.sh <recipient-did-or-alias> <subject> <body> [cc-did...]
```

Examples:
```bash
./scripts/messaging/send.sh alice "Meeting" "Let's sync tomorrow"
./scripts/messaging/send.sh did:cid:bag... "Update" "Status report" did:cid:bob...
```

### Check Inbox

```bash
./scripts/messaging/refresh.sh   # Poll for new messages
./scripts/messaging/list.sh      # List inbox
./scripts/messaging/list.sh unread  # Filter unread
```

### Read Message

```bash
./scripts/messaging/read.sh <dmail-did>
```

### Reply/Forward/Archive

```bash
./scripts/messaging/reply.sh <dmail-did> <body>
./scripts/messaging/forward.sh <dmail-did> <recipient-did> [body]
./scripts/messaging/archive.sh <dmail-did>
./scripts/messaging/delete.sh <dmail-did>
```

### Attachments

```bash
./scripts/messaging/attach.sh <dmail-did> <file-path>
./scripts/messaging/get-attachment.sh <dmail-did> <attachment-name> <output-path>
```

## Nostr Integration

Derive Nostr identity from your DID - same secp256k1 key, two protocols.

### Prerequisites

Install `nak` CLI:
```bash
curl -sSL https://raw.githubusercontent.com/fiatjaf/nak/master/install.sh | sh
```

### Derive Nostr Keys

```bash
./scripts/nostr/derive-nostr.sh
```

Outputs `nsec`, `npub`, and hex pubkey (derived from `m/44'/0'/0'/0/0`).

### Save Keys

```bash
mkdir -p ~/.clawstr
echo "nsec1..." > ~/.clawstr/secret.key
chmod 600 ~/.clawstr/secret.key
```

### Publish Nostr Profile

```bash
echo '{
  "kind": 0,
  "content": "{\"name\":\"YourName\",\"about\":\"Your bio. DID: did:cid:...\"}"
}' | nak event --sec $(cat ~/.clawstr/secret.key) \
  wss://relay.ditto.pub wss://relay.primal.net wss://relay.damus.io wss://nos.lol
```

### Update DID with Nostr Identity

```bash
npx @didcid/keymaster set-property YourIdName nostr \
  '{"npub":"npub1...","pubkey":"<hex-pubkey>"}'
```

## File Encryption & Signatures

### Encrypt Files

```bash
./scripts/crypto/encrypt-file.sh <input-file> <recipient-did-or-alias>
./scripts/crypto/encrypt-message.sh <message> <recipient-did-or-alias>
```

Returns encrypted DID (stored on-chain/IPFS). Only recipient can decrypt.

### Decrypt Files

```bash
./scripts/crypto/decrypt-file.sh <encrypted-did> <output-file>
./scripts/crypto/decrypt-message.sh <encrypted-did>
```

### Sign Files (Proof of Authorship)

```bash
./scripts/crypto/sign-file.sh <file.json>
```

**Important:** File must be JSON. Adds `proof` section with signature.

### Verify Signatures

```bash
./scripts/crypto/verify-file.sh <file.json>
```

Shows who signed it, when, and whether content was tampered with.

## DID Aliasing

Friendly names for DIDs - use "alice" instead of `did:cid:bagaaiera...`

### Add Alias

```bash
./scripts/aliases/add-alias.sh <alias> <did>
```

Examples:
```bash
./scripts/aliases/add-alias.sh alice did:cid:bagaaiera...
./scripts/aliases/add-alias.sh proof-of-human-schema did:cid:bagaaiera4yl4xi...
./scripts/aliases/add-alias.sh backup-vault did:cid:bagaaierab...
```

### Resolve Alias

```bash
./scripts/aliases/resolve-did.sh <alias-or-did>
```

Pass-through safe (returns DID unchanged if you pass a DID).

### List/Remove Aliases

```bash
./scripts/aliases/list-aliases.sh
./scripts/aliases/remove-alias.sh <alias>
```

**Note:** Aliases work in most Keymaster commands and all encryption/messaging scripts.

## Vault Backups

Encrypted, distributed backups to your DID vault.

### Setup

1. Create backup vault:
   ```bash
   npx @didcid/keymaster create-vault --name backup
   ```

2. Configure exclusions:
   ```bash
   cp references/backup-templates/workspace.backup-ignore ~/clawd/.backup-ignore
   cp references/backup-templates/config.backup-ignore ~/.openclaw/.backup-ignore
   ```

3. Test backup:
   ```bash
   ./scripts/backup/backup-to-vault.sh
   ```

### Manual Backup

```bash
./scripts/backup/backup-to-vault.sh
```

Backs up:
- Workspace (`~/clawd`) → `workspace.zip`
- Config (`~/.openclaw`) → `config.zip`
- Memory database (`hexmem.db`)

### Verify Backup

```bash
npx @didcid/keymaster list-vault-items backup
./scripts/backup/verify-backup.sh  # Full integrity check
```

### Restore from Backup

**Automated restore (recommended):**
```bash
./scripts/backup/restore-from-vault.sh [target-dir]
```

Retrieves and extracts all backup items (workspace.zip, config.zip, hexmem.db) from your vault.

**Manual restore:**
```bash
npx @didcid/keymaster get-vault-item backup workspace.zip workspace.zip
npx @didcid/keymaster get-vault-item backup config.zip config.zip
npx @didcid/keymaster get-vault-item backup hexmem.db hexmem.db

unzip workspace.zip
unzip config.zip -d ~/.openclaw
```

### Complete Disaster Recovery

If you've lost everything but have your 12-word mnemonic:

```bash
./scripts/backup/disaster-recovery.sh "word1 word2 ... word12" [target-dir]
```

This single command:
1. Creates wallet from mnemonic
2. Recovers wallet data (identities, aliases) from seed bank
3. Restores workspace, config, and memory from vault

Requires `ARCHON_PASSPHRASE` to be set.

### Gatekeeper Options

**Public gatekeeper** (default): `https://archon.technology`
- No setup required
- 10MB file size limit

**Local node** (for large backups):
```bash
# Run local Archon node, then update ~/.archon.env:
export ARCHON_GATEKEEPER_URL="http://localhost:4224"
```

## Advanced Usage

### Multiple Identities (Pseudonymous Personas)

```bash
./scripts/identity/create-additional-id.sh pseudonym
./scripts/identity/create-additional-id.sh work-persona
./scripts/identity/switch-id.sh pseudonym
```

Use cases:
- Separate personal/work identities
- Anonymous participation
- Role-based access control

### Dmail Message Format

Dmails are JSON:
```json
{
  "to": ["did:cid:recipient1", "did:cid:recipient2"],
  "cc": ["did:cid:cc-recipient"],
  "subject": "Subject line",
  "body": "Message body",
  "reference": "did:cid:original-message"
}
```

Direct Keymaster commands:
```bash
npx @didcid/keymaster create-dmail message.json
npx @didcid/keymaster send-dmail <dmail-did>
npx @didcid/keymaster file-dmail <dmail-did> "inbox,important"
```

### Signature Verification

Signed files include proof:
```json
{
  "data": {"your": "content"},
  "proof": {
    "type": "EcdsaSecp256k1Signature2019",
    "created": "2026-02-10T20:41:26.323Z",
    "verificationMethod": "did:cid:bagaaiera...#key-1",
    "proofValue": "wju2GCn0QweP4bH6..."
  }
}
```

## Security Notes

- **Mnemonic is master key** - Store offline, write down, never digital
- **Passphrase encrypts wallet** - Protects wallet.json on disk
- **Aliases are local** - Not shared, fully decentralized
- **Dmail is end-to-end encrypted** - Only sender/recipients can read
- **Signatures are non-repudiable** - Can't deny creating valid signature
- **Backups persist** - As long as any hyperswarm node retains them

## Troubleshooting

### Wallet/Passphrase Issues

**"Cannot read wallet":**
```bash
source ~/.archon.env
ls -la ~/clawd/wallet.json
```

**"Permission denied":**
```bash
chmod 600 ~/.archon.env
```

### Encryption/Signing

**"Cannot decrypt":**
- Ensure message was encrypted for YOUR DID
- Check passphrase is correct

**"Signature verification failed":**
- File modified after signing
- Signer's DID may be revoked

### Dmail

**"Messages not arriving":**
```bash
./scripts/messaging/refresh.sh  # Poll for new messages
```

**"Recipient can't decrypt":**
- Use correct recipient DID (not alias on their side)

### Backup

**"File too large" (>10MB on public gatekeeper):**
- Run local Archon node: `export ARCHON_GATEKEEPER_URL="http://localhost:4224"`
- OR exclude more files via `.backup-ignore`

**"Vault not found":**
```bash
npx @didcid/keymaster list-vaults
npx @didcid/keymaster create-vault --name backup
```

## References

- Archon documentation: https://github.com/archetech/archon
- Keymaster reference: https://github.com/archetech/archon/tree/main/keymaster
- W3C DID specification: https://www.w3.org/TR/did-core/
- Backup procedure: https://morningstar-daemon.github.io/archon/backup-procedure
