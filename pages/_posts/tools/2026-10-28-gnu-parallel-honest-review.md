---
title: "GNU parallel: the job runner that quotes your filenames for you, until you quote them too"
description: "A stress-tested review of GNU parallel: the quotes that turn its safety into injection, kill -9 vs --resume, an exit code capped at 101, and 3 ms a job."
date: 2026-10-28
preview: /images/previews/gnu-parallel-the-job-runner-that-quotes-your-filen.svg
categories: [Tools]
tags: [productivity, system]
author: edge
verdict: "Use it — survives a bad Tuesday. Leave {} unquoted, never kill -9 a --resume run, and batch with -X when the jobs are tiny."
excerpt: "I fed GNU parallel a filename that runs a command, ten thousand do-nothing jobs, and a kill -9 mid-run. It quoted the evil filename perfectly until I helped by adding quotes, and then it ran the payload."
permalink: /tools/gnu-parallel-honest-review/
---
I review job runners by handing them work nobody sane would queue: a filename with a newline in it, a filename that is also a shell command, ten thousand jobs that do nothing at all, and a `kill -9` in the middle. GNU `parallel` is what you reach for once a `for` loop over 4,000 images has run for twenty minutes on one core while the other three watched. You give it a command and a list, and it runs one copy per CPU, collects the output and tells you what failed. It is excellent at that.

It also has one reflex trap, and every careful shell programmer will walk into it. `parallel` shell-quotes every argument you hand it. Your training says to wrap `"{}"` in double quotes, and if you do, the two layers of quoting cancel out. I made a file named `$(touch PWNED).txt` and ran a careful-looking command over it. Afterwards there was a file called `PWNED` in the directory.

**The verdict, up front:** use it. Its output grouping is better than anything `xargs -P` gives you, it catches a full disk and says so out loud, and its quoting is correct right up until you "fix" it. It survives a normal Tuesday and most of a bad one. Here's how it fails on the bad ones: you add quotes, you `kill -9` a resumable run, or you feed it ten thousand jobs that each take a millisecond.

Everything below ran on Ubuntu 24.04 with 4 cores, against the version apt installed:

```console
$ parallel --version | head -1
GNU parallel 20231122
```

(One thing to check before you copy any of this. The `moreutils` package also ships a program called `parallel`, with different flags. On Debian and Ubuntu, installing GNU `parallel` moves the moreutils one aside to `parallel.moreutils`. [Cass covered that collision in the moreutils review](/tools/moreutils-honest-review/). Run `parallel --version` first. If the first line doesn't say `GNU parallel`, nothing below applies to the program you have.)

## Gotcha 1: quoting `{}` yourself turns its safety into injection

Start with what it gets right, because it's a lot. With `{}` left bare, `parallel` quotes every argument for the shell, so spaces, apostrophes, emoji and a fake `rm -rf` all arrive as plain text:

```console
$ parallel -k echo ::: 'a b' '$(whoami)' "it's" '; rm -rf /' '🔥 emoji'
a b
$(whoami)
it's
; rm -rf /
🔥 emoji
```

Every one came through as a literal string. `$(whoami)` didn't run. The `; rm -rf /` stayed text (and yes, I ran it inside a scratch directory first, because I'm a professional). That's better than `xargs` manages. Now do what twenty years of `"$var"` taught you and put quotes around the placeholder:

```console
$ parallel -k 'echo "[{}]"' ::: 'a b' plain "it's" '$HOME'
['a b']
[plain]
/usr/bin/bash: -c: line 1: unexpected EOF while looking for matching `''
['/tmp/gp/home']
```

All four results are wrong in a different way. `a b` came out with literal single quotes stuck to it. `it's` broke the command line. `$HOME` **expanded**: `parallel` single-quoted it, your double quotes went around those, and inside double quotes a single quote is just a character, so the shell saw a bare `$HOME` and filled it in. Now swap the variable for a command:

```console
$ mkdir inj && cd inj && touch '$(touch PWNED).txt'
$ ls | parallel 'wc -c "{}"'
wc: "'.txt'": No such file or directory
$ ls
$(touch PWNED).txt
PWNED
```

A filename ran a command. The equivalent `xargs -I{} sh -c 'wc -c "{}"'` does the same thing (I checked, and `PWNED` showed up there too), so `parallel` isn't worse than the tool it replaces. The difference is that `parallel` had it *right* until I added the quotes. Who gets hurt: whoever runs a batch job over a shared upload directory, in a repo that once had a code review comment saying "always quote your variables." The fix is to leave `{}` bare. `parallel 'wc -c {}'` is the safe form, even though it looks like the unsafe one.

## Gotcha 2: no `{}` means it adds the argument to the end, even where that breaks things

If your command has no `{}` in it, `parallel` adds the argument to the end. That's handy for `parallel gzip ::: *.log`. It bit me twice while I was writing this review. The first time, I wanted ten jobs that failed:

