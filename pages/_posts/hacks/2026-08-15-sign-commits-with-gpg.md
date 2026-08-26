---
title: "Sign your commits with GPG for the Verified badge (and why GitHub still says Unverified)"
description: "Generate a GPG key, turn on commit signing, and earn the green Verified badge — plus the three silent reasons GitHub keeps showing Unverified, each reproduced."
date: 2026-08-15
preview: /images/previews/sign-your-commits-with-gpg-for-the-verified-badge-.jpg
categories: [Hacks]
tags: [git, security]
author: cass
excerpt: "Anyone can commit under your name. The green Verified badge is the one thing that says a commit is actually you — here's how to earn it, and the three ways it silently stays grey."
permalink: /hacks/sign-commits-with-gpg/
---
Right now, on a laptop somewhere, someone is committing under your name. They did not break into anything. They typed four words:

```console
$ git config user.name "You, Apparently"
$ git config user.email "your.real@email.com"
```

That's it. That's the whole exploit. Git author identity is a text field with a trust level of "please." The name and email attached to a commit are a *claim the committer typed*, not a fact anyone checked — and GitHub will happily render that claim with your avatar and your name in the timeline, because your email is on file. A stranger can push a commit that adds a backdoor to a dependency, sign it "You," and the blame view will agree with them.

**SEVERITY:** your professional reputation, retroactively. **ATTACK VECTOR:** a form field with no validation, invented in 2005.

Let me walk that back to the boring true version, because the boring true version is the one that matters. Nobody is impersonating you in a git commit to frame you for espionage. But your commits *do* travel — into other people's repos, into audit logs, into the "who approved this" conversation after an incident — carrying an identity that anyone could have typed. The green **Verified** badge next to a commit is the one thing on GitHub that says: *this was signed by a key that provably belongs to this account.* It's a cryptographic signature standing where a text field used to stand.

