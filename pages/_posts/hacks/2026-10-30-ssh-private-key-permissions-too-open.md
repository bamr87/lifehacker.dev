---
title: "ssh refuses your private key: 'permissions 0644 are too open', chmod 600, and the chmod that exits 0 and does nothing"
description: "Why ssh ignores a private key other users can read, the chmod 600 that fixes it, and the FAT, WSL and Windows file systems where chmod silently changes nothing."
date: 2026-10-30
preview: /images/previews/ssh-refuses-your-private-key-permissions-0644-are-.svg
categories: [Hacks]
tags: [shell, security]
author: cass
excerpt: "ssh read your key, saw the rest of the machine could too, and refused it. The fix is one chmod, unless your key is on a file system where chmod returns 0 and changes nothing."
permalink: /hacks/ssh-private-key-permissions-too-open/
---
I threat-model the walk a private key takes between machines. You generate `id_ed25519` on the laptop. You need it on the other laptop. So it goes through a USB stick, a Slack DM to yourself, the "Downloads" folder, a zip file named `keys-FINAL-2.zip`, and finally into `~/.ssh/` on a box where the shared `guest` account, the backup daemon and the smart TV on the same Samba share can all read it. Along the way the key picked up permission bits from every place it stopped, the way a suitcase picks up stickers.

Then you try to use it, and ssh shouts at you in a box of `@` signs.

```text
SEVERITY:      everyone on the box who isn't you
ATTACK VECTOR: -rw-r--r--, the default mode of a file you copied without thinking about it
EXPLOIT:       cat
```

For once ssh is the most paranoid thing in the room, and I approve. This piece covers what it checks, the one command that fixes it, and the places where that command returns success and changes nothing at all. The tip comes from it-journey.dev's [Security Specialist quest report](https://it-journey.dev/quest-reports/2026-07-12-security-specialist-1000/). If you want the background on permission bits, read [chmod 644 and 755, never 777](/hacks/chmod-644-755-never-777/) first. If your whole home directory worries you, [threat-model your dotfiles](/hacks/threat-model-your-dotfiles/) covers that.

Everything below ran on OpenSSH 9.6p1 (Ubuntu) against a local `sshd`, using a throwaway ed25519 key made for this article. The key has since been deleted and removed from `authorized_keys`, because I'm not going to write a whole article about key hygiene and then leave a test key authorized on the box. The one exception is the native-Windows section, which I couldn't run. It's labeled as such.

## The refusal, reproduced

Make a throwaway key, authorize it, and give it the permissions a careless `cp` or an unzip would give it. I used a small `ssh -F cfg` file so the command stays readable. It points `box` at `127.0.0.1` with `IdentityFile /tmp/demo/throwaway_ed25519`, `IdentitiesOnly yes` and `BatchMode yes`, so ssh can't quietly fall back to some other key or prompt for a password:

```console
$ chmod 644 throwaway_ed25519
$ ssh -F cfg box whoami; echo "rc=$?"
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Permissions 0644 for '/tmp/demo/throwaway_ed25519' are too open.
It is required that your private key files are NOT accessible by others.
This private key will be ignored.
Load key "/tmp/demo/throwaway_ed25519": bad permissions
runner@127.0.0.1: Permission denied (publickey,password).
rc=255
```

Read the last line carefully, because it's the one that wastes your afternoon. The real error is `This private key will be ignored`. The server never saw the key, so it says `Permission denied (publickey)`, which looks like the *server* rejected you. It didn't. Your own client refused to use the key. If you only read the last line, you'll spend an hour checking `authorized_keys` on a server that did nothing wrong.

One correction to the advice I started from: ssh doesn't fail before it touches the network. In an earlier run with a fresh `known_hosts`, the first line of output was `Warning: Permanently added '127.0.0.1' (ED25519) to the list of known hosts.`, *then* the key warning. The client connects, gets to authentication, and only then loads the key. For a check that never leaves the machine, use `ssh-keygen -y`, which loads the private key to print its public half and runs the same permission check:

```console
$ ssh-keygen -y -f throwaway_ed25519 >/dev/null
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Permissions 0644 for 'throwaway_ed25519' are too open.
It is required that your private key files are NOT accessible by others.
This private key will be ignored.
Load key "throwaway_ed25519": bad permissions
```

## What ssh actually checks

I ran a fresh copy of the key at seven different modes through `ssh-keygen -y` to find where ssh draws the line:

```console
$ for m in 600 400 700 640 604 660 444; do ...
600 loads
400 loads
700 loads
640 REFUSED
604 REFUSED
660 REFUSED
444 REFUSED
```

The rule is about who *else* can read the file. Any group or other bit set, even read-only (`640`, `604`, `444`), gets refused. The owner's bits don't matter: `600`, `400` and even an executable `700` all load. So `0444`, "read-only for everyone", fails. The problem was never that someone could change the key. It's that someone else could read it.

Now the escalation, because that's my job. The check only applies to keys **you own**. I copied the key, made root the owner, set it to `644` so the whole machine could read it, and ssh took it without complaint:

```console
$ ls -l r
-rw-r--r-- 1 root root 399 Oct 30 22:43 r
$ ssh-keygen -y -f r >/dev/null && echo "root-owned 644: loads"
root-owned 644: loads
```

That isn't a bug. ssh is asking "did *you* leave your key lying around?", not "is this file safe?". The refusal is a seatbelt chime, not an audit. Mitigation 3 below is the audit.

## The three mitigations, ranked

### 1. `chmod 600` the private key, then prove it loads

```console
$ chmod 600 throwaway_ed25519
$ ssh -F cfg box whoami; echo "rc=$?"
runner
rc=0
```

You'll know it worked when `stat -c '%a' your_key` prints `600` (or `400`) and `ssh-keygen -y -f your_key >/dev/null` prints nothing and exits 0. `600` lets you rewrite the file later (to add a passphrase with `ssh-keygen -p`, say). `400` is fine if you never will. The `.pub` file can stay `644`: I left the public key world-readable during the successful login above, and ssh didn't mind, because public keys are meant to be read. Don't run `chmod 600 ~/.ssh/*` "to be safe" and then wonder why some other tool can't read your public keys.

### 2. Keep the key on a file system that stores permission bits

This is the trap in the title. I formatted a 16 MB image as FAT (the file system on most USB sticks), mounted it the way a desktop would, put the key on it and ran the fix:

```console
$ cp throwaway_ed25519 usb/id_ed25519
$ chmod 600 usb/id_ed25519; echo "chmod rc=$?"
chmod rc=0
$ stat -c '%a %n' usb/id_ed25519
755 usb/id_ed25519
$ ssh-keygen -y -f usb/id_ed25519 >/dev/null
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Permissions 0755 for 'usb/id_ed25519' are too open.
It is required that your private key files are NOT accessible by others.
This private key will be ignored.
Load key "usb/id_ed25519": bad permissions
```

`chmod` exited **0**, printed no error, and the mode is still `755`. FAT has nowhere to store Unix permission bits, so the mount options decide every file's mode and `chmod` does nothing. A script that runs `chmod 600 "$key" && ssh ...` gets a green light from the first command and a refusal from the second.

You can spot the problem by asking what file system the key is on:

```console
$ stat -f -c %T usb .
msdos
ext2/ext3
```

The fix is to move the key, not to fight the mount. `install` copies the file and sets the mode in one step, so the key is never readable by others, even for a moment:

```console
$ install -m 600 usb/id_ed25519 keys/id_ed25519
$ stat -c '%a %n' keys/id_ed25519; ssh-keygen -y -f keys/id_ed25519 >/dev/null && echo loads
600 keys/id_ed25519
loads
```

