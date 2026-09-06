---
title: "pass: the password manager that encrypts the secret and leaves the label on the box"
description: "pass encrypts your passwords with GPG as plain files — but leaves every filename in cleartext and keeps deleted secrets in git forever. Threat-modeled."
date: 2026-09-06
categories: [Tools]
tags: [system, productivity]
author: cass
verdict: "Use it — GPG-backed, plain files, no subscription. But it encrypts the secret, not the label: turn OFF the git sync (or scrub it), keep the store on encrypted-at-rest storage, and never `-c` on a shared display."
excerpt: "The unix password manager I actually trust — GPG under the hood, a directory of files, no cloud. It also files every secret under a cleartext label and keeps the deleted ones in git forever. Verdict: use it, threat-model it first."
preview: /images/previews/pass-the-password-manager-that-encrypts-the-secret.svg
permalink: /tools/pass-password-manager-honest-review/
---
**Verdict: use it. `pass` is the password manager I reach for on any machine with a shell — it encrypts each secret with your GPG key, stores it as a plain file, syncs over git you control, and asks for exactly zero dollars a month. I trust it more than any vault with a marketing budget. Now let me tell you the three things it does NOT encrypt, because a tool you trust is precisely the one worth threat-modeling.** I have no relationship with `pass`, GnuPG, or Jason Donenfeld; it's GPLv2, nobody paid me, and I distrust free things on principle — which is why this review exists.

Here is the thing about a password manager: it is a single box holding everything an attacker wants, so it advertises "encrypted" the way a bank advertises "vault." Fine. But "encrypted" is a claim about the *contents* of the box. It says nothing about the *label*. And `pass` — bless its minimalist heart — writes the label in permanent marker on the outside.

