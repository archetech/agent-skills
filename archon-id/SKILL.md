# Archon Identity Management Skill

Complete identity lifecycle management for Archon DIDs: create, manage multiple identities, and recover.

## What This Skill Does

Manages your Archon decentralized identities (DIDs):
- **Initial setup** - Create your first DID and secure environment
- **Multi-DID** - Manage multiple identities (pseudonymous personas, role separation)
- **Recovery** - Restore identities from mnemonic or seed bank

## Prerequisites

- Node.js installed (for `npx @didcid/keymaster`)
- Internet connection (uses public Archon gatekeeper at `https://archon.technology`)

**Optional:** Run local Archon node for offline operations or custom configuration

## Initial Setup

### Create Your First Identity

Run the setup script:

```bash
./scripts/create-id.sh
```

This will:
1. Generate a new Archon DID via Keymaster
2. Create a secure passphrase
3. Save passphrase to `~/.archon.env`
4. Display your DID and mnemonic
5. Prompt you to save mnemonic securely (offline!)

**Important:** Your 12-word mnemonic is your master key. Write it down and store it offline. It's the only way to recover your identity if you lose everything else.

### What Gets Created

- `~/clawd/wallet.json` - Your DID wallet (encrypted)
- `~/.archon.env` - Contains `ARCHON_PASSPHRASE` (sourced by other Archon scripts)
- Mnemonic (12 words) - **Store this offline securely**

## Managing Multiple Identities

### Create Additional DID

```bash
./scripts/create-additional-id.sh <did-name>
```

Example:
```bash
./scripts/create-additional-id.sh pseudonym
./scripts/create-additional-id.sh work-persona
```

Creates a new DID in your existing wallet under the specified name.

### List All DIDs

```bash
./scripts/list-ids.sh
```

Shows all DIDs in your wallet with their names and IDs.

### Switch Active Identity

```bash
./scripts/switch-id.sh <did-name>
```

Switches which DID is used by default for operations. Updates environment to use the selected identity.

**Note:** Different DIDs in the same wallet share the same mnemonic but have separate identities on-chain.

## Recovery

### From Complete Loss (Have Mnemonic)

If you've lost your wallet and all files but have your mnemonic:

```bash
npx @didcid/keymaster import-wallet "word1 word2 word3 ... word12"
```

This recreates your wallet with all DIDs from the mnemonic.

### From Seed Bank (Wallet Lost, Mnemonic Known)

If your wallet is lost but you know your mnemonic:

```bash
# 1. Import wallet from mnemonic
npx @didcid/keymaster import-wallet "word1 word2 ... word12"

# 2. Recover wallet DID from seed bank
npx @didcid/keymaster recover-wallet-did
```

The seed bank is Archon's distributed backup service for wallet metadata.

### Verify Recovery

After recovery, recreate your `.archon.env`:

```bash
echo 'export ARCHON_PASSPHRASE="your-passphrase"' > ~/.archon.env
chmod 600 ~/.archon.env
```

Then verify with:
```bash
source ~/.archon.env
npx @didcid/keymaster list-dids
```

## Use Cases for Multiple DIDs

**Pseudonymous Personas:**
- Main identity for trusted contexts
- Anonymous persona for public forums
- Separate identity per community

**Role Separation:**
- Personal DID
- Work/professional DID
- Bot/automation DID

**Privacy:**
- Each DID has separate on-chain history
- No linkability between DIDs (unless you link them)
- Can selectively reveal identities

## Security Notes

- **Mnemonic is master key** - Anyone with it controls all your DIDs
- **Passphrase protects wallet** - Encrypts wallet.json on disk
- **`.archon.env` is sensitive** - Contains passphrase, keep it private (chmod 600)
- **Multiple DIDs share mnemonic** - Losing mnemonic = losing all identities
- **Backup wallet regularly** - Use archon-backup skill to backup to vault

## Integration with Other Skills

This skill is foundational. Other Archon skills assume you've run `create-id.sh`:

- **archon-backup** - Requires `.archon.env` and wallet.json
- **archon-nostr** - Derives Nostr identity from active DID
- **archon-verify** - Verifies signatures from DIDs
- Future skills (credentials, messaging, etc.)

## Troubleshooting

**"Keymaster command not found":**
- Ensure Node.js and npm/npx are installed
- Try: `npx @didcid/keymaster --version`

**"Cannot read wallet":**
- Ensure `ARCHON_PASSPHRASE` is set: `source ~/.archon.env`
- Check wallet exists: `ls -la ~/clawd/wallet.json`
- Verify passphrase is correct

**"Permission denied" on .archon.env:**
- Check permissions: `ls -la ~/.archon.env`
- Should be `-rw-------` (600)
- Fix with: `chmod 600 ~/.archon.env`

**Lost mnemonic:**
- **No recovery possible** - mnemonic is the master key
- This is by design (decentralized security)
- Prevention: backup mnemonic offline, use archon-backup skill

## References

- Archon documentation: https://github.com/archetech/archon
- Keymaster reference: https://github.com/archetech/archon/tree/main/keymaster
- DID specification: https://www.w3.org/TR/did-core/
