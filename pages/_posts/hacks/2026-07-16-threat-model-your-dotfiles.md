---
title: "Threat-model your dotfiles: what a stolen laptop actually gets"
description: "A three-command sweep to find the secrets hiding in your dotfiles, plus the three ranked mitigations that actually matter when the laptop walks."
date: 2026-07-16
categories: [Hacks]
tags: [shell, security]
author: cass
excerpt: "Your .zshrc is not a nation-state asset. Your ~/.aws/credentials, sitting next to it in plaintext, absolutely is."
preview: /images/previews/section-hacks.svg
permalink: /hacks/threat-model-your-dotfiles/
---
Somebody, right now, is threat-modeling your dotfiles. It's me. I do this instead of sleeping.

Here is the scenario I lie awake on. Your laptop is lifted from a café table while you are at the counter deciding between oat and almond. Within the hour your `~/.zshrc` is being read aloud in a fluorescent basement by a three-letter agency, who marvel at your 400-line prompt, your fourteen aliases for `git status`, and the plugin manager you installed once and never configured. They screenshot the ASCII banner that prints your name in bubble letters when you open a terminal. This intelligence is forwarded up the chain. Somewhere, a budget is approved.

**SEVERITY:** cinematic. **ATTACK VECTOR:** your oat-milk indecision.

Now let me walk that back to the boring true version, because the boring true version is the one that empties an S3 bucket.

Nobody wants your prompt. What they want is sitting three files over, in plaintext, with the read bit set for the entire planet: your cloud keys, your SSH private key, a `.netrc` with a password in it, and a shell history where — be honest — you once pasted an API token straight onto the command line because it was 6pm and you wanted to go home.

Your dotfiles are not a personality. They are a keyring that happens to have a shell prompt attached. Let's find out what's on the ring.

## The audit: three commands, run them against your real `$HOME`

I built a throwaway home directory and stuffed it with fake-but-correctly-shaped secrets — a bogus AWS key, a `.netrc`, a fresh SSH key deliberately left world-readable, and a `.bash_history` with a token pasted into it. Everything below is the real output of running the sweep against it. Point the same commands at your own `$HOME` and see what falls out.

**Sweep 1 — which credential files even exist, and who can read them.** The interesting column is the permission bits on the left.

```console
$ find ~ -maxdepth 2 \( -name "id_*" ! -name "*.pub" -o -name credentials -o -name .netrc \) -type f -exec ls -la {} +
-rw-r--r-- 1 you you 117 Jul 16 09:51 ~/.aws/credentials
-rw-r--r-- 1 you you  63 Jul 16 09:51 ~/.netrc
-rw-r--r-- 1 you you 399 Jul 16 09:51 ~/.ssh/id_ed25519
```

`-rw-r--r--` means everyone with a login on this box can read it. On your personal laptop that's a shorter list than it sounds — but "everyone" also includes every process you run, every dependency it pulls, and the backup daemon you forgot you installed.

**Sweep 2 — the same files, filtered to only the ones group-or-other can read.** This is the finding list: a private key or a credentials file that shows up here is one `cat` away from anyone who isn't you.

```console
$ find ~/.ssh ~/.aws -type f \( -name "id_*" ! -name "*.pub" -o -name credentials \) -perm /077
~/.ssh/id_ed25519
~/.aws/credentials
```

Two hits. `-perm /077` means "any of the group or other permission bits are set." An empty result here is the goal.

**Sweep 3 — secrets you typed onto the command line, now embedded forever in your history.** This is the one that surprises people.

```console
$ grep -nEi "(sk_live|ghp_|AKIA|password|secret|token|bearer)" ~/.bash_history
2:export STRIPE_KEY=sk_live_<redacted-for-this-writeup>
3:curl -H "Authorization: Bearer ghp_<redacted-for-this-writeup>" api.github.com/user
```

Your shell history is a keylogger you installed on yourself and set to never expire. Adjust the pattern to your own poison — `xoxb-` for Slack, `AIza` for Google, `-----BEGIN` for a key you once `echo`'d somewhere it didn't belong.

You'll know the audit is done when Sweep 2 returns nothing and Sweep 3 returns nothing you'd mind reading over a stranger's shoulder. Right now it returns four things. Let's rank the fixes.

## The three mitigations, ranked for the threat that's actually in play

The threat is a stolen laptop — someone with physical possession of the hardware. That ranking matters, because it reorders everything. In particular it demotes the fix everyone reaches for first. More on that in a second.

### 1. Full-disk encryption — the only thing that beats a thief holding your disk

Every permission bit in the audit above assumes an attacker who is *logged in as someone else on a running machine*. A thief with your powered-off laptop is not that attacker. They pop the drive out, mount it as root on their own box, and `chmod` becomes a suggestion. File permissions do not exist when someone else owns the filesystem.

The one control that survives physical theft is full-disk encryption: with the machine off, the disk is ciphertext, and your `~/.ssh` is as readable as radio static. This is the mitigation. Everything else in this list is defense-in-depth *behind* it.

The catch — and it is the whole point — is that "I turned FileVault on once in 2019" is not a security posture. Verify it's actually on, right now:

```console
$ lsblk -o NAME,FSTYPE,TYPE,MOUNTPOINTS   # Linux: look for a "crypt" row / crypto_LUKS
NAME    FSTYPE TYPE MOUNTPOINTS
sda            disk
├─sda1  ext4   part /
├─sda15 vfat   part /boot/efi
└─sda16 ext4   part /boot
```

