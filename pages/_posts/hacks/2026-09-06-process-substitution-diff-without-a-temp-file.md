---
title: "Diff two commands without a temp file — until <(…) dies in sh and eats the exit code"
description: "Process substitution hands a command's output to diff as a fake file. I broke it three ways: dies under sh, hides the inner exit, and doesn't wait for >(…)."
date: 2026-09-06
preview: /images/previews/diff-two-commands-without-a-temp-file-until-dies-i.svg
categories: [Hacks]
tags: [shell, ci-cd]
author: edge
excerpt: "diff <(sort a) <(sort b) skips the scratch files — a slick trick I then ran to destruction. It dies under /bin/sh, hides the inner command's exit from set -euo pipefail, and doesn't wait for the >(…) side. Every failure below is real captured output."
permalink: /hacks/process-substitution-diff-without-a-temp-file/
---
Someone showed me `diff <(sort a.txt) <(sort b.txt)` the way you'd show off a card trick — no temp files, no cleanup, look ma, one line. It is a genuinely good trick. I have a clipboard and a grudge against tricks that demo clean and page you at 2 a.m., so I spent an afternoon trying to make this one page me. It obliged three times.

The idea to poke at it came from it-journey.dev's [bash complete reference](https://it-journey.dev/notes/cheatsheets/bash-complete-reference/), which lists process substitution in the "handy one-liners" column right next to pipes, as if they were the same safety class. They are not. Every command, exit code, and error string below is real output I captured on bash 5.2.21 with GNU diffutils 3.10, and `/bin/sh` wired to dash 0.5.12 — not a number I hoped for.

## What the trick actually is

`<(command)` runs `command`, connects its stdout to a named pipe, and substitutes the *path to that pipe* into the command line. The outer command opens what looks like a file and reads the inner command's output. No scratch file, no cleanup. Here is the before and after on two word lists:

```console
$ printf 'banana\napple\ncherry\n' > a.txt
$ printf 'cherry\napple\ndate\n'   > b.txt

$ sort a.txt > a.sorted; sort b.txt > b.sorted; diff a.sorted b.sorted; echo "exit=$?"
2d1
< banana
3a3
> date
exit=1

$ diff <(sort a.txt) <(sort b.txt); echo "exit=$?"
2d1
< banana
3a3
> date
exit=1
```

Identical diff, identical exit code, and the second version never littered the directory with `.sorted` files I'd forget to delete. The "file" it hands over is a `/dev/fd` entry pointing at a pipe:

```console
$ echo <(sort a.txt)
/dev/fd/63
$ ls -l <(sort a.txt)
lr-x------ 1 runner runner 64 Sep  6 09:15 /dev/fd/63 -> pipe:[17724]
```

That `-> pipe:` is the whole story of the next three sections. It is not a file. It behaves like one exactly until you lean on it.

## Break #1: the identical line dies under `sh`

This is the one that eats the afternoon, because the code doesn't change — the interpreter does. I put the exact working line in a script and ran it two ways:

```console
$ cat demo.sh
diff <(sort a.txt) <(sort b.txt)

$ bash demo.sh; echo "bash exit=$?"
2d1
< banana
3a3
> date
bash exit=1

$ sh demo.sh; echo "sh exit=$?"
demo.sh: 1: Syntax error: "(" unexpected
sh exit=2
```

Process substitution is a bash/zsh feature, not POSIX. Under dash — which is `/bin/sh` on Debian, Ubuntu, and most CI base images — the `<(` isn't a redirect, it's a syntax error the shell can't even parse. The failure this prevents: you test with `./deploy.sh` (bash, because your login shell is bash), it passes, you add `#!/bin/sh` to the top or a Makefile calls it as `sh deploy.sh`, and now it explodes on a machine you'll swear is "identical." It isn't. The fix is to be explicit about the interpreter:

```console
$ cat fixed.sh
#!/usr/bin/env bash
diff <(sort a.txt) <(sort b.txt) > /dev/null && echo "same" || echo "differ"

$ ./fixed.sh; echo "exit=$?"
differ
exit=0
```

The nitpick with a victim: the shebang only helps when it is *honored*. Call the same file as `sh fixed.sh` and the shebang is ignored — sh is already chosen — and it breaks again:

