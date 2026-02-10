# Archon Crypto - Encryption and Digital Signatures

Encrypt files and messages for other DIDs. Sign and verify files using your DID.

## What This Skill Does

Provides cryptographic operations using Archon DIDs:
- **Encrypt** - Secure files and messages for specific DIDs (only they can decrypt)
- **Decrypt** - Open encrypted content sent to you
- **Sign** - Prove you created/approved a file
- **Verify** - Check who signed a file and that it hasn't been tampered with

## Prerequisites

- Archon identity set up ([archon-id](../archon-id/) skill)
- `~/.archon.env` configured
- Recipient's DID for encryption operations

## Use Cases

**Secure Communication:**
```bash
# Encrypt message for alice
./encrypt-message.sh "Secret info" alice
# Alice decrypts it
./decrypt-message.sh did:cid:bagaaiera...
```

**File Encryption:**
```bash
# Encrypt sensitive file for bob
./encrypt-file.sh confidential.pdf bob encrypted.json
# Bob decrypts it
./decrypt-file.sh encrypted.json confidential.pdf
```

**Document Signing:**
```bash
# Sign a document (modifies in place)
./sign-file.sh contract.json
# Others verify your signature
./verify-file.sh contract.json
```

**Code/Release Signing:**
```bash
# Sign manifest of repository/release (modifies in place)
./sign-file.sh manifest.json
# Users verify it came from you
./verify-file.sh manifest.json
```

## Encryption

### Encrypt a Message

```bash
./encrypt-message.sh <message> <recipient-name-or-did>
```

Example:
```bash
./encrypt-message.sh "Meet at the usual place" alice
```

Output: Encrypted DID (starts with `did:cid:`) that only alice can decrypt.

### Encrypt a File

```bash
./encrypt-file.sh <input-file> <recipient-name-or-did>
```

Examples:
```bash
./encrypt-file.sh secret.pdf alice
./encrypt-file.sh document.txt bob
```

**Output:** An encrypted DID (like `did:cid:bagaaiera...`). The encrypted content is stored on-chain/IPFS and referenced by this DID. Only the recipient can decrypt it.

## Decryption

### Decrypt a Message

```bash
./decrypt-message.sh <encrypted-did>
```

Example:
```bash
./decrypt-message.sh did:cid:bagaaiera...
```

Output: Original plaintext message (if encrypted for you).

### Decrypt a File

```bash
./decrypt-file.sh <encrypted-did> <output-file>
```

Example:
```bash
./decrypt-file.sh did:cid:bagaaiera... decrypted.pdf
```

**Output:** Original file restored from on-chain/IPFS storage (if encrypted for you).

## Digital Signatures

### Sign a File

```bash
./sign-file.sh <file>
```

Example:
```bash
./sign-file.sh manifest.json
```

**Important:** File must be JSON. The signature (proof) is added directly to the JSON file.

**What gets signed:**
- File content hash
- Your DID (as issuer)
- Timestamp
- Signature using your private key

**Output:** The JSON file is modified in-place with a `proof` section:
```json
{
  "content": "...",
  "proof": {
    "type": "EcdsaSecp256k1Signature2019",
    "created": "2026-02-10T19:30:00Z",
    "verificationMethod": "did:cid:bagaaiera...#key-1",
    "proofValue": "..."
  }
}
```

### Verify a Signature

```bash
./verify-file.sh <file>
```

Example:
```bash
./verify-file.sh manifest.json
```

**Output:**
- ✓ Valid - Shows who signed it and when
- ✗ Invalid - Signature doesn't match or file was tampered with

**Verification checks:**
- Signature is valid for the content
- Issuer DID exists and is active
- Content hasn't been modified since signing

## Security Notes

**Encryption:**
- Only the recipient's DID can decrypt
- Messages are encrypted end-to-end
- Sender authentication is implicit (only someone with access to encryption can create valid ciphertext)
- Encryption uses recipient's public key from their DID document

**Signatures:**
- Proves file came from the signer's DID
- Detects any tampering (even one byte changed breaks signature)
- Non-repudiation - signer can't deny creating signature
- Timestamp shows when signing occurred
- Signature uses your private key (never leaves your wallet)

**Best Practices:**
- Always verify signatures on files from untrusted sources
- Keep your passphrase secure (it protects your signing key)
- For critical documents, verify the signer's DID is who you expect
- Sign files before sharing to prove authenticity

## Integration with Other Skills

**archon-names:**
Use friendly names instead of full DIDs:
```bash
./encrypt-message.sh "Secret" alice    # Uses name
./encrypt-file.sh doc.pdf bob          # Uses name
```

**archon-credentials:**
Credentials are signed JSON - use verify-file to check them:
```bash
./verify-file.sh credential.json
```

**Code signing:**
Sign release manifests, skill packages, or any JSON configuration:
```bash
./sign-file.sh package.json
./sign-file.sh skill-manifest.json
```

## How Encryption Works

**Encrypted content returns a DID:**
When you encrypt a file or message, Keymaster:
1. Encrypts the content with the recipient's public key
2. Stores the encrypted data on-chain/IPFS
3. Returns a DID that references this encrypted data

**Example:**
```bash
./encrypt-file.sh secret.pdf alice
# Returns: did:cid:bagaaierawxxpo4tuo4ephexi2a2zbvj...
```

The recipient uses this DID to decrypt:
```bash
./decrypt-file.sh did:cid:bagaaierawxxpo4... decrypted.pdf
```

**Signed files:**
Signing adds a `proof` section to your JSON:
```json
{
  "data": { "your": "content" },
  "proof": {
    "type": "EcdsaSecp256k1Signature2019",
    "created": "2026-02-10T20:41:26.323Z",
    "verificationMethod": "did:cid:bagaaiera...#key-1",
    "proofPurpose": "assertionMethod",
    "proofValue": "wju2GCn0QweP4bH6..."
  }
}
```

## Troubleshooting

**"Cannot decrypt" error:**
- Ensure message was encrypted for YOUR DID
- Check passphrase is correct
- Verify your DID has access to the decryption key

**"Signature verification failed":**
- File may have been modified after signing
- Signer's DID may be revoked
- File format may be invalid

**"Not a JSON file":**
- sign-file only works with JSON files
- Convert non-JSON files to JSON first, or use a wrapper format

**Name not found:**
- Add recipient to names: `archon-names/add-name.sh alice did:cid:...`
- Or use full DID instead of name

## References

- Keymaster documentation: https://github.com/archetech/archon/tree/main/keymaster
- W3C DID specification: https://www.w3.org/TR/did-core/
- Linked Data Signatures: https://w3c-ccg.github.io/ld-proofs/
