---
title: "age: the encryption tool that won't pretend to know who sent the file"
description: "A threat-modeled review of age: the plaintext identity file, the ciphertext anyone with your public key can forge, the passphrase mode that needs a TTY, and three mitigations that matter."
date: 2026-09-08
categories: [Tools]
tags: [files, system]
author: cass
preview: /images/previews/age-the-encryption-tool-that-won-t-pretend-to-know.svg
verdict: "Use it — for encrypting a file to a key, which is all it claims to do. Do not mistake 'decrypted cleanly' for 'came from who you think it did.'"
excerpt: "I threat-modeled the friendly little encryption tool everyone recommends. The good news: age does exactly what it says. The bad news is everything you'll assume it also did — and the private key it leaves sitting on your disk in plaintext."
permalink: /tools/age-honest-review/
---
Picture the backup you emailed yourself. A single `.zip` of tax documents, sitting in your own inbox, "just in case." You have threat-modeled this, I'm sure, in the way most people threat-model it: not at all. So let me do it for you. That file has already been read by your mail provider, its ad-targeting subprocessor, the intern who built the spam classifier, and — the day the credential-stuffing bot finally guesses that 2019 password you reused — a stranger in a country you can't spell. SEVERITY: your own convenience. ATTACK VECTOR: the sentence "just in case." The fix a friendly blog post will hand you is "encrypt it first," and the tool that friendly blog post now recommends is `age`.

`age` is good. That is not sarcasm, and I don't say it often. It encrypts a file to a public key — or to a passphrase — with modern, opinionated, no-knobs cryptography, and it refuses to grow the eleven footguns that made everyone hate `gpg`. But "encrypt it first" is the load-bearing lie in that sentence, because encryption solves exactly one of the four problems you have, and `age` is honest enough — in its behavior, if not its marketing — to show you the other three if you actually run it. I did. Every command below ran on a fresh Ubuntu 24.04 box, `apt`-installed, no network after that.

**The verdict, up front:** use it, for the one thing it does. Encrypting a file to a recipient key is where `age` is genuinely the right answer — fast, tiny, and impossible to misconfigure into false confidence, because it barely has a configuration. What it does *not* do is manage your keys, prove who encrypted a file, or survive being wired into an unattended script the naive way. It's an encryption primitive wearing a friendly command name, and the danger isn't the tool. The danger is the list of things you'll assume it did.

There's an `apt` package, and unlike half the tools I review it isn't hiding under a renamed binary:

```console
$ age --version
1.1.1
```

## The happy path, which actually is happy

Two commands. Make a keypair, encrypt to the public half.

```console
$ age-keygen -o key.txt
Public key: age164a7du5mlwssxvx3rtsstjhspxehg0femceshsu3ra4swxn8zqkqlawek2

$ printf 'the launch codes are hunter2\n' > secret.txt
$ age -r age164a7du5mlwssxvx3rtsstjhspxehg0femceshsu3ra4swxn8zqkqlawek2 -o secret.age secret.txt

$ age -d -i key.txt secret.age
the launch codes are hunter2
```

That's the whole tool. The public key is a shareable string, the private key lives in `key.txt`, and anyone holding your public key can encrypt a file only you can open. No web of trust to configure, no cipher to choose badly, no `--yes-i-really-mean-it` incantations. For "send me something only I can read," this is the least dangerous tool in the category, and I am constitutionally incapable of higher praise.

Now let me spend the rest of the review on the part where you get hurt anyway.

## Finding 1 — your entire security is a plaintext string in a file (and one redirect away from world-readable)

Look at what `key.txt` actually is:

```console
$ cat key.txt
# created: 2026-09-08T09:28:42Z
# public key: age164a7du5mlwssxvx3rtsstjhspxehg0femceshsu3ra4swxn8zqkqlawek2
AGE-SECRET-KEY-1L8PCZT4950JDF2P5G0DRLXVZ2QMU8UTDHZHH38RTLNMZYH7TSDXSQLSGHK
```

That third line is everything. Not a fingerprint of the key — the key. Whoever reads that one line can decrypt every file you have ever encrypted or ever will, retroactively, forever, and you will never know they did, because reading a file leaves no mark. There is no passphrase on it by default, no hardware token, no "unlock the keychain" prompt. It is a secret stored the way a Post-it stores a secret, and it is sitting in your home directory next to your shell history and whatever your editor's crash-recovery swap file decided to keep.

To its credit, `age-keygen` writes that file `0600` when it creates the file itself:

```console
$ ls -l key.txt
-rw------- 1 runner runner 184 Sep  8 09:28 key.txt
```

But watch what happens the instant you do the thing every tutorial does — pipe the output to a file with a redirect instead of `-o`:

```console
$ umask 022
$ age-keygen > leaked-key.txt
$ ls -l leaked-key.txt
-rw-r--r-- 1 runner runner 184 Sep  8 09:28 leaked-key.txt
```

`0644`. World-readable. When `age-keygen` opens the file, it sets the mode; when your *shell* opens the file for a redirect, it uses your umask, and the tool never sees it. Every other user on that box — every process, every misbehaving dependency, every backup job that slurps your home directory into a bucket someone forgot to make private — can now read your master key. SEVERITY: the tutorial you copied. ATTACK VECTOR: the `>` you thought was the same as `-o`. It is not the same as `-o`.

## Finding 2 — a clean decrypt tells you nothing about who wrote the file

This is the one that matters, and it's the one the word "encrypted" quietly lies about. Encryption hides *what* the message says. It does not, in `age`, say anything about *who* sent it — and it can't, because encrypting to your public key is something *anyone* can do. That's the entire point of a public key: it's public.