```console
$ sh fixed.sh; echo "sh exit=$?"
fixed.sh: 2: Syntax error: "(" unexpected
sh exit=2
```

So the rule isn't just "add a bash shebang," it's "add a bash shebang *and* never invoke the script through `sh name`." Both, or neither counts.

## Break #2: the inner command's exit code is invisible

This is the dangerous one, because it fails *silently* under the exact header everyone adds to feel safe. Watch a real pipe and a process substitution do the "same" thing and disagree about whether anything went wrong:

```console
$ cat pipe.sh
#!/usr/bin/env bash
set -euo pipefail
false | wc -l
echo "unreachable"

$ ./pipe.sh; echo "script exit=$?"
0
script exit=1
```

`false | wc -l` trips `pipefail` — `false` failed, so the pipeline fails, and `set -e` kills the script before `echo "unreachable"`. Good. That's the safety you signed up for. Now the process-substitution spelling of the same idea:

```console
$ cat invisible.sh
#!/usr/bin/env bash
set -euo pipefail
echo "before"
lines=$(wc -l < <(false))
echo "wc saw $lines lines, wc exit=$?"
echo "reached the end — set -euo pipefail never noticed 'false' failed"

$ ./invisible.sh; echo "script exit=$?"
before
wc saw 0 lines, wc exit=0
reached the end — set -euo pipefail never noticed 'false' failed
script exit=0
```

`false` failed exactly like before. But its exit status lives inside the substituted process, which the outer command never sees — `wc` was handed an empty stream, counted zero lines, and exited `0`. The whole script exits `0`. `pipefail` covers `|`; it does not cover `<(…)`. So `diff <(sort a.txt) <(curl -s https://api.example.com/data)` where the `curl` 404s doesn't error — it quietly diffs against an empty stream and reports "everything was deleted," and your CI gate goes green on a comparison that never happened. That is the failure this section exists to prevent: a green build that proved nothing.

The fix is to stop hiding the risky command inside the parentheses. Run it on its own line, into a real file, and check `$?` yourself:

```console
$ cat fixB.sh
#!/usr/bin/env bash
set -euo pipefail
tmp=$(mktemp)
if ! false > "$tmp"; then          # 'false' stands in for the command that can fail
  echo "inner command failed (exit nonzero) — caught before diff ran"
  rm -f "$tmp"
  exit 1
fi
diff <(sort a.txt) "$tmp"          # only reached when the inner command succeeded
rm -f "$tmp"

$ ./fixB.sh; echo "script exit=$?"
inner command failed (exit nonzero) — caught before diff ran
script exit=1
```

Yes, that brings back a temp file. That's the point: process substitution is for commands that *can't* fail in a way you care about. The moment the inner command can 404, time out, or run out of disk, you want its exit code, and the only way to get it is to run it where the shell can see it.

## Break #3 (the absurd one that found a real bug): `>(…)` doesn't wait

The mirror form, `>(command)`, is the flashy one — fan one stream out to several consumers at once. It works:

```console
$ seq 1 5 | tee >(wc -l > count.txt) >(gzip > nums.gz) > /dev/null
$ cat count.txt
5
$ gunzip -c nums.gz | tr '\n' ' '
1 2 3 4 5
```

Five numbers, counted and gzipped in one pass, no temp file. Beautiful. So per the house rule — escalate until it breaks — I asked the obvious paranoid question: does the shell *wait* for that `>(…)` process before moving on? I made the consumer slow and read its output on the very next line:

```console
$ cat race.sh
#!/usr/bin/env bash
rm -f out.txt
echo "hello from the pipe" | tee >(sleep 0.5; cat > out.txt) > /dev/null
echo "immediately after: out.txt = [$(cat out.txt 2>/dev/null)]"

$ for i in 1 2 3; do echo "run $i:"; ./race.sh; done
run 1:
immediately after: out.txt = []
run 2:
immediately after: out.txt = []
run 3:
immediately after: out.txt = []
```

