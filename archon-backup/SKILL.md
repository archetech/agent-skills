# Archon Backup Skill

Automate secure backups of your workspace, config, and memory to your Archon DID vault.

## What This Skill Does

Backs up your critical data to a distributed, encrypted Archon vault:
- **Workspace** - Your working directory (code, docs, research)
- **Config** - OpenClaw configuration and secrets
- **Memory** - Your hexmem database

Your backups are:
- **Distributed** - Stored in IPFS, replicated across hyperswarm nodes
- **Encrypted** - Only you (and vault members) can decrypt
- **Recoverable** - Restore everything from your 12-word mnemonic

## Prerequisites

1. **Archon DID** - Created via Keymaster
2. **Backup vault** - Created with `npx @didcid/keymaster create-vault --name backup`
3. **Environment variables**:
   ```bash
   export ARCHON_PASSPHRASE=your-passphrase
   export ARCHON_GATEKEEPER_URL=https://archon.technology  # or http://localhost:4224
   ```

### Gatekeeper Options

Skills default to the **public gatekeeper** (`https://archon.technology`):
- **Pros:** No local setup required, works immediately
- **Cons:** 10MB file size limit per item

For backups larger than 10MB, run a **local Archon node**:
1. Install Archon locally: https://github.com/archetech/archon
2. Update `~/.archon.env`:
   ```bash
   export ARCHON_GATEKEEPER_URL="http://localhost:4224"  # Unlimited size
   ```

## Setup

### 1. Create Backup Vault

```bash
npx @didcid/keymaster create-vault --name backup
```

### 2. Configure Exclusions

Copy the template `.backup-ignore` files to your workspace and config directories:

```bash
cp templates/workspace.backup-ignore ~/clawd/.backup-ignore
cp templates/config.backup-ignore ~/.openclaw/.backup-ignore
```

Edit as needed to exclude large/temporary files.

### 3. Test the Script

```bash
./scripts/backup-to-vault.sh
```

Verify the output shows all three items backed up successfully.

### 4. Automate (Optional)

Add to your `HEARTBEAT.md` for periodic backups:

```markdown
### Backup to DID vault
**Once daily** (check if last backup was >24h ago), run:
\`\`\`bash
~/clawd/scripts/backup-to-vault.sh
\`\`\`

### Verify backups
**Once monthly**, verify backup integrity:
\`\`\`bash
~/clawd/scripts/verify-backup.sh
\`\`\`
```

## Usage

### Manual Backup

```bash
cd ~/your-workspace
./scripts/backup-to-vault.sh
```

The script:
1. Creates zip archives (workspace.zip, config.zip) excluding patterns in `.backup-ignore`
2. Uploads archives + hexmem.db to your backup vault
3. Displays vault contents with sizes and timestamps

### Verify Backup

**Quick check (list items):**
```bash
npx @didcid/keymaster list-vault-items backup
```

**Full verification (test retrieval and integrity):**
```bash
./scripts/verify-backup.sh
```

This script:
- Retrieves each backup item from vault
- Tests file integrity (unzip for archives, SQLite check for database)
- Reports what's actually recoverable
- Leaves test files in `/tmp/backup-verify-*` for inspection

**Recommended frequency:** Monthly, or after any major backup system changes.

### Restore from Backup

**Using the restore script (recommended):**
```bash
./scripts/restore-from-vault.sh
```

This script:
- Lists available backups in your vault
- Downloads and extracts workspace.zip, config.zip, hexmem.db
- Places files in a timestamped restore directory
- Shows commands to move files to their final locations

**Manual restore:**
```bash
# Retrieve files
npx @didcid/keymaster get-vault-item backup workspace.zip workspace.zip
npx @didcid/keymaster get-vault-item backup config.zip config.zip
npx @didcid/keymaster get-vault-item backup hexmem.db hexmem.db

# Extract
unzip workspace.zip
unzip config.zip -d ~/.openclaw
```

### Complete Recovery (from mnemonic only)

If you've lost everything and only have your 12-word mnemonic:

```bash
./scripts/disaster-recovery.sh "word1 word2 ... word12" [target-dir]
```

This single command:
1. Creates wallet from mnemonic
2. Recovers wallet data (identities, aliases) from seed bank
3. Restores workspace, config, and memory from vault

The seed bank stores an encrypted copy of your wallet (including the backup vault alias), so you can recover everything from just the mnemonic.

**Manual steps (if preferred):**
```bash
npx @didcid/keymaster import-wallet "word1 word2 ... word12"
npx @didcid/keymaster recover-wallet-did
./scripts/restore-from-vault.sh
```

## Backup Contents

### Workspace (~/clawd)
- All files except: .git, node_modules, __pycache__, .venv, test directories, logs
- Includes: code, docs, scripts, memory files, research

### Config (~/.openclaw)
- All files except: sessions, cache, logs, browser data, media, canvas
- Includes: secrets, agent configs, channel configs

### Memory (hexmem.db)
- Your complete memory database (memory_log, events, facts, lessons)

## Security Notes

- Your vault is encrypted - only you can decrypt contents
- The 12-word mnemonic is your master key - store it securely offline
- Secrets in config backup are encrypted at rest in the vault
- Use `.backup-ignore` to prevent sensitive temp files from being included
- Backups persist as long as any hyperswarm node retains them

## Troubleshooting

**"File too large" error (>10MB on public gatekeeper):**
- Run local Archon node and set `ARCHON_GATEKEEPER_URL=http://localhost:4224`
- OR reduce backup size via more aggressive .backup-ignore patterns

**"Vault not found":**
- Verify vault exists: `npx @didcid/keymaster list-vaults`
- Create if missing: `npx @didcid/keymaster create-vault --name backup`

**Permission errors:**
- Ensure ARCHON_PASSPHRASE is set and correct
- Check wallet.json location (script uses ~/clawd/wallet.json by default)

## References

- Full procedure documentation: https://morningstar-daemon.github.io/archon/backup-procedure
- Archon documentation: https://github.com/archetech/archon
