---
title: "age: the honest review"
description: "age is a one-binary file-encryption tool that proves the bytes weren't tampered with — and refuses to say who sent them. That gap is the review."
date: 2026-09-04
categories: [Tools]
tags: [files, system]
author: cass
verdict: "Use it for encrypting files at rest — it's the least foot-gunny crypto CLI I've tested — but it encrypts, it does not SIGN: a clean decrypt proves the bytes are intact, never who produced them. If you need to know the file came from a specific person, bolt a signature on top."
excerpt: "A single Go binary that does authenticated public-key file encryption with no keyring and almost no options to get wrong. Genuinely good. Also: it proves integrity, never authorship, and the secret key sits in cleartext behind one chmod. Verdict: keep it, sign on top, guard the identity."
preview: /images/previews/age-the-honest-review.svg
permalink: /tools/age-encryption-honest-review/
---
**Verdict: install it — `apt install age` — and use it for encrypting files at rest, backups, secrets you're about to park in a bucket. age is the least foot-gunny crypto CLI I have ever threat-modeled: one static binary, no keyring daemon, no `--cipher` menu to pick a broken option from, no 900-line config. It does authenticated encryption correctly and it makes the correct thing the easy thing. It is also a tool whose single most important property is one it never mentions: age encrypts, it does not _sign_. A file that decrypts cleanly proves the bytes were not touched. It does not prove who produced them. Those are different guarantees, people conflate them constantly, and age hands you exactly one of the two with a straight face.** That is not a knock. That is the threat model, and it's the part the README treats as obvious.

age (`filippo.io/age`, "Actually Good Encryption") is what you reach for when the honest alternative was going to be a `gpg` incantation you copied off a 2011 Stack Overflow answer and never understood. I have no relationship with the project — it's free, BSD-licensed, open source, written by Filippo Valsorda, and nobody paid me. I don't trust free things on principle, which is exactly why I spent an afternoon trying to break this one. It mostly refused. Here's where it holds, and the one place the trust boundary is not where you think it is.

## The convenience: encryption with almost nothing to get wrong

Here is what earns the install. You make a keypair, you encrypt to the public half, you decrypt with the private half. Real captured output, `age` 1.1.1 on Ubuntu:

```console
$ age-keygen -o key.txt
Public key: age1dcnw4t78ute6nytsm3t974drdq89zrreuprahwnspw68y9v0nuhq50geqk
$ echo "launch codes: hunter2" > secret.txt
$ age -r age1dcnw4t78ute6nytsm3t974drdq89zrreuprahwnspw68y9v0nuhq50geqk -o secret.age secret.txt
$ age -d -i key.txt secret.age
launch codes: hunter2
```

That's the whole tool. `-r` is a recipient (a public key), `-i` is an identity (your private key file), `-d` decrypts. It streams, so `tar czf - ~/data | age -r age1... > data.tar.gz.age` just works — I ran the piped version, it round-trips. It armors to ASCII with `-a` when you need to paste it into something that eats binary. And it will encrypt straight to an SSH public key, which means you can encrypt a file to a colleague using the `ed25519` key they already published on GitHub:

```console
$ age -R id_test.pub -o ssh.age secret.txt
$ age -d -i id_test ssh.age
launch codes: hunter2
```

No keyring to import, no web of trust to curate, no `gpg --recv-keys` reaching out to a keyserver that's been down since the last time you needed it. There is genuinely very little surface here to configure into a hole. If the review ended here it would be a rave. It doesn't, because "very little surface" is not "no surface," and the surface that's left is load-bearing.

## Attack surface #1: age proves the bytes are intact — never who sent them

This is the one. Everything else is hygiene; this is the trust boundary people put in the wrong place.

age uses authenticated encryption, so tampering is caught. I flipped a single byte at the end of a valid ciphertext and tried to decrypt it — real captured output:

```console
$ age -d -i key.txt s.tampered
age: error: failed to decrypt and authenticate payload chunk
```

Exit 1, refused, correct. So the file you decrypt is bit-for-bit the file that was encrypted. That is a real, strong guarantee, and it is the guarantee people _think_ means "this came from Alice." It does not. Watch what age does and does not stop.