This idea landed on my desk from the it-journey.dev character-setup notes on [initializing your developer identity](https://it-journey.dev/notes/zero/start/) — which is the right frame. Your commit identity *is* an identity, and an identity you can't prove is just a costume. Let's give it a signature.

## Step 1: generate a signing key

You want a modern key. `gpg --full-generate-key` walks you through it interactively — pick **ECC / EdDSA (ed25519)**, no expiry or a year out, and set the email to the one you commit with. I generated mine in batch mode so this write-up is reproducible, but the result is identical. Here's the real key it produced:

```console
$ gpg --list-secret-keys --keyid-format=long
sec   ed25519/069AD32453C4996B 2026-08-15 [SC]
      547BF1B3525D4169259C93C3069AD32453C4996B
uid                 [ultimate] Cass Vector <cass@lifehacker.dev>
```

The part you'll paste into git is the **long key id** after the slash: `069AD32453C4996B`. The 40-character string on the next line is the full fingerprint; either works, but the long id is less to fat-finger.

One thing to notice now, because it comes back to bite in a moment: the key has an *email baked into it* — `cass@lifehacker.dev`. That email is not decoration. GitHub uses it to decide whether the badge goes green.

## Step 2: tell git to sign

Three settings. Point git at the key, turn signing on by default, and (on some setups) name the gpg binary explicitly:

```console
$ git config --global user.signingkey 069AD32453C4996B
$ git config --global commit.gpgsign true
$ git config --global gpg.program gpg
```

Now every commit gets signed. Make one and check the work with `--show-signature`:

```console
$ git commit -m "first signed commit"
$ git log --show-signature -1
gpg: Signature made Sat Aug 15 09:10:40 2026 UTC
gpg:                using EDDSA key 547BF1B3525D4169259C93C3069AD32453C4996B
gpg: Good signature from "Cass Vector <cass@lifehacker.dev>" [ultimate]
```

`Good signature` locally means the math checks out on *your* machine, where the key lives. It does **not** mean GitHub will trust it, because GitHub has never seen this key. That's step 3, and it's where everyone gets stuck.

## Step 3: give GitHub the public half

GitHub can only verify a signature against a public key you've handed it. Export the **public** half — the part that's safe to share — and it comes out as an armored block:

```console
$ gpg --armor --export 069AD32453C4996B
-----BEGIN PGP PUBLIC KEY BLOCK-----

mDMEaoAs+xYJKwYBBAHaRw8BAQdADVQpHFI2cJVnizesu0G6ck841RAztETqoD1T
...(truncated)...
=fHIM
-----END PGP PUBLIC KEY BLOCK-----
```

Copy the whole block, including the `BEGIN`/`END` lines, and paste it into **GitHub → Settings → SSH and GPG keys → New GPG key** (their walkthrough is [here](https://docs.github.com/en/authentication/managing-commit-signature-verification/adding-a-gpg-key-to-your-github-account)). Push a signed commit and the badge should go green.

Should. If it doesn't — and for a lot of people it doesn't — it's one of exactly three things, and every one of them fails *silently*. Your commit exists, `git log` says `Good signature`, and GitHub just quietly shows grey. Here they are, ranked by how often they actually bite.

## The three reasons the badge stays grey, ranked

### 1. The committer email doesn't match the key — and nothing warns you

This is the top of the list because git gives you zero indication anything is wrong. Watch. I changed my committer email to one that does **not** match the key's baked-in `cass@lifehacker.dev`, then committed:

```console
$ git config user.email "cass@personal-laptop.local"
$ git commit -m "second commit, mismatched committer email"
$ git log --show-signature -1 --format="committer email: %ce"
gpg: Signature made Sat Aug 15 09:10:46 2026 UTC
gpg:                using EDDSA key 547BF1B3525D4169259C93C3069AD32453C4996B
gpg: Good signature from "Cass Vector <cass@lifehacker.dev>" [ultimate]
committer email: cass@personal-laptop.local
```

Exit code zero. `Good signature`. Not a single complaint. But look at the mismatch: the signature was made by the key for `cass@lifehacker.dev`, while the commit is stamped `cass@personal-laptop.local`. GitHub's verification rule (documented [here](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification)) needs three things to *all* line up: the signature is valid, the key is on your account, **and the committer email matches a verified email on that account**. Fail the third and the badge stays grey, with no error anywhere in your terminal to tell you why.

**Fix:** make the three emails agree. The email you commit with (`git config user.email`), the email on the GPG key's UID, and a verified email in your GitHub account settings must be the same address. Check the committer side with `git config user.email` and the key side with `gpg --list-secret-keys` — if they disagree, that's your grey badge.

**SEVERITY:** a config typo. **ATTACK VECTOR:** the work laptop where you set `user.email` once, in 2021, to the wrong address.

### 2. The public key was never uploaded (or you uploaded the private one, don't)

Ranked second only because it's the obvious one — but it's obvious *after* you know signing and uploading are two separate acts. A `Good signature` locally proves your machine has the *private* key. GitHub verifies against the *public* key, and it can't verify against a key it doesn't have. No upload, no verification, no badge — and, again, no error: your push succeeds normally.

**Fix:** the `gpg --armor --export <keyid>` block from step 3, pasted into GitHub's GPG keys settings. Two guardrails while you're there. First, confirm you exported with `--export` and not `--export-secret-keys` — the public block starts with `PUBLIC KEY BLOCK`; if yours says `PRIVATE KEY BLOCK`, stop, that's the half that signs *as you*, and it never leaves your machine. Second, the key's email has to be one GitHub has *verified*, not just one you typed — an unverified address won't turn the badge green no matter how correct the signature is.

### 3. `gpg failed to sign the data` — the commit dies before a signature exists

The other two leave you with a signed commit that GitHub won't bless. This one is louder and earlier: the commit doesn't happen at all. The first time you sign on a fresh terminal — a new SSH session, a tmux pane, a machine where the GPG agent can't find a screen to draw a password prompt on — you get this:

```console
$ git commit -m "signed commit attempt"
error: gpg failed to sign the data:
[GNUPG:] KEY_CONSIDERED 6DE8701725550E7CFD4699492B02F92331067C8E 2
[GNUPG:] BEGIN_SIGNING H10
[GNUPG:] PINENTRY_LAUNCHED 7502 curses 1.2.1 - - - - 1001/1001 -
gpg: signing failed: Inappropriate ioctl for device
[GNUPG:] FAILURE sign 83918950
fatal: failed to write commit object
```

`Inappropriate ioctl for device` is GPG's way of saying *I tried to pop up a passphrase prompt and there was no terminal to pop it up on.* The commit is rejected — I confirmed the repo had zero commits afterward, nothing half-written. The culprit is a missing environment variable that tells GPG's pinentry which terminal it's allowed to talk to.

**Fix:** export `GPG_TTY` so pinentry knows where to prompt. Put this in your `~/.bashrc` or `~/.zshrc`:

```console
export GPG_TTY=$(tty)
```

Open a new shell (or `source` the file), and the passphrase prompt has a terminal to appear on. I verified the other side of this directly: the *same* key and the *same* commit that produced the error above signed cleanly the moment pinentry could actually obtain the passphrase —

```console
$ git log --show-signature -1
gpg: Signature made Sat Aug 15 09:11:28 2026 UTC
gpg:                using EDDSA key 6DE8701725550E7CFD4699492B02F92331067C8E
gpg: Good signature from "Cass Vector <cass@lifehacker.dev>" [ultimate]
```

The key was never broken. The config was never wrong. GPG just had no window to ask you the one question it needed answered. `GPG_TTY` gives it one.

## The one-paragraph version

Commit authorship is a text field anyone can type; the Verified badge is the cryptography that makes it a claim you can prove. Generate an ed25519 key with `gpg --full-generate-key`, point git at it (`user.signingkey`, `commit.gpgsign true`), and export the **public** half into GitHub's GPG-keys settings. Then, when the badge stays stubbornly grey — and it will — check the three silent failures in order: the committer email must match the key's email *and* a verified email on your account (the mismatch that warns you about nothing); you must upload the public key, not the private one; and if the commit won't even sign, `export GPG_TTY=$(tty)` gives pinentry a terminal to ask for your passphrase. A green badge is not a personality trait. It's three settings and one environment variable, all of which fail quietly, which is exactly why nobody's badge is green.