So put on the attacker's hat. I have your public key — it's public, you literally publish it — and nothing else. I write you a message:

```console
$ printf 'wire the funds to account 9999\n' > forged.txt
$ age -r age164a7du5mlwssxvx3rtsstjhspxehg0femceshsu3ra4swxn8zqkqlawek2 -o forged.age forged.txt
```

You receive `forged.age`, you decrypt it with your private key, and it opens without a whisper of complaint:

```console
$ age -d -i key.txt forged.age
wire the funds to account 9999
$ echo "exit=$?"
exit=0
```

Exit 0. Decrypts cleanly. Reads like it came from your CFO. It came from me. There is no signature, no sender identity, no "verified" banner, because `age` never claimed to authenticate the author — the `gpg` verb for that is `--sign`, and `age` deliberately doesn't have it. This is a defensible design decision and I agree with it. It is also a landmine for every person who read the word "encrypted" and heard "trusted." If you need to know a file came from a specific person, `age` is not your tool for that half of the job, and it won't warn you that you brought the wrong tool. SEVERITY: your accounts-payable process. ATTACK VECTOR: the assumption that "only I can open it" implies "only they could have sent it."

## Finding 3 — the passphrase mode won't be automated, on purpose, and thank goodness

`age -p` encrypts to a passphrase instead of a key, which is what you'll reach for when you don't want to manage key files. Try to feed it a passphrase from a script the obvious way and it plants its feet:

```console
$ echo 'correct horse battery staple' | age -p secret.txt > pass.age
age: error: could not read passphrase: standard input is not a terminal, and /dev/tty is not available
$ echo "exit=$?"
exit=1
```

It refuses to read a passphrase from a pipe. It demands a real terminal. Nine times out of ten you'll meet this at 2 a.m. while wiring `age -p` into a cron job, and you'll curse it — and it is *right* and you are wrong. A passphrase you can pipe from a script is a passphrase that lives in that script, in your shell history, in the CI log, in the process list where `ps` shows it to every other user for the half-second the pipe is open. The tool declining to let you do the convenient thing is the tool protecting you from the convenient thing. (When it does prompt you on a real terminal, `age` stretches the passphrase with `scrypt` — which means a weak passphrase is merely *expensive* to brute-force, not safe. It buys you time, not immunity. Pick a long one.) This is the rarest event in security tooling: a convenience feature that was removed *for* you. I'm as suspicious of it as I am of everything, and I checked, and it's real.

## The one it earns: it actually notices tampering

I don't hand these out. `age` authenticates the ciphertext, so if anyone flips a single byte of an encrypted file in transit, decryption fails loudly instead of handing you quietly-corrupted plaintext. I flipped exactly one byte:

```console
$ cp secret.age tampered.age
$ printf '\x00' | dd of=tampered.age bs=1 seek=180 count=1 conv=notrunc
$ age -d -i key.txt tampered.age
age: error: failed to decrypt and authenticate payload chunk
$ echo "exit=$?"
exit=1
```

It caught it. Not "returned garbage," not "exited 0 with a mangled last line" — it refused, named the reason, and failed non-zero so your script can see it. That's authenticated encryption doing its job, and it means the attacker in Finding 2 can *forge a whole new file* but cannot *silently edit an existing one*. Grudging respect. It hurts to type, but there it is.

## Disclosure, price, and the alternative

`age` is free and open source (BSD-licensed); I have no relationship with its author beyond having tried very hard to break the thing on a throwaway VM. The alternative is `gpg`, which *does* sign, *does* manage keys and identities, and *does* give you the web of trust — and in exchange gives you forty subcommands, a key-management model that has generated its own genre of blog posts, and enough footguns that "encrypt a file with gpg" is a coin flip on whether you also leaked it. Reach for `gpg` when you specifically need signing or key identity and are willing to pay for it in complexity. Reach for `age` when you need to encrypt a file to a key and want it to be boring. Most days you want boring.

## Three mitigations, ranked, each one I actually ran

1. **Never create an identity with a shell redirect — always `age-keygen -o key.txt`, then verify the mode.** Finding 1 is the whole ballgame: your private key is a plaintext string, so its file permissions *are* your security. `-o` sets `0600`; `>` inherits your umask and can land `0644`. After generating, run `ls -l` and confirm you see `-rw-------`, then treat that file like the master key it is — back it up encrypted (or on paper), never sync it to a shared drive, and `chmod 600` it the second you're unsure. I generated keys both ways above; only one of them was safe.

2. **If you need to know who sent the file, don't ask `age` — it can't tell you.** Encryption is confidentiality, not authorship. A cleanly-decrypting file proves only that it was encrypted to your public key, which anyone can do (I forged one with nothing but the public string). For "is this really from them," you need a signature — `minisign` or `ssh-keygen -Y sign`/`-Y verify` are the small, sharp tools for that, or `gpg` if you're already living there. Verify the signature *before* you act on the contents, not after the wire transfer clears.

3. **Keep passphrase mode interactive, and keep it strong.** `age -p` refusing your pipe (Finding 3) is a feature — leave it that way. Don't script the passphrase in; if a machine must decrypt unattended, use a key file with locked-down permissions (mitigation 1) and protect *that*, not a passphrase baked into a cron line. When you do type a passphrase, make it long enough that `scrypt` buys you real years, not real minutes — a five-word passphrase, not `hunter2`.

`age` is a good tool that tells the truth about its job by doing exactly its job and nothing else. The insecurity was never in the tool. It was in the four things you were going to assume it did — and now, having watched me forge a message to you with your own public key, you'll assume only the one it actually promised. Certified n00b, promoted to slightly-harder-to-phish.
