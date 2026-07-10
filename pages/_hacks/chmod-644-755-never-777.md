---
title: "chmod 644 and 755, never 777: the permission bits that decide what's safe to run"
description: "Read an ls -l line as a type char plus three rwx triples, set 644 for data and 755 for scripts, and skip the 777 that hands the whole box the keys."
date: 2026-07-10
collection: hacks
author: claude
excerpt: "The 777 that 'fixes' a permissions error is a footgun with a delay on it. Here's how to read the bits and set them on purpose instead."
tags: [bash, shell, linux, permissions]
---

Something won't run. You've seen the fix on a hundred forum posts: `chmod 777`,
and the error goes away. It always works, because `777` means *everyone can do
everything*, so of course the check passes. It's the permissions equivalent of
fixing a fuse by replacing it with a nail.

The bits aren't decoration. They decide who can read your config, who can run
your script, and who can quietly rewrite either one. Two numbers cover almost
everything you'll ever set — `644` for data, `755` for programs — and once you
can read an `ls -l` line, you'll never reach for `777` by reflex again.

This is the same "look at the bits before you trust the file" instinct the
[Bashcrawl "Armoury" quest](https://it-journey.dev/quests/0000/armoury/) drills
in when it hands you a pile of scripts and asks which ones are safe to pick up.

## Read the line before you change it

`ls -l` prints a ten-character mode string. It looks like line noise until you
chunk it: **one** type character, then **three** groups of `rwx`.

```console
$ ls -l settings.conf deploy.sh
-rw-r--r-- 1 runner runner 12 Jul 10 10:12 settings.conf
-rwxr-xr-x 1 runner runner 45 Jul 10 10:12 deploy.sh
```

Take `-rwxr-xr-x` and split it:

```
-      rwx      r-x      r-x
type   owner    group    other
```

- The first char is the **type**: `-` a regular file, `d` a directory, `l` a symlink.
- Then **owner** (you), **group**, and **other** (everyone else on the machine),
  each a `read` / `write` / `execute` triple. A letter means yes, a `-` means no.

So `-rwxr-xr-x` reads: regular file; owner can read, write, and run it; group and
everyone else can read and run it but not change it. That's a script you're happy
to share. And `-rw-r--r--` reads: regular file; owner can read and write; everyone
else can only read. That's data.

## The two numbers, and where they come from

Each `rwx` triple is a digit you build by adding up **read = 4, write = 2,
execute = 1**. `rw-` is `4+2 = 6`. `r-x` is `4+1 = 5`. `r--` is `4`. String the
three digits together and you have the octal mode `chmod` wants:

| Symbolic     | Octal | Owner | Group | Other | For                        |
|--------------|-------|-------|-------|-------|----------------------------|
| `-rw-r--r--` | `644` | rw-   | r--   | r--   | data, config, docs         |
| `-rwxr-xr-x` | `755` | rwx   | r-x   | r-x   | scripts, binaries          |
| `-rwxrwxrwx` | `777` | rwx   | rwx   | rwx   | nothing you want to keep    |

Set them on purpose and read the result straight back:

```console
$ chmod 644 settings.conf     # data: you write, everyone reads
$ chmod 755 deploy.sh         # script: everyone runs, only you edit
$ stat -c '%A %a %n' settings.conf deploy.sh
-rw-r--r-- 644 settings.conf
-rwxr-xr-x 755 deploy.sh
```

**You'll know it worked when** `stat` (or `ls -l`) shows an `x` in the owner
triple of your script and *no* `x` anywhere on your data file. Config that can't
be executed can't be tricked into being executed.

Here's the whole thing in one script. It's opted into our test harness
(`lh:run`), so it runs on every build in a locked-down, no-network sandbox as a
non-root user — the output you're reading is the output that passed:

```bash lh:run
#!/usr/bin/env bash
set -euo pipefail
tmp=$(mktemp -d); cd "$tmp"

# A data file and a script, set on purpose:
echo "listen_port: 8080" > settings.conf
printf '#!/usr/bin/env bash\necho "deploy ran as $(id -un)"\n' > deploy.sh
chmod 644 settings.conf   # rw-r--r-- : read for all, write for you
chmod 755 deploy.sh       # rwxr-xr-x : everyone runs it, only you edit it

echo "==> the two modes, read straight off the file:"
stat -c '%A %a  %n' settings.conf deploy.sh

echo
echo "==> run the script the way that works (./ prefix):"
./deploy.sh

echo
echo '==> the classic trip-up: no ./, because . is not on PATH'
if deploy.sh 2>/dev/null; then
  echo "UNEXPECTED: bare name resolved"; exit 1
else
  echo "bare \"deploy.sh\" -> not found (exit $?), as expected"
fi

echo
echo "==> prove data stayed non-executable (644 has no x bit):"
if [ -x settings.conf ]; then echo "UNEXPECTED: data is executable"; exit 1; fi
echo "OK: settings.conf is not executable, deploy.sh is"
```

## Why not 777

`777` grants write to **other** — every account on the machine. On a shared box,
a build server, or anything exposed to the internet, that means anyone (or
anything) that lands a foothold can overwrite the file:

```console
$ chmod 777 world.txt
$ stat -c '%A %a  %n' world.txt
-rwxrwxrwx 777  world.txt
```

Those two `w` bits after the owner's are the problem. A world-writable *script*
is worse still: something the whole system can both edit and run is a swap-in
waiting to happen — replace the contents, wait for the next person (or cron job)
to execute it, and your code runs as them. `755` gives everyone the ability to
*run* your script while reserving *changing* it to you. That gap is the entire
point.

## The first footgun: the missing `./`

`755` was correct and the script still "won't run":

```console
$ deploy.sh
bash: deploy.sh: command not found
$ ./deploy.sh
deploy ran as runner
```

Nothing is wrong with the permissions. When you type a bare word, the shell only
searches the directories on your `PATH`, and — for good security reasons — your
current directory is **not** on it. `./deploy.sh` gives an explicit path, so the
shell stops searching and runs *that* file. The executable bit lets a file run;
the `./` tells the shell *where the file is*. You need both, and they fail in
different ways.

## The second footgun: `+x` on a file with no shebang

You `chmod +x` a script and it *still* misbehaves — but not always the same way,
which is what makes this one sneaky. The `x` bit says "you may execute this"; it
does **not** say *which interpreter* runs it. That's the shebang's job — the
`#!/usr/bin/env bash` first line. Leave it off and it depends entirely on *who*
tries to run the file.

Ask the kernel to execute it directly (what happens when a *program*, not your
shell, calls `execve` on it — a cron entry, another language's exec, a service
manager):

```console
$ printf 'arr=(a b c); echo "count: ${#arr[@]}"\n' > arr.sh
$ chmod +x arr.sh
$ python3 -c 'import os; os.execv("./arr.sh", ["./arr.sh"])'
OSError: [Errno 8] Exec format error
```

`Exec format error` is the kernel saying "this has no `#!` and isn't a binary I
recognize — I don't know what to run it *with*." Now the confusing part: from an
**interactive shell**, the same file often runs anyway, because `bash` catches
that error and quietly retries the script in a subshell of itself. So it looks
fine on your terminal and breaks in cron. And when the fallback shell is a
stricter one, the mask comes off — this is a `/bin/sh` (dash) line, exactly what
a plain cron job gets:

```console
$ dash ./arr.sh
./arr.sh: 1: Syntax error: "(" unexpected
```

The bash array your interactive shell ran without complaint is a syntax error to
dash. Add the shebang and the kernel stops guessing — it runs the interpreter you
named, everywhere:

```console
$ printf '#!/usr/bin/env bash\narr=(a b c); echo "count: ${#arr[@]}"\n' > arr.sh
$ chmod +x arr.sh
$ ./arr.sh
count: 3
```

The executable bit and the shebang are two independent switches. `chmod +x`
grants permission to run; the shebang decides what runs it. "It works on my
machine" is very often the gap between the two.

## When this goes wrong

- **You `chmod -R 777` a whole directory to "fix" one file.** Now every data
  file is executable and every file is world-writable, and you've hidden the one
  real problem under a hundred new ones. Set the one file, or use `find . -type f
  -exec chmod 644 {} +` and `find . -type d -exec chmod 755 {} +` to give files
  and directories their proper defaults. (Directories need `x` — on a directory
  it means "may enter / list", not "may run".)
- **You edited someone else's file and can't figure out why.** As a regular user,
  the bits are enforced; as `root`, they're almost entirely ignored, so a script
  that "works when I sudo it" may be failing on permissions for everyone else.
  Test as the user who'll actually run it.
- **A file has the right bits and still won't read.** Check the *directory's*
  permissions too — you can't reach a perfectly-readable file inside a directory
  you have no `x` (enter) bit on.

Two numbers, `644` and `755`, cover the vast majority of what you set by hand.
Reach for anything with a `7` in the "other" slot only when you can say out loud
who "other" is and why they get to write. Usually you can't — which is the answer.

---

*Real captured output above, from `GNU bash 5.2.21`, `coreutils 9.4`, and
`dash` as `/bin/sh` on Ubuntu 24.04. The `lh:run` block is executed by the
site's build in a non-root, no-network sandbox; the `console` blocks are
transcripts of the same commands run in a shell.*
