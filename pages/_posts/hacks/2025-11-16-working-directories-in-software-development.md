---
title: "Stop 'works on my machine': anchor every script to its own directory"
description: "Why your build script breaks when run from the wrong folder, the cd that fails silently and keeps going, and the four-line anchor that fixes both."
date: 2025-11-16
categories: [Hacks]
tags: [shell, ci-cd]
author: amr
excerpt: "A script that works from the repo root and explodes from a subdirectory isn't flaky — it's reading the wrong path. Pin it to its own location instead."
preview: /images/previews/section-hacks.svg
permalink: /hacks/working-directories-in-software-development/
---
Someone says your build script is broken. It works for you. You watch them run it and it dies on a file that is right there. Nothing changed. The script is the same, the file is the same, the machine is — well, that's the whole problem. The machine is *their* machine, and they ran it from a different folder than you did.

Your script doesn't break because of the machine. It breaks because it assumes it knows where it's standing, and the caller decides that, not the script.

The fix is four lines that pin the script to its own location so it stops caring where you launched it from. Here's the failure first, then the four lines.

## The part where it broke

Here's a project laid out the normal way: a `scripts/` folder, a `config/` folder, and a build script that reads the config with a relative path.

```bash
# scripts/build.sh — the naive version
#!/usr/bin/env bash
echo "reading config..."
cat config/settings.txt
```

`cat config/settings.txt` is a relative path. The shell resolves it against the current working directory — wherever your process *thinks it is* — not against where the script file lives. Those are usually the same folder right up until they aren't.

We ran it two ways. Real output:

```console
$ cd project && ./scripts/build.sh
reading config...
mode=production

$ cd project/scripts && ./build.sh
reading config...
cat: config/settings.txt: No such file or directory
exit code: 1
```

Same script, same file on disk, two different working directories. From the repo root, `config/settings.txt` resolves to `project/config/settings.txt` and works. From inside `scripts/`, it resolves to `project/scripts/config/settings.txt`, which doesn't exist, and the script dies.

This is the entire "works on my machine" bug in one example. You always run it from the root. The other person `cd`s in first. The relative path means something different to each of you.

## The four lines

A script can find out where its own file lives, regardless of where it was called from. Once it knows that, it can build every other path from that fixed point instead of trusting the caller's current directory.

```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "script dir: $SCRIPT_DIR"
echo "repo root:  $REPO_ROOT"
echo "reading config..."
cat "$REPO_ROOT/config/settings.txt"
```

Read the third line inside-out:

- `${BASH_SOURCE[0]}` is the path to the script file itself — the file being read, not the command being run.
- `dirname` strips that down to the folder the script lives in.
- `cd "$(...)" && pwd` turns whatever that was (could be relative, could have `../` in it) into one clean absolute path.

`SCRIPT_DIR` now holds the script's own folder as an absolute path. `REPO_ROOT` is one level up, also absolute. Every path you build from those is anchored to the repo, not to the caller's whim.

Here's the same `build.sh` fixed and run from three different places. Real output (the temp path is collapsed to `/work` for readability):

```console
$ cd project && ./scripts/build.sh
script dir: /work/project/scripts
repo root:  /work/project
reading config...
mode=production

$ cd project/scripts && ./build.sh
script dir: /work/project/scripts
repo root:  /work/project
reading config...
mode=production

$ cd / && /work/project/scripts/build.sh
script dir: /work/project/scripts
repo root:  /work/project
reading config...
mode=production
```

Repo root, subdirectory, absolute path from the filesystem root — same `SCRIPT_DIR`, same `REPO_ROOT`, same config read, every time. That's the tell: **`SCRIPT_DIR` prints the same absolute path no matter where you launched the script.** If it changes when you `cd` somewhere else first, the anchor isn't anchored — you probably used `$0` or `$PWD` instead of `${BASH_SOURCE[0]}`.

## The other failure, hiding inside the first

There's a second bug that travels with this one, and it's worse because it doesn't error out — it succeeds while doing the wrong thing.

Plenty of "fix it" advice tells you to `cd` to the right place at the top of the script and be done with it:

```bash
#!/usr/bin/env bash
cd ..               # go up to the repo root, supposedly
rm -rf build
mkdir build
```

A `cd` can *fail* — wrong relative target, a directory that got moved, a typo. And a failed `cd` in a script with no `set -e` is non-fatal. The shell prints a complaint to stderr and the script keeps running, still standing in the old directory.

We ran a version of that. The real output:

```console
$ bash demo.sh
demo.sh: line 3: cd: /nonexistent-dir-12345: No such file or directory
pwd is now: /var/folders/lj/.../T/tmp.ciLn30hjhK
about to rm -rf build in THIS directory...
exit code: 0
```

Look at the exit code. It's `0`. The `cd` failed, the script announced it was about to `rm -rf build`, and as far as the shell is concerned everything went fine. The next line in a real script does the destructive thing — in the directory you never left, not the one you meant to be in.

The same script with `set -euo pipefail` at the top turns that failed `cd` into a hard stop. Real output:

```console
$ bash demo2.sh
demo2.sh: line 3: cd: /nonexistent-dir-12345: No such file or directory
exit code: 1
```

Now it exits `1` and never reaches the `rm`. That's why the anchor block opens with `set -euo pipefail`: not as decoration, but because a script that moves around the filesystem has to die the instant a move fails, before the next line acts on a wrong assumption.

## You can also not move at all

The cleanest `cd` is the one you never write. A lot of tools take a directory flag, so you point them at the work instead of walking the script over to it. We verified one of these on this host:

```console
$ git -C /work/repo log --oneline
f5d728f init
```

`git -C /path/to/repo` runs git against that repo without anyone `cd`-ing into it — real output above, run against a throwaway repo. The same idea shows up across the toolbox:

```bash
git -C /path/to/repo status
pytest path/to/tests
npm --prefix frontend test
make -C build
```

Each of these does the directory-changing for you, scoped to one command, with no `cd` left lying around to leak into the next line. When a tool offers the flag, prefer it. When it doesn't, anchor the script.

## When this still goes wrong

A few honest edges.

`${BASH_SOURCE[0]}` is a bash thing. In plain POSIX `sh`, that array doesn't exist and you're stuck with `$0`, which holds however the script was *invoked* — fine for an absolute or relative path, useless if the script was found on `$PATH`. If your shebang is `#!/usr/bin/env bash`, you're using bash; if it's `#!/bin/sh`, don't reach for `BASH_SOURCE`.

The anchor finds where the script *file* lives, which is not always where the repo root is. The `"$SCRIPT_DIR/.."` assumes the script sits exactly one level under the root. Move the script deeper and that `..` is wrong — better to ask git: `REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"` walks up to the real root from wherever the script lives, as long as it's inside a git repo.

And a symlinked script reports the link's location, not the target's. `${BASH_SOURCE[0]}` doesn't resolve symlinks. If you symlink your build script into `~/bin`, `SCRIPT_DIR` points at `~/bin`, not the repo. If that matters, resolve the link first (`readlink -f` on Linux; macOS's stock `readlink` doesn't take `-f`, which is its own afternoon).

The whole hack is one habit: a script should never trust where it was called from. Pin it to its own location with the four-line block, open with `set -euo pipefail` so a bad move can't slide into the next line, and reach for a tool's `-C`/`--prefix` flag before you write a `cd` at all. Do that and "works on my machine" stops being a thing people say about your scripts, because the machine — and the folder — stop mattering.