Encryption to a public key is a public operation. **Anyone who has your public key can produce a valid ciphertext to you** — that's the entire point of public-key crypto — and age has no mechanism, none, to record who did the encrypting. There is no `--sign` flag. Grep the help and there is nothing:

```console
$ age --help | grep -iE 'sign|authenticat|sender'
$
```

Nothing comes back, because sender authentication is not a feature age has. The "authenticate" in "failed to decrypt and authenticate" is the AEAD tag authenticating the _ciphertext to itself_ — it proves the bytes weren't mangled in transit, not that a specific human produced them. So the attack is not exotic. **SEVERITY: your own assumptions. ATTACK VECTOR: anyone who knows your public key — which is public — mails you `invoice.age` that decrypts perfectly into new wiring instructions. BLAST RADIUS: you told your finance team "if it decrypts with our key, it's from us," and it decrypts, and it isn't.** age did its job flawlessly: it kept the file secret from everyone but you and proved nobody corrupted it. It never claimed to prove authorship, and you built a workflow that assumed it did.

Walk it back to what a normal person should actually do: for the overwhelmingly common case — you encrypting your own backups, your own secrets, files only you will ever decrypt — this doesn't matter at all, because you already know who the sender is. It's you. The moment a _second_ party is supposed to _trust that a file came from a specific first party_, you have crossed out of what age does, and you need a signature. That's mitigation #1 below, and it's four commands you already have installed.

## Attack surface #2: the secret key is cleartext on disk behind one chmod

`age-keygen` writes your identity to a file. Let's look at what's in it and what's guarding it:

```console
$ head -c 80 key.txt
# created: 2026-09-04T09:24:13Z
# public key: age1dcnw4t78ute6nytsm3t974drdq89zr
$ stat -c '%a' key.txt
600
```

Below those comment lines sits a line beginning `AGE-SECRET-KEY-1...` — the private key, in the clear. The only thing standing between it and any process running as you is the Unix permission bits: `600`, owner-only. `age-keygen` sets that correctly, credit where due. But there is no passphrase on the file itself unless you go out of your way to add one, and there is no forward secrecy: that one key decrypts _every file ever encrypted to its public half_. I encrypted an "old" secret and a "new" secret to the same recipient and one stolen `key.txt` opened both:

```console
$ age -d -i key.txt old.age
older secret
$ age -d -i key.txt new.age
newer secret
```

**SEVERITY: a stray backup. ATTACK VECTOR: `key.txt` swept into a dotfiles repo, a synced Documents folder, a `tar` of your home directory, or a laptop that left the building. BLAST RADIUS: not one file — every file anyone ever sent to you, retroactively, silently, forever.** There's no revocation and no expiry; the key is valid until you stop using it and re-encrypt everything to a new one. Walk it back: `600` and a disk that doesn't leave your possession is genuinely fine for most people. But an identity file is a skeleton key, and it's sitting in plaintext. Treat it like the skeleton key it is — mitigation #2.

## Attack surface #3: passphrase mode refuses to be scripted (and that's mostly good)

age has a symmetric mode: `-p` encrypts to a passphrase instead of a key. Handy, until you try to automate it. Real captured output, in a non-interactive shell:

```console
$ echo hello | age -p -o p.age p.txt
age: error: could not read passphrase: standard input is not a terminal, and /dev/tty is not available: open /dev/tty: no such device or address
```

age _insists_ on reading the passphrase from a real terminal (`/dev/tty`) and flatly refuses a pipe or a heredoc. In a paranoid mood I want to call this a bug; in an honest one it's a defense. Feeding a passphrase in on a pipe means it lands in your shell history, your CI logs, a `ps` listing, and an environment variable three processes can read. By demanding a TTY, age makes it _annoying_ to do the insecure thing, which is the correct direction for the annoyance to point. **SEVERITY: a leaked CI log. ATTACK VECTOR: `echo "$SECRET" | age -p` in a pipeline, passphrase now printed in the build output forever. BLAST RADIUS: the one convenience feature you were reaching for is the one that leaks the key material — so age took it away.** The footgun here is real but it's the _absence_ of a footgun: if you find yourself fighting `-p` in a script, that's the tool telling you to switch to key files (which are meant to be automated) rather than piping a passphrase around. Don't fight it. Don't `expect(1)` your way past it either.

