# Archon Secrets Vault

Store and retrieve sensitive files in encrypted Archon group vaults. Designed for shared access — multiple DIDs can decrypt the same vault for disaster recovery.

## Why

- Secrets should never live in git repos — even private ones
- Archon vaults encrypt data end-to-end with DID keys
- Group vaults let trusted parties (e.g., human + agent) both access secrets
- `--to-ram` mode loads secrets to tmpfs — nothing touches disk
- Backed by IPFS — distributed, resilient, no third-party access

## Scripts

| Script | Purpose |
|--------|---------|
| `store.sh` | Pack and encrypt secrets into a vault |
| `restore.sh` | Decrypt and restore secrets from a vault |
| `status.sh` | Check vault status, members, and contents |

## Quick Start

```bash
# Set up archon environment
export ARCHON_CONFIG_DIR="/path/to/your/archon/wallet"
source /path/to/archon.env

# Store secrets with a shared vault (add a trusted DID)
./store.sh --vault my-secrets --dir ~/.config/hex --member did:cid:trusted-partner-did

# Check vault status
./status.sh --vault my-secrets

# Restore to disk
./restore.sh --vault my-secrets --dir ~/.config/hex

# Restore to RAM only (nothing on disk, wiped on reboot)
./restore.sh --vault my-secrets --to-ram

# Dry run
./restore.sh --vault my-secrets --dry-run

# Restore as a vault member (shared vault, use DID directly)
./restore.sh --did did:cid:vault-did-here --dir ~/.config/hex
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `SECRETS_VAULT_NAME` | `secrets` | Vault name/alias |
| `SECRETS_VAULT_DID` | *(from alias)* | Vault DID (for shared vaults) |
| `SECRETS_DIR` | `~/.config` | Directory to store/restore |
| `SECRETS_PATTERN` | `*.env` | Glob pattern for files to include |
| `ARCHON_CONFIG_DIR` | *(required)* | Path to your Archon wallet directory |

## Security Model

- Files are packed into a tarball, encrypted with vault keys, stored on IPFS
- Only the vault owner and added members can decrypt
- `--to-ram` writes to `/dev/shm` (tmpfs) — wiped on reboot, never touches disk
- Restored files get `chmod 600` automatically
- Temp files cleaned up on exit (even on error)

## Group Vault (Recommended)

For disaster recovery, create a shared vault with your trusted partner:

```bash
# Owner creates vault with a member
./store.sh --vault shared-secrets \
  --dir ~/.config/hex \
  --member did:cid:partner-did

# Partner restores from the shared vault
./restore.sh --did did:cid:vault-did --dir ~/.config/hex --to-ram
```

Both parties can decrypt. If one loses access, the other can recover.

## Systemd Integration

To auto-load secrets from vault on boot:

```ini
[Unit]
Description=Load secrets from Archon vault to RAM
After=archon.service

[Service]
Type=oneshot
Environment=ARCHON_CONFIG_DIR=/path/to/wallet
ExecStart=/path/to/restore.sh --vault my-secrets --to-ram
RemainAfterExit=yes

[Install]
WantedBy=default.target
```
