---
title: "moreutils: the toolbox whose sponge soaks up an empty pipe and saves it anyway"
description: "moreutils' sponge fixes the file > file truncation, then writes an empty result over your file and quietly forks your hard links. Threat-modeled, straced."
date: 2026-10-27
preview: /images/previews/moreutils-the-toolbox-whose-sponge-soaks-up-an-emp.svg
categories: [Tools]
tags: [files, system]
author: cass
verdict: "Use it: sponge, ifne, chronic and ts earn the install. But sponge writes whatever the pipe hands it, including nothing, so guard it, and know which of its two write paths your file is on before you sponge a secret."
excerpt: "A bag of tiny Unix tools that fill the gaps coreutils left: sponge, ifne, chronic, ts, vidir. I straced the one everybody loves and found it has two different ways of writing your file, and neither one checks whether the pipe was empty."
permalink: /tools/moreutils-honest-review/
---
**Verdict: use it. [moreutils](https://joeyh.name/code/moreutils/) is a grab bag of small Unix tools that should have shipped with the system and didn't, and four of them (`sponge`, `ifne`, `chronic`, `ts`) belong in your fingers. It's also free, packaged everywhere, and maintained by one person (Joey Hess) who has been at it since 2006. Now the threat model, because the most popular tool in the bag has a habit of writing exactly what you told it to.** I have no relationship with moreutils or its author. It's GPL, nobody paid me, and I distrust free things on principle, which is why I ran `strace` on it.

Every product that promises to edit a file "in place" is a file-deletion tool that hasn't been tested on your worst day. `sponge` is one of those. It's a very good one. I trust it the way I trust a chainsaw: completely, and from a respectful distance.

Everything below ran for real on Ubuntu 24.04.5, `moreutils 0.69-1` from apt, in a throwaway directory. The secrets are fake. The behavior is not.

## What's in the bag

```console
$ dpkg -L moreutils | grep bin/
/usr/bin/chronic
/usr/bin/combine
/usr/bin/errno
/usr/bin/ifdata
/usr/bin/ifne
/usr/bin/isutf8
/usr/bin/lckdo
/usr/bin/mispipe
/usr/bin/parallel
diverted by parallel to: /usr/bin/parallel.moreutils
/usr/bin/pee
/usr/bin/sponge
/usr/bin/ts
/usr/bin/vidir
/usr/bin/vipe
/usr/bin/zrun
```

Read that `parallel` line twice. moreutils ships a small program called `parallel`. So does GNU, and GNU's is the one everybody's tutorials mean. On Debian and Ubuntu the GNU `parallel` package *diverts* moreutils' copy aside, so on my box `parallel` is GNU and the moreutils one lives at `parallel.moreutils`:

```console
$ parallel --version | head -1
GNU parallel 20231122
$ parallel.moreutils -j 2 echo -- a b
a
b
```

`SEVERITY: your Stack Overflow answer. ATTACK VECTOR: two different programs answering to the same name, with different flags, depending on which packages the box happened to install.` Not a security hole. A "works on my machine" generator. Check `parallel --version` before you trust a `parallel` one-liner.

## sponge: the reason you install it

Here's the classic shell footgun. You want to drop a line from a file, so you write the obvious thing:

```console
$ printf 'alice:x\nbob:x\ncarol:x\n' > users.txt
$ grep -v bob users.txt > users.txt
grep: users.txt: input file is also the output
$ wc -c users.txt
0 users.txt
```

The shell truncates `users.txt` before `grep` ever opens it. GNU grep even notices and complains, and the file is still zero bytes, because the damage was done before grep got a vote. `sponge` fixes it by soaking up all of stdin first and only then writing the file:

```console
$ printf 'alice:x\nbob:x\ncarol:x\n' > users.txt
$ grep -v bob users.txt | sponge users.txt
$ cat users.txt
alice:x
carol:x
```

That's the whole pitch, and it's a good one. Convenience delivered. Which, in my line of work, means an attack surface with a nicer font.

## Leak #1: sponge saves an empty pipe as faithfully as a full one

`sponge` waits for the pipe to finish. It does not ask how the pipe finished. Search for a user who isn't there:

```console
$ grep mallory users.txt | sponge users.txt
$ echo "grep exit=${PIPESTATUS[0]}"
grep exit=1
$ wc -c users.txt
0 users.txt
```

grep found nothing, exited 1, wrote nothing to stdout, and `sponge` dutifully replaced your file with that nothing. "But I use `set -o pipefail`," you say, like a responsible adult:

```console
$ printf 'alice:x\nbob:x\n' > users.txt
$ set -o pipefail
$ grep mallory users.txt | sponge users.txt
$ echo "pipeline exit=$?"
pipeline exit=1
$ wc -c users.txt
0 users.txt
```

`pipefail` changes what the pipeline *reports*. It doesn't stop the pipeline. Every stage still runs, so `sponge` still writes and you get a red exit code next to an empty file. `SEVERITY: your /etc/hosts. ATTACK VECTOR: a typo in a sed pattern at 4:58 on a Friday.` I'm not saying a nation-state will typo your regex on purpose. I'm saying they won't have to.

## Leak #2: sponge has two ways of writing your file, and they disagree

This is where it gets interesting enough that I ran `strace`. Rewriting a `0600` secrets file in my home directory:

```console
$ printf 'SECRET=hunter2\n' > .env; chmod 600 .env; ln -f .env hardlink.env
$ stat -c '%a %i %h' .env
600 9437238 2
$ strace -f -e trace=openat,rename,chmod,unlink -o st.txt sh -c "sed 's/2/3/' .env | sponge .env"
$ grep -E 'sponge|\.env|chmod|rename' st.txt
2736  openat(AT_FDCWD, "/tmp/sponge.j4PS9p", O_RDWR|O_CREAT|O_EXCL, 0600) = 3
2735  openat(AT_FDCWD, ".env", O_RDONLY) = 3
2736  chmod("/tmp/sponge.j4PS9p", 0100600) = 0
2736  rename("/tmp/sponge.j4PS9p", ".env" <unfinished ...>
2736  <... rename resumed>)             = 0
$ stat -c '%a %i %h' .env
600 19145 1
$ cat .env hardlink.env
SECRET=hunter3
SECRET=hunter2
```

Good news first: the temp file is created `O_EXCL` and mode `0600`, sponge copies your file's mode onto it, and the temp file is gone afterwards. Nothing sat world-readable in `/tmp`. Credit where due.

Now the part nobody threat-models. On this box `/tmp` and my home directory are the same filesystem, so sponge *renamed* the temp file over `.env`. That's a brand-new inode (9437238 became 19145), and the link count dropped from 2 to 1. The hard link I made earlier still points at the old inode, which still holds `hunter2`. You "rotated" the secret. A second name for the old secret is sitting right next to it. `SEVERITY: the backup script that hard-links your config dir. ATTACK VECTOR: you, believing the old value is gone.`

Then I mounted a tmpfs so the target sat on a *different* filesystem from `/tmp`, rebuilt the same `.env` and hard link there, and ran the identical `strace` (trace output, filtered the same way):

```console
2755  openat(AT_FDCWD, "/tmp/sponge.iXRgqA", O_RDWR|O_CREAT|O_EXCL, 0600) = 3
2754  openat(AT_FDCWD, ".env", O_RDONLY) = 3
2755  chmod("/tmp/sponge.iXRgqA", 0100600) = 0
2755  rename("/tmp/sponge.iXRgqA", ".env" <unfinished ...>
2755  <... rename resumed>)             = -1 EXDEV (Invalid cross-device link)
2755  openat(AT_FDCWD, ".env", O_WRONLY|O_CREAT|O_TRUNC, 0666) = 4
2755  unlink("/tmp/sponge.iXRgqA")      = 0
$ stat -c '%a %i %h' .env
600 2 2
$ cat .env hardlink.env
SECRET=hunter3
SECRET=hunter3
```

The rename fails with `EXDEV`, so sponge falls back to opening your file `O_TRUNC` and copying the bytes in. Same inode, both links updated. Also not atomic: there's a window where `.env` is truncated and half-written, and a crash in that window leaves you with a fragment. So whether sponge forks your hard links or briefly zeroes your file depends on where your `/tmp` is mounted. The same command does two different things on two machines, and neither of them prints anything.

Is this a vulnerability? No. It's a reasonable tool doing reasonable things, and I won't pretend otherwise. It's just not one behavior, and "in place" is a promise the filesystem gets the final say on.

## The rest of the bag, briefly

**`ifne`** runs a command only if stdin is non-empty. It's the cheapest guard for Leak #1 (see mitigations).

**`chronic`** runs a command and swallows its output unless it fails, which is what cron mail always wanted to be:

```console
$ chronic sh -c 'echo noisy chatter; exit 0'; echo "exit=$?"
exit=0
$ chronic sh -c 'echo noisy chatter; echo boom >&2; exit 3'; echo "exit=$?"
noisy chatter
boom
exit=3
$ chronic sh -c 'echo warning: disk 99% full >&2; exit 0'; echo "exit=$?"
exit=0
```

Look at the third one. A script that *warns* on stderr and exits 0 gets silenced completely. Convenience feature, meet the disk that filled up quietly. Mitigation #3 is the fix.

**`ts`** timestamps every line of stdin. `-i` gives you the gap since the previous line, which is a cheap profiler for a slow script:

```console
$ printf 'one\ntwo\n' | ts '%Y-%m-%dT%H:%M:%S'
2026-10-27T22:50:19 one
2026-10-27T22:50:19 two
$ (echo a; sleep 1; echo b) | ts -i '%.s'
0.000004 a
0.990819 b
```

**`mispipe`** returns the exit status of the *first* command in a two-command pipe, for shells without `pipefail`: `false | true` exits 0, `mispipe false true` exits 1. **`errno`** turns the number in an error message into words (`errno 13` → `EACCES 13 Permission denied`), and I use it more than I'll admit.

**`vidir`** opens a directory listing in your `$EDITOR` so you can rename files by editing text. Delete a line, and you delete the file. I scripted the "editor" to do what a tired thumb does, remove one line:

```console
$ touch keep.txt prod.db notes.md
$ printf '#!/bin/sh\nsed -i "/prod.db/d" "$1"\n' > /tmp/mu/ed.sh; chmod +x /tmp/mu/ed.sh
$ EDITOR=/tmp/mu/ed.sh vidir --verbose .
removed './prod.db'
$ ls
keep.txt
notes.md
```

No confirmation, no trash. `dd` in vim is now `rm`. `SEVERITY: prod.db. ATTACK VECTOR: muscle memory.` It's a lovely bulk-rename tool. Go in knowing it's also a delete tool that looks like a text file.

## The three mitigations that matter

Ranked, each one run above or below, none of them "be more careful."

**1. Don't let anything write a result you haven't checked: temp file, test, then rename.** This is #1 because it closes Leak #1 for good, and it's how sponge's own fast path works anyway, minus the blind trust. Write to a sibling file and only `mv` it into place if the command succeeded:

```console
$ printf 'alice:x\nbob:x\n' > users.txt
$ grep mallory users.txt > users.txt.new && mv users.txt.new users.txt; echo "exit=$?"
exit=1
$ cat users.txt
alice:x
bob:x
$ grep -v bob users.txt > users.txt.new && mv users.txt.new users.txt; echo "exit=$?"
exit=0
$ cat users.txt
alice:x
```

The failed run left the original alone. It also left an empty `users.txt.new` behind, so clean that up (or `trap` it in a script). Because the temp file sits next to the target, the `mv` is a same-filesystem rename: atomic, every time, no matter where `/tmp` lives. If you'd still rather keep sponge for a quick interactive edit, `ifne sponge` is the one-word guard. It refuses to write an empty pipe:

```console
$ printf 'alice:x\nbob:x\n' > users.txt
$ grep mallory users.txt | ifne sponge users.txt; echo "exit=$?"
exit=0
$ wc -c users.txt
14 users.txt
```

Know its limit: it blocks *empty*, not *wrong*, and it also blocks the time you really did mean to empty the file.

**2. Before you rewrite a secret in place, count its names.** Leak #2 only bites files with more than one hard link, and that takes two seconds to check:

```console
$ stat -c '%h %n' .env
2 .env
$ find . -samefile .env
./backup.env
./.env
```

A link count above 1 means sponge (or `sed -i`, or your editor's save-by-rename) may update one name and strand the old secret under the other. Remove the extra links first, or edit the file through each name you care about. And if the secret was worth rotating, rotate it at the source too. A stale copy on disk is a leak whether or not you remember making it.

**3. Run cron jobs under `chronic -e`, not bare `chronic`.** `-e` treats any stderr output as a failure, so the warning-and-exit-0 script from above stops being invisible:

```console
$ chronic -e sh -c 'echo warning: disk 99% full >&2; exit 0'; echo "exit=$?"
warning: disk 99% full
exit=2
```

The warning shows up and the exit code becomes 2. Per `chronic`'s own docs that means "the command returned 0 but printed to stderr," so your monitoring can tell it apart from a real crash. Noisy scripts that chatter on stderr every run will now page you every run, which is fair: fix the script, not the alarm.

## So, install it?

Yes. `apt install moreutils` and you get a dozen small tools, four of which you'll use weekly. `sponge` really does fix the `file > file` footgun, `chronic` really does make cron mail bearable, and `ts` and `errno` are tiny joys. The free alternative is writing the temp-file-and-rename dance by hand every time, and mitigation #1 is literally that dance, so you'll end up knowing both.

Just remember what "in place" means. sponge writes whatever the pipe gave it, including nothing, through one of two code paths your filesystem picks for you. I trust it. I trust it because I straced it, not instead of doing so. Do the same to this review. I would.
