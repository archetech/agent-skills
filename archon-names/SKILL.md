# Archon Names - DID Naming and Resolution

Manage friendly names for DIDs. Use names instead of full DIDs for agents, schemas, vaults, and more.

## What This Skill Does

Provides a simple naming system for Archon DIDs:
- **Add names** - Assign friendly names to any DID
- **Resolve names** - Look up DIDs by name
- **List names** - View all your named DIDs
- **Remove names** - Delete name mappings

Names work everywhere - most Keymaster commands accept names OR DIDs.

## Prerequisites

- Archon identity set up (run [archon-id](../archon-id/) skill first)
- `~/.archon.env` configured

## Use Cases

**Agent/Person Contacts:**
```bash
./add-name.sh alice did:cid:bagaaiera...
./add-name.sh bob did:cid:bagaaierc...
./add-name.sh cypher did:cid:bagaaierd...
```

**Schema DIDs:**
```bash
./add-name.sh proof-of-human did:cid:bagaaiera4yl4xi...
./add-name.sh proof-of-ai did:cid:bagaaieratedl6c...
./add-name.sh certification-schema did:cid:bagaaierabc123...
```

**Vault DIDs:**
```bash
./add-name.sh backup did:cid:bagaaierab...
./add-name.sh shared-workspace did:cid:bagaaierac...
```

**Organization:**
- Use consistent naming patterns (e.g., `-schema` suffix for schemas)
- Group related DIDs with prefixes (e.g., `work-alice`, `work-bob`)
- Keep names descriptive but concise

## Usage

### Add a Name

```bash
./add-name.sh <name> <did>
```

Example:
```bash
./add-name.sh alice did:cid:bagaaiera123...
```

Once added, you can use "alice" anywhere that accepts a DID.

### Resolve a Name to DID

```bash
./resolve-did.sh <name-or-did>
```

Examples:
```bash
./resolve-did.sh alice
# Returns: did:cid:bagaaiera123...

./resolve-did.sh did:cid:bagaaiera123...
# Returns: did:cid:bagaaiera123... (pass-through)
```

**Note:** `resolve-did` accepts both names and DIDs. If you pass a DID, it returns the DID unchanged. This makes it safe to use in scripts without checking if input is a name or DID.

### List All Names

```bash
./list-names.sh
```

Shows all name → DID mappings in your wallet.

### Remove a Name

```bash
./remove-name.sh <name>
```

Example:
```bash
./remove-name.sh alice
```

Removes the name mapping. The DID itself is not affected, just the name.

## Integration with Other Skills

### Using Names in Keymaster Commands

Most Keymaster commands accept names OR DIDs:

```bash
# Issue credential to named contact
npx @didcid/keymaster issue-credential \
  --to alice \
  --schema proof-of-human \
  --claims '{"verified": true}'

# Add item to named vault
npx @didcid/keymaster add-vault-item backup file.txt

# Verify signature from named DID
npx @didcid/keymaster verify-signature \
  --did bob \
  --message "hello" \
  --signature <sig>
```

### Examples in Scripts

```bash
#!/bin/bash
# Send message to contact by name

RECIPIENT="$1"
MESSAGE="$2"

# Resolve name to DID (works with names or DIDs)
RECIPIENT_DID=$(./resolve-did.sh "$RECIPIENT")

# Use the DID
send-encrypted-message "$RECIPIENT_DID" "$MESSAGE"
```

## Name Organization Patterns

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

Names are stored in your Archon wallet (`~/clawd/wallet.json`), encrypted with your passphrase. No separate files needed.

**Backup:** Names are automatically included when you backup your wallet (via archon-backup skill or seed bank).

## Security Notes

- Names are local to your wallet (other agents don't see your naming)
- Removing a name doesn't affect the underlying DID
- Names are included in wallet backups
- No centralized name registry (fully decentralized)

## Troubleshooting

**"Name not found":**
- Check spelling: `./list-names.sh`
- Ensure name was added: `./add-name.sh <name> <did>`

**"Permission denied":**
- Ensure `.archon.env` is loaded: `source ~/.archon.env`
- Check passphrase is correct

**Naming conflicts:**
- Each name must be unique in your wallet
- Removing old name before adding new one: `./remove-name.sh old-name`

## References

- Keymaster documentation: https://github.com/archetech/archon/tree/main/keymaster
- DID specification: https://www.w3.org/TR/did-core/