In real life that destination is `~/.ssh/`, created with `mkdir -m 700`. **WSL users, this is your problem too:** Microsoft's [WSL file-permissions docs](https://learn.microsoft.com/en-us/windows/wsl/file-permissions) say that files under `/mnt/c` get the same permission bits for user, group and other by default. Without the `metadata` mount option, `chmod` only toggles the Windows read-only attribute. I didn't have a WSL machine to test on, so that part comes from the docs, not from me. But it's the same fix as the FAT stick: keep the key in your Linux home (`~/.ssh`), not on `/mnt/c`.

### 3. Sweep the whole `~/.ssh`, not only the key that complained

ssh only complains about the key it's trying to use right now. That `aws-prod.pem` you copied in last spring and haven't used since has been readable by everyone this whole time. I pointed `HOME` at a throwaway directory holding one good key and one bad one, and ran a check that lists every private key anyone besides the owner can read:

```console
$ find ~/.ssh -type f ! -name '*.pub' -perm /077 -exec stat -c '%a %U %n' {} +
644 runner /tmp/sshk/fh/.ssh/aws-prod.pem
$ find ~/.ssh -maxdepth 0 -perm /077 -printf 'dir %m %p\n'
dir 755 /tmp/sshk/fh/.ssh
```

Fix both, run the same two commands again, and you'll know it worked when they print nothing:

```console
$ chmod 600 ~/.ssh/aws-prod.pem; chmod 700 ~/.ssh
$ find ~/.ssh -type f ! -name '*.pub' -perm /077 -exec stat -c '%a %U %n' {} +
$ find ~/.ssh -maxdepth 0 -perm /077 -printf 'dir %m %p\n'
```

The `find` doesn't care who owns the file, so it also catches the root-owned `644` key that ssh let through. (`known_hosts`, `config` and `authorized_keys` show up too, because they don't end in `.pub`. Tightening them to `600` costs nothing.)

## On native Windows, chmod is the wrong tool (not run here)

**Unlike everything above, I did not run this section.** My test machine is Linux, and Linux doesn't have NTFS access control lists (ACLs). On native Windows, an NTFS ACL decides who can read a file, not Unix permission bits, so a `chmod 600` from Git Bash doesn't fix this. OpenSSH for Windows checks the key's ACL instead, and a key in a folder that passes permissions down to its files (`/inheritance`) can carry access for users other than you. The tool is `icacls`. Per Microsoft's [icacls reference](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/icacls), `/inheritance:r` removes the inherited entries and `/grant:r` *replaces* (rather than adds to) the explicit grants. Microsoft's own [OpenSSH key-management guide](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement) uses that same `/inheritance:r` + `/grant` pattern to lock down `administrators_authorized_keys`. Applied to your private key in PowerShell, that's:

```powershell
# lh:norun — Windows-only; NOT executed for this article (no Windows box available)
icacls $env:USERPROFILE\.ssh\id_ed25519 /inheritance:r
icacls $env:USERPROFILE\.ssh\id_ed25519 /grant:r "$($env:USERNAME):(R)"
icacls $env:USERPROFILE\.ssh\id_ed25519
```

The last line lists the ACL, so you can check that your account is the only one on it. If you try this, a correction in the comments is welcome. I'd rather be corrected than confidently wrong about an OS I didn't touch.

## When this goes wrong

- **You fixed the client and the server still says no.** The server runs a check of its own. With `StrictModes yes` (the default), `sshd` refused my key once `~/.ssh/authorized_keys` on the server was `666`, and the server log said `Authentication refused: bad ownership or modes for file /home/runner/.ssh/authorized_keys`. Odd detail: Ubuntu's sshd *accepted* a group-writable `664`, because this machine's user has a private group with only that user in it. Don't count on that. Set it to `600`.
- **chmod "worked" and nothing changed.** Run `stat -f -c %T` on the key's folder. `msdos`, `vfat`, `exfat` or a network share means mitigation 2.
- **It's a root-owned key in a deploy script.** ssh won't warn you, so mitigation 3 is your only check.

I've stopped worrying about the smart TV. The `aws-prod.pem` that sat at `644` for a year got me to run the sweep.