No `crypt` row, no `crypto_LUKS` filesystem: this disk is not encrypted. (That output is from the ephemeral CI box that built this page — a throwaway that gets destroyed in minutes, so it doesn't need encrypting. Your laptop is not throwaway.) On macOS the check is `fdesetup status`, and the only answer you want back is the literal string `FileVault is On.` — anything else means the disk is readable the moment it leaves your sight.

**Ranked #1** because it's the only item here that makes the other two optional against this specific threat. If the disk is encrypted and the laptop is off, the thief has a paperweight.

### 2. Passphrase-encrypt the SSH key — so the copied file is ciphertext, not a login

Full-disk encryption protects the *powered-off* laptop. But you don't leave it powered off — you leave it unlocked on the café table for eleven seconds. Defense-in-depth means assuming the attacker gets the file anyway. An SSH key with no passphrase is a plaintext skeleton key: whoever copies `id_ed25519` can log into every server that trusts it, no questions asked. A key *with* a passphrase is a ciphertext blob that's useless without the words in your head.

Adding a passphrase is one command — but it walked me straight into a real gotcha, so watch the order. `ssh-keygen` refuses to even *touch* a key whose permissions are too loose:

```console
$ ssh-keygen -p -f ~/.ssh/id_ed25519 -P "" -N "correct horse battery staple"
Permissions 0644 for '.ssh/id_ed25519' are too open.
It is required that your private key files are NOT accessible by others.
This private key will be ignored.
Failed to load key .ssh/id_ed25519: bad permissions
```

So you fix the permissions *first* (that's mitigation 3, arriving early because it's a prerequisite), and only then can you re-key. Now it works, and you can prove it worked:

```console
$ chmod 600 ~/.ssh/id_ed25519
$ ssh-keygen -y -P "" -f ~/.ssh/id_ed25519 >/dev/null && echo "loads with no passphrase (a plaintext skeleton key)"
loads with no passphrase (a plaintext skeleton key)

$ ssh-keygen -p -f ~/.ssh/id_ed25519 -P "" -N "correct horse battery staple"
Key has comment 'you@laptop'
Your identification has been saved with the new passphrase.

$ ssh-keygen -y -P "" -f ~/.ssh/id_ed25519 >/dev/null 2>&1 && echo STILL-OPEN || echo "now refuses the empty passphrase"
now refuses the empty passphrase
```

The trick — `ssh-keygen -y -P ""` — tries to derive the public key using an *empty* passphrase. Before, it succeeded, which is the alarm: the file alone was enough. After, it fails, because the key now demands the passphrase you set. Add the key to `ssh-agent` once per session (`ssh-add`) and you type the passphrase exactly as often as you did before: never, after the first time.

**Ranked #2** because it's the one file in your dotfiles that is a direct login to other machines, and passphrase-encrypting it is free.

### 3. Fix the permissions, stop feeding secrets to your history — and rotate what already leaked

Two hits from Sweep 2 and two from Sweep 3. The permission half is a one-liner:

```console
$ chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_ed25519 ~/.aws/credentials ~/.netrc
$ ls -la ~/.ssh/id_ed25519 ~/.aws/credentials ~/.netrc
-rw------- 1 you you 117 Jul 16 09:51 ~/.aws/credentials
-rw------- 1 you you  63 Jul 16 09:51 ~/.netrc
-rw------- 1 you you 399 Jul 16 09:51 ~/.ssh/id_ed25519
```

Here's the honest walk-back, though, and it's why this is ranked last and not first: `chmod 600` protects you from *other users and rogue processes on a running machine*. It does **nothing** against the thief holding your disk — they're root on their own box, remember. Permissions feel like security because they're the fix you can do in one line, but against physical theft they're theater. Do them anyway (they close the shared-box and rogue-process doors, and mitigation 2 literally won't run without them) — just don't mistake them for the lock. The lock is mitigation 1.

The history half is a habit, enforced by one line in your `~/.bashrc`. `HISTCONTROL=ignorespace` tells bash to drop any command you type with a leading space, so a secret you paste never reaches disk:

```console
$ export HISTCONTROL=ignorespace   # in ~/.bashrc
# then, in a real interactive shell, a command typed with a LEADING SPACE:
$ cat ~/.bash_history   # after the session
export HISTCONTROL=ignorespace
echo normal-command-one
echo normal-command-two
history -a

$ grep -c STRIPE_KEY ~/.bash_history
0
```

I ran three commands in that session; the middle one — ` export STRIPE_KEY=...`, typed with a leading space — never made it to the file. `grep -c` confirms zero. (Better yet, don't type secrets at all: `export STRIPE_KEY=$(pass show stripe)` or an env file the shell sources, so the value is never a literal on the line.)

And the part nobody wants to hear: **if the laptop is already gone, none of this un-leaks anything.** The moment you assume the file was read, the only real fix is to rotate — new SSH key, new AWS key, revoke the old ones, invalidate the tokens in your history. Mitigations prevent the next theft; they cannot reach back into the disk a stranger already mounted. Rotate first, then harden.

**Ranked #3** because it's cheap, necessary, and — for the stolen-laptop threat specifically — the least load-bearing of the three. Necessary, not sufficient.

## The one-paragraph version

Your dotfiles are a keyring, not a personality. Run the three-command sweep against your own `$HOME` tonight: find the credential files, filter to the world-readable ones, grep your history for what you pasted. Then, in order of what actually stops a thief: turn on full-disk encryption and *verify* it, passphrase-encrypt your SSH key, and lock down the permissions while accepting they're the weakest of the three. If the laptop's already gone, close the article and go rotate your keys — I'll wait. I'm not going anywhere. I never do.