One quiet nicety while we're in the internals: an age ciphertext does not name its recipients. The header carries an ephemeral key share, not your public key, so a captured `.age` file doesn't advertise who it's for. That's a privacy win most tools don't bother with, and age gets it for free. Credit where it's due — it hurts to say, but say it.

## The three mitigations that actually matter

Paranoia without a payload is just anxiety. Here's what I configured and ran, ranked.

**1. If a second party must trust the sender, add a signature — age won't.** age gives you secrecy and integrity; it does not give you authorship. You already have a signer installed: OpenSSH. Sign the file with your SSH key, hand out an allowed-signers file, and now "came from me" is verifiable. Real captured output:

```console
$ ssh-keygen -Y sign -f id_test -n file artifact.txt
Signing file artifact.txt
Write signature to artifact.txt.sig
$ echo "me@example.com $(cat id_test.pub)" > allowed_signers
$ ssh-keygen -Y verify -f allowed_signers -I me@example.com -n file -s artifact.txt.sig < artifact.txt
Good "file" signature for me@example.com with ED25519 key SHA256:eUJ3lquaUNQcRjyJ+6uIg+jV1V2ft270aJoz6WjYcZA
```

Sign first, then age-encrypt both the file and its `.sig` together. And confirm the signature actually protects something — I appended one line to the signed file and re-verified:

```console
$ ssh-keygen -Y verify -f allowed_signers -I me@example.com -n file -s artifact.txt.sig < artifact.txt
Signature verification failed: incorrect signature
Could not verify signature.
```

Exit 255, rejected. Now "it decrypted" and "it's from me" are two separate, independently checkable facts — which is what you wrongly assumed age was giving you in the first place. (`minisign`, from the same author as age, does the same job if you'd rather not involve SSH keys.)

**2. Guard the identity file like the skeleton key it is.** It's a cleartext secret key whose blast radius is every file ever encrypted to it. Keep it `600`, keep it off anything that syncs, and confirm both before you walk away:

```console
$ stat -c '%a' key.txt
600
```

Better: encrypt the identity file _itself_ with a passphrase — `age -p -o key.age key.txt`, then decrypt it only at time of use and never leave the plaintext on disk — so a stolen copy is useless without the passphrase in your head. (That path needs a real terminal, per surface #3; it won't run in CI, which is the point.) The whole mitigation is: the file that decrypts everything should be the file you protect the most, and right now it's a plain-text line one `cp` away from a synced folder.

**3. Never gate a script on the passphrase path, and prefer key files for automation.** `-p` requires a TTY and will hang or fail in a pipeline; that's the tool refusing to let you leak a passphrase into a log. So automate with key-file recipients (`-r`/`-R`), which are designed for it, and keep `-p` for interactive, one-off, human-at-the-keyboard use. If a build step needs to decrypt, give it an identity file with tight permissions and a short life — not a passphrase piped in from an environment variable that three other processes can read.

## Should you use it

Yes. For encrypting files at rest, age is the one I recommend without a caveat about the crypto itself — the crypto is modern, the interface is small enough to hold in your head, and it makes the safe path the default path, which is the highest praise I give any security tool. The free alternative is `gpg`, which can also sign (age can't) and can also manage a keyring (age won't), and in exchange asks you to learn a subsystem with its own moon phases; for pure file encryption, age is the better tool and it isn't close. Just keep the one boundary straight: a clean decrypt is proof the bytes are intact, not proof of who sent them. age never claimed otherwise — that conflation is ours, not the tool's — so when a second party has to trust the sender, sign on top. The reader is the protagonist here. Encrypt freely; just don't let "it decrypted" quietly become your entire trust model for who's on the other end. Reality was reached for comment about the difference between "authenticated" and "authentic," and declined to elaborate.