Empty, three for three. The shell fires off the `>(…)` process asynchronously and does **not** wait for it to finish before running the next command. `tee` returned, the pipe closed, the shell marched on — while `cat > out.txt` was still asleep. Anything that writes through `>(…)` and then reads the result on the next line is reading a file that may not be written yet. This is the classic footgun: `command > >(post_process > final.log); upload final.log` uploads a half-written or empty file, intermittently, on a fast machine, which is to say it passes every time you test it and fails in production. The fix is unglamorous — if you need the output before the next command, don't use `>(…)`; use a plain redirect, which finishes before the line returns:

```console
$ cat norace.sh
#!/usr/bin/env bash
rm -f out.txt
echo "hello from the pipe" > out.txt        # synchronous: done when the line returns
echo "immediately after: out.txt = [$(cat out.txt)]"

$ ./norace.sh
immediately after: out.txt = [hello from the pipe]
```

## Bonus nitpick: it's a pipe, so it has no size and no rewind

Two smaller sharp edges for anyone piping process substitution into a tool that expects a real file. First, ask the filesystem how big it is and you get a lie:

```console
$ stat -c 'link size=%s type=%F' <(seq 1 100000)
link size=64 type=symbolic link
$ stat -L -c 'target size=%s type=%F' <(seq 1 100000)
target size=0 type=fifo
$ seq 1 100000 | wc -c
588895
```

The real content is 588,895 bytes. `stat` reports either 64 (the size of the `/dev/fd/63` symlink itself) or 0 (a fifo has no size). A tool that pre-allocates a buffer from the file size, or shows a progress bar, gets nonsense. Second, you can't rewind it — a pipe is consumed once:

```console
$ exec 9< <(seq 1 5)
$ head -n2 <&9 | tr '\n' ' '
1 2
$ head -n2 <&9 | tr '\n' ' '; echo "<<end"
<<end
```

Second read: nothing. Any tool that reads a file, seeks back to the start, and reads again — a two-pass parser, some XML and archive readers — sees the first pass and then an empty file. `wc -c` and `sort` and `diff` are fine; they stream once. Anything that stats or seeks is not.

## The results table

| Scenario | What I ran | Result |
|---|---|---|
| Basic diff, no temp file | `diff <(sort a.txt) <(sort b.txt)` | ✅ identical output & exit to the temp-file version |
| Under `sh`/dash | `sh demo.sh` | ❌ `Syntax error: "(" unexpected`, exit 2 |
| Bash shebang, run directly | `./fixed.sh` | ✅ works |
| Bash shebang, run as `sh fixed.sh` | `sh fixed.sh` | ❌ still breaks — shebang ignored |
| Inner fails, real pipe | `false \| wc -l` under `pipefail` | ✅ script exits 1 (caught) |
| Inner fails, process sub | `wc -l < <(false)` under `pipefail` | ❌ exits 0 — failure invisible |
| Inner fails, temp file + `$?` | `fixB.sh` | ✅ caught, exit 1 |
| `>(…)` then read next line | `race.sh`, 3 runs | ❌ empty file 3/3 — no wait |
| Ask its size | `stat -L` on `<(seq 1 100000)` | ❌ `size=0` vs real 588895 bytes |
| Read it twice | two `head` on one fd | ❌ second read empty — no rewind |

## The checklist

- **`diff <(a) <(b)`** is a real upgrade over scratch files — for commands that can't fail in a way you care about.
- **It's not POSIX.** Under `/bin/sh` (dash) it's a *syntax error*, not a runtime one. Use `#!/usr/bin/env bash` **and** never invoke the script as `sh name`.
- **`pipefail` does not cover `<(…)`.** The inner command's exit code is invisible; a 404 inside `<()` diffs against an empty stream and stays green. If it can fail, run it on its own line into a file and check `$?`.
- **The shell doesn't wait for `>(…)`.** Don't read its output on the next line — use a plain redirect when you need the result synchronously.
- **It's a pipe:** no meaningful size (`stat` lies), no rewind (read-once). Fine for streamers, wrong for anything that seeks.

**Verdict: survives a normal Tuesday**, interactively, for a quick `diff <(…) <(…)` you're watching with your own eyes. Drops to a **bad Tuesday** the moment it goes into a script — because the sh break and the swallowed exit code both wait until the day it runs unattended, on a machine that isn't yours, invoked by something that isn't bash. Grudging respect: for the interactive one-liner it was meant to be, it refused to break. I tried.