```console
$ parallel -j8 'exit 1' ::: $(seq 10)
/usr/bin/bash: line 1: exit: too many arguments
```

That ran `exit 1 1`, `exit 1 2`, and so on. The second time, I wanted one job that printed 3 MB of `x`:

```console
$ parallel 'head -c 3000000 /dev/zero | tr "\0" x' ::: 1
tr: extra operand ‘1’
```

The argument went to the end of the *whole command line*, which put it on the last command in the pipe. So `tr` got it, not `head`. Who gets hurt: anyone writing a pipeline that doesn't need the argument (a fixed-count benchmark, a retry loop), where an extra operand on the last stage either errors or quietly changes what it does. If you mean to ignore the argument, swallow it on purpose with `: {}` at the end. That's what I did for every test after this one.

## Gotcha 3: an argument with a newline in it becomes two jobs, unless you use `-0`

Here's one argument with a newline in it, passed directly on the command line:

```console
$ parallel --dry-run 'echo {}' ::: $'two\nlines'
echo two
echo lines
```

That's two jobs from one argument. Input piped from `ls` splits the same way, so a file called `evil⏎name.txt` turns into two jobs for two files that don't exist. The fix is the same one `xargs` uses: null-delimit from start to finish with `find . -print0 | parallel -0 …`, and then the name arrives in one piece. Who gets hurt: the cleanup job that runs `rm` on a file named `name.txt`, which belongs to someone else.

## Gotcha 4: the exit code counts failures, and stops counting at 101

`parallel` sets its own exit status to the *number of jobs that failed*, which is better than most runners. I failed jobs on purpose to see where the count stops:

| Failing jobs | `parallel` exit status |
|---|---|
| 1 | 1 |
| 3 | 3 |
| 100 | 100 |
| 101 | 101 |
| 150 | 101 |
| 300 | 101 |
| one job that ran `exit 7` | 1 |
| one job killed with `kill -9` | 1 |

It caps at 101, which is deliberate and correct: an exit status is one byte, so 256 failures would wrap around to 0, which means "success." I tested 300 and got 101. I respect it, reluctantly. The cost is the last two rows. A job's *own* exit code is gone, so 7 becomes 1 and a SIGKILL becomes 1. Also, by default every job runs even after the first one fails (with `-j1` over `0 1 0 0`, all four started). If job two failing means jobs three through four thousand will just fail the same way, add `--halt now,fail=1`, which stopped my run at the first failure and printed the command that died. If you need to know *why* each job failed, write `--joblog jobs.log` and read the `Exitval` and `Signal` columns. The exit status won't tell you.

## Gotcha 5: `kill -9` plus `--resume` runs the jobs that were in progress twice

`--joblog` with `--resume` is the feature people pick `parallel` for: kill a long run, start it again, and it skips what already finished. So I killed it. Twenty jobs, two at a time, each one adding a line to `done.txt`, `kill -9` on `parallel` after 1.2 seconds, then the same command again with `--resume`. I ran that ten times:

```console
trial 1: unique=20 dup=2
trial 2: unique=20 dup=2
…
trial 10: unique=20 dup=2
total duplicated jobs: 20
```

Every trial lost nothing, and every trial ran exactly two jobs twice. Two is `-j2`. The jobs that were running when `parallel` died kept going without a parent, finished, and wrote their lines. `parallel` was dead, so it never logged them, and `--resume` ran them again. In my first run, before the loop, `done.txt` already had 8 lines when the joblog only had 6 entries. Then I sent the polite signals instead:

| Signal to `parallel` | Exit | Lines in `done.txt` / joblog entries | Duplicates after `--resume` |
|---|---|---|---|
| `kill -9` (×10) | — | 8 / 6 (first run) | 2 every time |
| `kill -TERM` | 255 | 6 / 6 | 0 |
| `kill -INT` (Ctrl-C) | 255 | 6 / 6 | 0 |

With SIGTERM and SIGINT, `parallel` takes the running jobs down with it and the log matches reality. With SIGKILL, the in-progress jobs run *at least once*. Who gets hurt: anything that isn't safe to run twice, like the job that sends an invoice email, increments a counter or appends to a file. Make the jobs safe to repeat, and stop the runner with TERM (what `timeout` and `systemctl stop` send first) or INT (Ctrl-C), not `-9`.

## Gotcha 6: it costs 3 ms per job

`parallel` is a Perl program that does a lot of bookkeeping for each job. With jobs that do nothing, you only measure the bookkeeping:

```console
$ time (seq 10000 | parallel true > /dev/null)
real	0m30.271s

$ time (seq 10000 | xargs -P"$(nproc)" -n1 true)
real	0m4.815s

$ time (seq 10000 | parallel -X true)
real	0m0.381s
```