Everything below ran for real on Ubuntu 24.04, `pass 1.7.4`, GnuPG 2.4.4, in a throwaway store at `/tmp/passdemo-store` with a throwaway key (your real store defaults to `~/.password-store` — that's why the demo paths below say `/tmp`). The secrets are fake. The behavior is not.

## What earns the install

`pass` is `gpg` with a directory convention and a git wrapper, and that is a compliment. Each entry is a `.gpg` file; the tree of files IS your password list. Set it up, add a few secrets:

```console
$ pass init passdemo@lifehacker.dev
Password store initialized for passdemo@lifehacker.dev

$ printf 'hunter2\n'          | pass insert -e email/gmail.com/alice
$ printf 'sk-live-abcd1234\n' | pass insert -e work/stripe-prod-api-key
$ printf 'correct-horse\n'    | pass insert -e bank/chase.com/alice

$ pass ls
Password Store
├── bank
│   └── chase.com
│       └── alice
├── email
│   └── gmail.com
│       └── alice
└── work
    └── stripe-prod-api-key
```

The contents really are encrypted. Pull the raw file off disk and it's ciphertext — `strings` gets you nothing, the secret is not in there in any readable form:

```console
$ file /tmp/passdemo-store/work/stripe-prod-api-key.gpg
/tmp/passdemo-store/work/stripe-prod-api-key.gpg: data

$ strings /tmp/passdemo-store/work/stripe-prod-api-key.gpg | head -3
'M/j/
```

That's the good part, and it's genuinely good. No cloud, no phone-home, no "sync service" that is really a copy of your vault on someone else's computer. Your secrets are asymmetric-encrypted to a key that lives in your GPG agent. `SEVERITY: manageable. ATTACK VECTOR: someone who already has your unlocked GPG key, at which point you have larger problems than a password manager.`

So where's the paranoia? Look at that `pass ls` output again. Read it like an attacker who cannot decrypt a single byte.

## Leak #1: the filename is the metadata, and the metadata is cleartext

`pass` encrypts the password. It does not — cannot — encrypt the *path* the password lives at. The path is a real directory on a real filesystem, and directory names are not secret. An attacker who gets read access to `~/.password-store` (a synced backup, a stolen laptop, a misconfigured Dropbox folder, a container image someone `COPY . .`'d) does not need your key to learn this:

```console
$ find /tmp/passdemo-store -name '*.gpg' -printf '%P\n' | sed 's/\.gpg$//' | sort
bank/chase.com/alice
email/gmail.com/alice
work/stripe-prod-api-key
```

I just learned that `alice` banks at Chase, uses Gmail, runs Stripe in production, and — because you helpfully named the file `stripe-prod-api-key` — exactly which secret to spearphish out of her. I have not decrypted anything. The vault held. The label told me everything I needed to write the phishing email.

Escalate it to the worst case, because that's the job: a state-level actor exfiltrates a backup of ten thousand employees' password stores. They can't crack GPG. They don't need to. `find | sort` gives them a de-anonymized map of every service every employee uses, which bank, which crypto exchange, which internal admin panel is named `admin/root/prod-db`. That is a target list, sorted, for free.

Walk it back to reality: you are not being targeted by a state actor. But your `~/.password-store` probably IS in a git repo, and that git repo probably IS on someone else's server, and "the contents are encrypted so it's fine to push publicly" is a sentence people say right before they publish their entire life's org chart. **There is no `pass` flag that hides this.** I checked — the filenames stay cleartext no matter what you do inside the tool, because the tool is a convention over the filesystem and the filesystem's whole job is to know filenames. `RATING: CVE-YOUR-DIRECTORY-LISTING. SEVERITY: your threat model. EXPLOITABILITY: ls.`

## Leak #2: git remembers the secret you deleted

`pass` has optional git integration and the docs treat it as a feature, which it is — versioned, syncable, auditable secrets. It is also the single best way to keep a compromised password alive forever after you thought you killed it.

Turn on git, then do the two things everyone does with a password manager: rotate a leaked key, and delete an account you closed.

```console
$ pass git init
$ printf 'sk-live-ROTATED-9999\n' | pass insert -e -f work/stripe-prod-api-key
[master 369a781] Add given password for work/stripe-prod-api-key to store.

$ pass rm -f bank/chase.com/alice
removed '/tmp/passdemo-store/bank/chase.com/alice.gpg'
[master 1050869] Remove bank/chase.com/alice from store.

$ pass ls
Password Store
├── email
│   └── gmail.com
│       └── alice
└── work
    └── stripe-prod-api-key
```

The bank entry is gone from the tree. The old Stripe key is overwritten. Clean, right? Now put on the attacker hat, `cd` into the store, and ask git what it remembers:

```console
$ pass git log --oneline
1050869 Remove bank/chase.com/alice from store.
369a781 Add given password for work/stripe-prod-api-key to store.
2e5e775 Configure git repository for gpg file diff.
e27f48d Add current contents of password store.
```

Every version is right there. And because I have the key that this store was encrypted to — which is the whole point, git stores the *ciphertext* blobs — I can decrypt the deleted and the rotated-away secrets out of history in one line each:

```console
$ git show 369a781:bank/chase.com/alice.gpg | gpg -d --quiet
correct-horse

$ git show e27f48d:work/stripe-prod-api-key.gpg | gpg -d --quiet
sk-live-abcd1234
```

There it is. `pass rm` did not delete your secret; it *hid* it. The bank password you deleted and the Stripe key you rotated because it leaked are both sitting in `.git/`, fully recoverable, for as long as that repo exists — which, if you pushed it, is "everywhere it was ever cloned, forever." `SEVERITY: the intern who force-pushed the store to a public mirror in 2024. ATTACK VECTOR: git.`

This is not a bug in `pass`. It is git doing exactly what git does — keep history — colliding with what "rotate a leaked secret" actually requires, which is that the old value stop existing. The tool never claims otherwise; it just doesn't warn you, and the friendly `[master 1050869] Remove...` message reads like a delete when it's an append.

## Leak #3: the clipboard is a room everyone's standing in

`pass -c` copies a secret to your clipboard instead of printing it, and on a headless box it fails honestly, which I appreciate:

```console
$ pass show -c work/stripe-prod-api-key
Error: No X11 or Wayland display detected
```

On your actual desktop it succeeds, and there's the rub: the X11/Wayland clipboard is a *shared* resource. It is not scoped to one app. Every program in your session — every Electron chat client, every browser tab with clipboard read permission, every "productivity" tool that syncs your clipboard to the cloud because that seemed helpful in a planning meeting — can read what `pass -c` just put there. `pass` mitigates this by clearing the clipboard after 45 seconds (honored via the real `PASSWORD_STORE_CLIP_TIME` env var — it's referenced right in the script), which is a genuine kindness and also a 45-second window during which your production API key is a global variable readable by every process you're running. `Convenience feature: the clipboard. Attack surface: the clipboard.`

Two more sharp edges while the hat's on, both real: `pass generate` prints the new secret to your terminal, so it lands in scrollback and possibly your terminal emulator's log; and `pass grep` decrypts *every entry in the store* to run the search — a single `pass grep` momentarily has your entire plaintext vault in memory, which is fine on your laptop and less fine on a shared build agent.

## The three mitigations that actually matter

Ranked, tested, none of them "be more careful."

**1. Treat a leaked-then-rotated secret as still leaked, and scrub the history — don't just `pass rm`.** This is #1 because it's the one that saves you after a real compromise. The moment a secret hits git history, rotating it in `pass` doesn't un-leak the old value; you must also rotate it *at the source* (regenerate the Stripe key in Stripe's dashboard) AND remove it from history. The blunt, tested version is to drop the git history entirely and start fresh — the old blobs become unreachable:

```console
$ rm -rf /tmp/passdemo-store/.git
$ pass git init
$ git show 369a781:bank/chase.com/alice.gpg
fatal: invalid object name '369a781'.
```

The recoverable blob is gone. (For a store you want to keep syncing with history intact elsewhere, `git filter-repo --path <file> --invert-paths` does the surgical version — but if the repo already left your machine, assume the secret is burned and rotate at the source anyway. History scrubbing protects the *next* clone, not the ones already out there.)

**2. Keep the store on encrypted-at-rest storage, and never push the plaintext tree to a plain remote.** This is the only real answer to Leak #1, because the filename leak has no in-tool fix. Put `~/.password-store` on a LUKS/dm-crypt volume or an encrypted home directory so the cleartext tree only exists while your disk is unlocked, and if you sync it, sync it somewhere the *directory listing itself* is protected — a private repo you control, not a public mirror, and not a consumer cloud folder that indexes filenames. Opaque entry names (`svc/7f3a` instead of `bank/chase.com/alice`) help a little, but you have to actually remember them, so in practice the filesystem-level fix is the one that holds.

**3. Stop using `-c`; pipe the first line straight into what needs it.** The clipboard is a shared bus; skip it. `pass show` puts the secret on stdout, and the first line is the password by convention, so pipe it directly to the one program that needs it and it never touches the clipboard, scrollback, or another app's memory:

```console
$ pass show work/stripe-prod-api-key | head -1 | wc -c
21
```

The secret went down the pipe and was never rendered. Wire that into your tools (`curl -H "Authorization: Bearer $(pass show work/stripe-prod-api-key | head -1)"`), and set `PASSWORD_STORE_CLIP_TIME` low for the times you genuinely must use `-c`.

## So, use it?

Yes. Unreservedly, actually — `pass` is the right shape for secrets management: local, open, GPG-backed, no vendor, no subscription, no cloud copy of your vault. It does the hard cryptographic part correctly and gets out of the way. Just remember what "encrypted" is a claim about. It encrypts the secret. The label, the history, and the clipboard are on you — and now you know exactly where each one leaks, and the three moves that plug them.

I trust `pass`. I trust it because I threat-modeled it, not instead of having done so. Do the same to this review, by the way. I would.
