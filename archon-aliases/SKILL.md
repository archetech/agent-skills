# Archon Aliases - DID Aliasing and Resolution

Manage friendly aliases for DIDs. Use aliases instead of full DIDs for agents, schemas, vaults, and more.

## What This Skill Does

Provides a simple aliasing system for Archon DIDs:
- **Add aliases** - Assign friendly aliases to any DID
- **Resolve aliases** - Look up DIDs by alias
- **List aliases** - View all your DID aliases
- **Remove aliases** - Delete alias mappings

Aliases work everywhere - most Keymaster commands accept aliases OR DIDs.

## Prerequisites

- Archon identity set up (run [archon-id](../archon-id/) skill first)
- `~/.archon.env` configured

## Use Cases

**Agent/Person Contacts:**
```bash
./add-alias.sh alice did:cid:bagaaiera...
./add-alias.sh bob did:cid:bagaaierc...
./add-alias.sh cypher did:cid:bagaaierd...
```

**Schema DIDs:**
```bash
./add-alias.sh proof-of-human did:cid:bagaaiera4yl4xi...
./add-alias.sh proof-of-ai did:cid:bagaaieratedl6c...
./add-alias.sh certification-schema did:cid:bagaaierabc123...
```

**Vault DIDs:**
```bash
./add-alias.sh backup did:cid:bagaaierab...
./add-alias.sh shared-workspace did:cid:bagaaierac...
```

**Organization:**
- Use consistent naming patterns (e.g., `-schema` suffix for schemas)
- Group related DIDs with prefixes (e.g., `work-alice`, `work-bob`)
- Keep aliases descriptive but concise

## Usage

### Add an Alias

```bash
./add-alias.sh <alias> <did>
```

Example:
```bash
./add-alias.sh alice did:cid:bagaaiera123...
```

Once added, you can use "alice" anywhere that accepts a DID.

### Resolve an Alias to DID

```bash
./resolve-did.sh <alias-or-did>
```

Examples:
```bash
./resolve-did.sh alice
# Returns: did:cid:bagaaiera123...

./resolve-did.sh did:cid:bagaaiera123...
# Returns: did:cid:bagaaiera123... (pass-through)
```

**Note:** `resolve-did` accepts both aliases and DIDs. If you pass a DID, it returns the DID unchanged. This makes it safe to use in scripts without checking if input is an alias or DID.

### List All Aliases

```bash
./list-aliases.sh
```

Shows all alias → DID mappings in your wallet.

### Remove an Alias

```bash
./remove-alias.sh <alias>
```

Example:
```bash
./remove-alias.sh alice
```

Removes the alias mapping. The DID itself is not affected, just the alias.

## Integration with Other Skills

### Using Aliases in Keymaster Commands

Most Keymaster commands accept aliases OR DIDs:

```bash
# Issue credential to aliased contact
npx @didcid/keymaster issue-credential \
  --to alice \
  --schema proof-of-human \
  --claims '{"verified": true}'

# Add item to aliased vault
npx @didcid/keymaster add-vault-item backup file.txt

# Verify signature from aliased DID
npx @didcid/keymaster verify-signature \
  --did bob \
  --message "hello" \
  --signature <sig>
```

### Examples in Scripts

```bash
#!/bin/bash
# Send message to contact by alias

RECIPIENT="$1"
MESSAGE="$2"

# Resolve alias to DID (works with aliases or DIDs)
RECIPIENT_DID=$(./resolve-did.sh "$RECIPIENT")

# Use the DID
send-encrypted-message "$RECIPIENT_DID" "$MESSAGE"
```

## Alias Organization Patterns

**By Purpose:**
- Contacts: `alice`, `bob`, `cypher`
- Schemas: `proof-of-human-schema`, `certification-schema`
- Vaults: `backup-vault`, `shared-vault`

**By Context:**
- Work: `work-alice`, `work-shared-vault`
- Personal: `personal-bob`, `personal-backup`
- Public: `public-schema`, `public-profile`

**By Trust Level:**
- Verified: `verified-alice`, `verified-schema`
- Pending: `pending-bob`, `unverified-schema`

## Storage

Aliases are stored in your Archon wallet (`~/clawd/wallet.json`), encrypted with your passphrase. No separate files needed.

**Backup:** Aliases are automatically included when you backup your wallet (via archon-backup skill or seed bank).

## Security Notes

- Aliases are local to your wallet (other agents don't see your aliases)
- Removing an alias doesn't affect the underlying DID
- Aliases are included in wallet backups
- No centralized alias registry (fully decentralized)

## Troubleshooting

**"Alias not found":**
- Check spelling: `./list-aliases.sh`
- Ensure alias was added: `./add-alias.sh <alias> <did>`

**"Permission denied":**
- Ensure `.archon.env` is loaded: `source ~/.archon.env`
- Check passphrase is correct

**Alias conflicts:**
- Each alias must be unique in your wallet
- Removing old alias before adding new one: `./remove-alias.sh old-alias`

## References

- Keymaster documentation: https://github.com/archetech/archon/tree/main/keymaster
- DID specification: https://www.w3.org/TR/did-core/
