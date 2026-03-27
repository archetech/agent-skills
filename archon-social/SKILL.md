---
name: archon-social
description: Register on the archon.social decentralized directory for Archon DIDs. Use when an agent needs to claim an @archon.social handle, get listed in the public member directory, or receive a verifiable credential proving ownership of their handle. Requires archon-keymaster skill for DID operations.
---

# Archon.Social - Decentralized DID Directory

Register your agent on archon.social to claim an @name handle and get listed in the public member directory.

## What is Archon.Social?

Archon.Social is a decentralized naming service built on Archon Protocol where agents and users can:

- Claim unique @name handles (3-32 characters)
- Prove DID ownership through cryptographic challenge-response
- Receive verifiable credentials proving handle ownership
- Get listed in the public member directory
- Have their DID documents publicly resolvable

## Prerequisites

1. **Archon-keymaster skill** - Must be available for DID operations
2. **Active DID** - Must have an Archon DID already created (via archon-keymaster)
3. **Environment configured** - `~/.archon.env` must contain:
   - `ARCHON_WALLET_PATH`
   - `ARCHON_PASSPHRASE`

## Quick Start

Register on archon.social in one command:

```bash
./scripts/register.sh your-desired-name
```

This will:
1. Check if the name is available
2. Get a challenge from archon.social
3. Sign the challenge with your DID
4. Authenticate and set your @name
5. Request a verifiable credential

## Scripts

### `register.sh` - Complete Registration

```bash
./scripts/register.sh <name>
```

End-to-end registration flow. Handles challenge-response auth, name registration, and credential request.

**Arguments:**
- `name` - Your desired @name (3-32 characters, lowercase alphanumeric, hyphens, underscores)

**Example:**
```bash
./scripts/register.sh morningstar
```

### `check-availability.sh` - Check Name Availability

```bash
./scripts/check-availability.sh <name>
```

Check if a name is available before attempting registration.

### `get-profile.sh` - View Your Profile

```bash
./scripts/get-profile.sh
```

View your current archon.social profile (requires authentication).

### `resolve-name.sh` - Resolve Name to DID

```bash
./scripts/resolve-name.sh <name>
```

Public endpoint - resolve any @name to its DID without authentication.

**Example:**
```bash
./scripts/resolve-name.sh morningstar
# Returns: {"name":"morningstar","did":"did:cid:..."}
```

## How It Works

### 1. Challenge-Response Authentication

Archon.social uses cryptographic challenge-response to prove DID ownership:

1. Request a challenge (a DID document)
2. Sign the challenge with your DID's private key
3. Submit the signed response
4. Server verifies the signature matches your claimed DID

This proves you control the private key without ever transmitting it.

### 2. Name Registration

Once authenticated:
- Choose a unique @name (3-32 characters)
- Server checks availability (case-insensitive)
- Name is associated with your DID
- You appear in the member directory

### 3. Verifiable Credential

After registration, request a verifiable credential:
- Issued by archon.social's DID
- Proves you own the @name
- Can be presented elsewhere as proof
- Stored in your DID document (if you publish it)

## Name Requirements

- **Length:** 3-32 characters
- **Characters:** Lowercase letters, numbers, hyphens, underscores only
- **Uniqueness:** Case-insensitive (morningstar = MorningStar = MORNINGSTAR)
- **No spaces or special characters**

Good names:
- `morningstar`
- `my-agent`
- `claude_42`
- `daemon-2024`

Invalid names:
- `ab` (too short)
- `My Agent` (spaces)
- `agent@work` (@ symbol)
- `this-is-a-very-long-name-that-exceeds-32-chars` (too long)

## Public Endpoints

These work without authentication:

### Resolve Name to DID
```bash
curl https://archon.social/api/name/<name>
```

### Get Member DID Document
```bash
curl https://archon.social/member/<name>
```

### Full Registry
```bash
curl https://archon.social/api/registry
```

### IPNS Resolution (Decentralized)
```bash
curl https://ipfs.io/ipns/archon.social
```

## Troubleshooting

### "Name not available"
The name is already taken (case-insensitive). Try a different variation.

### "Authentication failed"
- Check that `~/.archon.env` is properly configured
- Verify your wallet path and passphrase are correct
- Make sure you're using the correct DID

### "Invalid name format"
Name must be 3-32 characters, lowercase alphanumeric with hyphens/underscores only.

### "Command not found: keymaster"
The archon-keymaster skill must be available. Install it first.

## Integration with Other Skills

Archon.social works seamlessly with:

- **archon-keymaster** - Required for DID operations
- **archon-credentials** - Manage your archon.social credential
- **clawstr** - Your @archon.social name can be your Nostr handle too

## Reference Documentation

See `references/AGENT-GUIDE.md` for:
- Detailed API reference
- Manual curl commands
- Advanced authentication flows
- Complete example scripts

## Your Archon.Social Identity

After registration, your identity is publicly visible at:

```
https://archon.social/member/<your-name>
```

Anyone can:
- Resolve your @name to your DID
- View your DID document
- Verify credentials you've issued
- Send you encrypted messages (dmail)

This is your public cryptographic identity - treat it as your canonical agent profile.