Ten thousand empty jobs took 30.3 seconds, about 3 ms of overhead each, and more than six times slower than `xargs -P`. If each job is a two-minute video encode, 3 ms doesn't matter. If each job is a `stat`, the overhead is the whole runtime. The fix is built in: `-X` packs as many arguments into each command line as will fit, spread across the job slots. My 10,000 arguments became 4 commands of 2,500 each, and the whole run took 0.38 seconds. That's about 80× faster than one job per argument and still correct. I compared output checksums: `-k` output, plain `seq`, and sorted unordered output all hashed to `72d4ff27…`.

## Where it refused to break (respect, reluctantly)

- **Output never interleaves.** Two jobs printing three lines each, 50 ms apart: `xargs -P2` mixed them up (`A-line1`, `B-line1`, `A-line2`…), and `parallel` printed all of A, then all of B. Who that protects: anyone grepping a log for one job's output. If you *want* lines as they arrive, use `--line-buffer`, which prints each job's output a whole line at a time as it arrives.
- **`-k` keeps input order.** Jobs that slept 0.3, 0.1 and 0.2 seconds finished as `1 2 3` without it and came out `3 1 2` with it.
- **A full disk is a loud error.** Grouping output means buffering it in `$TMPDIR`, so I mounted a 1 MB tmpfs as `TMPDIR` and made one job print 3 MB. It didn't silently cut the output short. It exited **255**, wrote **0 bytes** to stdout, and said: `Output is incomplete. … Is the disk full? Change $TMPDIR with --tmpdir or use --compress.` Its own suggestion worked: `--compress` delivered all 3,000,000 bytes and exited 0, and so did `-u` and `--line-buffer`, which skip the buffer.
- **Shell functions fail loudly.** `parallel greet ::: a` with an unexported function gave `greet: command not found` and exit 1. After `export -f greet`, it printed `hi a`. No silent no-op.

## The citation notice, and the hall of shame

Upstream GNU parallel shows a notice asking academics to cite it until you run `parallel --citation` once. On this box it never appeared, not with a fresh `$HOME` and not under a pseudo-terminal. Here's why, in Debian's copy of the program:

```console
$ sed -n 2631,2633p /usr/bin/parallel
    # If you want GNU Parallel to be maintained in the future, you
    # should keep this line:
#    citation_notice();
```

Debian commented the call out. The upstream source says, in several places, that whoever removes those lines will be "put in a public hall of shame." Debian's changelog addresses this directly. It notes the hall-of-shame comment and says the maintainer does "not think that those statements invalidate the permission to change the code that is granted by GPL." So there's a licensing dispute in your `/usr/bin`. Who gets hurt: anyone who copies an Ubuntu one-liner onto a Mac or a hand-built server and finds an unexpected notice on stderr, which can trip whatever is checking that stderr is empty. `--will-cite` exists, and Debian's own copy still accepts it.

## The results table

| Scenario | Behavior | Survives? |
|---|---|---|
| Args with spaces, `'`, `$( )`, `; rm -rf /`, emoji, `{}` bare | All literal, nothing executed | Grudging respect ✅ |
| Two chatty jobs at once | Output grouped per job, never interleaved | Grudging respect ✅ |
| 3 MB of output into a 1 MB `$TMPDIR` | Exit 255, 0 bytes, clear error; `--compress` fixes it | Grudging respect ✅ |
| 300 failing jobs | Exit status capped at 101, never wraps to 0 | Grudging respect ✅ |
| `kill -TERM` / Ctrl-C, then `--resume` | Log matches reality, 0 duplicates | Normal Tuesday ✅ |
| 10,000 tiny jobs | 30.3 s (≈3 ms each) vs 0.38 s with `-X` | Bad Tuesday ❌ (fixed by `-X`) |
| Command with no `{}` | Argument added to the end of the last command | Bad Tuesday ❌ |
| One job's own exit code | Gone: 7 → 1, SIGKILL → 1 | Bad Tuesday ❌ |
| Newline in a name, without `-0` | One argument becomes two jobs | Bad Tuesday ❌ |
| `kill -9`, then `--resume` (×10) | 2 jobs ran twice, every time | Intern-has-sudo Tuesday ❌ |
| `"{}"` in double quotes | Literal quotes, broken commands, **filename executed** | Intern-has-sudo Tuesday ❌ |

## The verdict, in full

**Use GNU `parallel`.** If you run lots of independent jobs from the shell, it's better than `xargs -P` on nearly everything that matters: output that doesn't interleave, a failure count that can't wrap to zero, a joblog you can resume, and an error you can read when the disk fills up. Most of what I threw at it, it handled.

Every way it actually failed came from you, the operator, doing something reasonable. So the rules are short. Leave `{}` bare; its quoting is correct and yours breaks it. End with `: {}` when you mean to ignore the argument. Use `-0` for filenames. Use `--halt now,fail=1` when the first failure means the rest will fail too, and `--joblog` when you need to know what failed. Use `-X` when the jobs are tiny. Stop it with TERM, never `-9`, and make every job safe to run twice anyway. Follow those and it survives a bad Tuesday. Ignore the first rule and a file in your upload directory can run commands on your machine.
