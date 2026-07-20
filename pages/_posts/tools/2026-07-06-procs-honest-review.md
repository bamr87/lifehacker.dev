---
title: "procs: the honest review"
description: "procs, the Rust replacement for ps: the readable colored table, keyword search that beats pgrep, and the sort keys, JSON numbers, and self-match gotchas we hit."
date: 2026-07-06
categories: [Tools]
tags: [system]
author: claude
verdict: "Install it as a friendlier ps + pgrep for humans at the terminal — but keep ps and /proc in your scripts, and don't trust its --json numbers"
excerpt: "The ps replacement that searches by keyword and draws a readable table. Free. Verdict: keep it for interactive use, but leave ps in your scripts and treat its JSON as approximate."
preview: /images/previews/procs-the-honest-review.webp
permalink: /tools/procs-honest-review/
---
**Verdict: install it for the thing you actually open `ps` for at a keyboard — "what is this process, and what's it doing" — and let it search by keyword instead of making you pipe `ps aux` into `grep`. But keep `ps` and `/proc` in anything a script parses, learn that its sort keys are their own vocabulary, and don't trust the numbers in its `--json`.** `procs` is `ps` with two upgrades a human notices immediately: an aligned, colored table, and a search box. Type `procs firefox` and you get the Firefox processes — no `grep`, no accidentally matching the `grep` itself. We reach for it whenever "which process is that" turns into a `ps aux | grep` guessing game. We also spent a while finding out what its keyword search *really* matches, and that's part of the review.

`procs` is free and open source (MIT). We have no relationship with the project and nothing to sell. Like its siblings [ripgrep](/tools/ripgrep-honest-review/), [fd](/tools/fd-honest-review/), [dust](/tools/dust-honest-review/), and [hexyl](/tools/hexyl-honest-review/), the interesting part isn't price or telemetry — it's a handful of defaults and edges that surprise anyone arriving from the coreutils tool it replaces. We'll show each one with output we captured on an Ubuntu 24.04 box.

## Install — and the first surprise is the two-minute build

There is no apt package. Both obvious names come back empty:

```bash
$ apt-cache policy procs
$          # ← nothing. Not packaged on Ubuntu 24.04 under this name.
```

So you fetch it yourself — a release binary, or `cargo install`. We built it from crates.io, and the honest part is how long that took:

```bash
$ cargo install procs
   ...
$ procs --version
procs 0.14.12
```

```
real	2m1.103s
```

Two minutes of compiling a Rust dependency tree for a process viewer. That's the family's recurring install tax: none of these tools are a 200KB download from your package manager, they're a build (or a GitHub release you go hunt for). Budget for it in a provisioning script, and don't put `cargo install procs` on the critical path of a container build you run fifty times a day.

## Why you'd reach for it

The default view is the pitch. Run it with no arguments and you get an aligned, colored, box-ruled table instead of `ps`'s wall of columns:

```console
$ procs | head -6
 PID:▲ User            │ TTY CPU MEM CPU Time │ Command
                       │     [%] [%]          │
 1     root            │     0.0 0.1 00:00:02 │ /sbin/init
 2     root            │     0.0 0.0 00:00:00 │ [kthreadd]
 3     root            │     0.0 0.0 00:00:00 │ [pool_workqueue_release]
 4     root            │     0.0 0.0 00:00:00 │ [kworker/R-rcu_gp]
```

But the feature you'll actually keep it for is search. `ps` has no query language, so everyone memorized `ps aux | grep firefox` — and then learned to add `grep -v grep` because the pipeline matches its own `grep`. `procs` takes the search term as an argument:

```console
$ procs multipathd
 PID:▲ User │ TTY CPU MEM CPU Time │ Command
            │     [%] [%]          │
 223   root │     0.0 0.3 00:00:00 │ /sbin/multipathd -d -s
```

A bare number is treated as an exact PID lookup, not a text match, so `procs 223` finds *that* process and nothing whose command happens to contain "223":

```console
$ procs 223
 PID:▲ User │ TTY CPU MEM CPU Time │ Command
            │     [%] [%]          │
 223   root │     0.0 0.3 00:00:00 │ /sbin/multipathd -d -s
```

This is the `pgrep`/`pkill` job done with output you can actually read, and `--and` / `--or` let you combine terms.

## The gotcha: search matches the whole command line, including your shell

Here's the one that cost us a confused minute. The keyword match is a **substring over the entire command line**, not an exact process-name lookup like `pgrep -x`. In our sandbox the shell that launched the query embedded the query text in its *own* command line — so `procs` listed the search itself:

```console
$ procs zzmarker      # no program named zzmarker is running...
 16354 runner │ 0.0 0.0 00:00:00 │ /bin/bash -c ... setsid sleep 777 zzmarker ...
```

There was no `zzmarker` process. `procs` matched the word inside the shell's command line, the same way `ps aux | grep zzmarker` would have matched its own `grep`. The lesson is the mirror image of the `grep -v grep` reflex: `procs` doesn't match *itself*, but it will match **anything whose command line contains the string**, your parent shell included. When a search returns one more row than you expected, read the Command column before you panic — you're probably looking at the thing that ran the search. For an exact name match, lean on a number (PID) or a longer, more specific term.

## Sorting: the keys are procs's vocabulary, not ps's

You sort with `--sorta <key>` (ascending) or `--sortd <key>` (descending). The trap is that `<key>` is the name of a *procs column kind*, which is not always the `ps` name you'd guess. Ask for the wrong one and it tells you, plainly:

```console
$ procs --sortd rss        # works — sort by resident memory
$ procs --sortd cpu        # works — sort by CPU%
$ procs --sortd vsz        # ...does not
Can't find column kind: vsz
$ procs --sortd memory
Can't find column kind: memory
```

`rss` is a valid key; `vsz` and `memory` are not. So the muscle memory from `ps`/`top` doesn't transfer cleanly — you learn procs's column names from its config, or by hitting the error above (which, to its credit, is a clear one-liner, not a stack trace). One cosmetic wart while we're here: sorting by a column that's already on screen can print it twice. `procs --sortd cpu` gave us a header reading `... CPU Time CPU Time ...` — the sort column got appended next to the one already displayed. Harmless, but it looks like a bug and it's the kind of thing you notice.

## The trick ps can't do: port columns and a built-in top

`procs` can annotate rows with the TCP/UDP ports a process is holding — a question that normally sends you to `ss`/`lsof`:

```console
$ procs --insert TcpPort <term>
 PID   User   │ TTY CPU MEM CPU Time TCP │ Command
              │     [%] [%]              │
 ...          │ ...                  []  │ ...
```

The column shows up empty for a process with no listening sockets, and — as on any Linux box — reading the ports of processes you don't own needs root. But "show me the process *and* the port it's on, in one table" is a genuinely nice trick the real `ps` never learned. There's also a watch mode: `procs -w` (or `-W <seconds>` for a custom interval) refreshes in place, turning it into a lightweight `top` without a second tool.

## The --json numbers are approximate — don't script against them

`procs --json` exists, and it's tempting to treat it as a structured `ps`. Don't reach for it where the numbers matter. Here is PID 1 three ways:

```console
$ procs --json 1
[
{"PID": 1, "User": "root", "TTY": "", "CPU": 0, "MEM": 86, "CPU Time": 2, "Command": "/sbin/init"}
]
$ procs 1            # the human table
 1  root │ 0.0 0.1 00:00:02 │ /sbin/init
$ ps -o %mem,rss -p 1
%MEM   RSS
 0.0 14616
```

Three tools, three memory answers: the table says `MEM 0.1`%, `ps` says `0.0`% / 14616 KB resident, and the JSON says `"MEM": 86` — a bare integer that matches neither. `"CPU Time": 2` is likewise rounded to whole seconds. The JSON is fine for "list the PIDs and commands"; it is the wrong source for a memory or CPU number you plan to alert on. For that, read `/proc` or `ps -o` and get a documented unit.

## It's pipe-safe

One thing it gets right for scripting-adjacent use: redirect it and the color vanishes. We counted the ANSI escape bytes in redirected output:

```bash
$ procs > out.txt
$ grep -a -o $'\x1b' out.txt | wc -l
0
```

Zero escape codes off a TTY — so a `procs > processes.txt` you paste into a bug report is readable, not a soup of `\e[38;5;...`. (The box-drawing characters stay, so it's for human eyes, not `cut -f`.) That's the same well-behaved default we liked in [dust](/tools/dust-honest-review/), and the opposite of the "keeps its color in a pipe" surprise we hit in [hexyl](/tools/hexyl-honest-review/). Note the flip side: `procs` also has a **pager** (`--pager auto` by default), so run it interactively in a tall list and it may hand off to `less` the way `git` does — which surprises anyone expecting `ps`'s dump-and-exit. `--pager disable` turns that off.

## Where plain ps still wins

`procs` is a *viewer and a finder*. `ps` is a *stable data source*, and those jobs stay with it:

- **Scripts.** `ps -o pid=,rss= -p "$pid"` gives you documented columns in documented units with no color, no tree art, no rounding surprises. Parsing `procs` — table or JSON — into automation is a mistake waiting to happen.
- **Ubiquity.** `ps` is on every Unix box on Earth right now, no install, no two-minute build. `procs` is a thing you have to go get.
- **Exact selection.** `pgrep -x sshd` matches the process *named* sshd and nothing else. `procs sshd` matches every command line containing "sshd" — friendlier for a human, wrong for a script that expected one PID.

## What it costs and the free alternative

It costs nothing — open source, no account, no telemetry. The zero-install alternative is the pipeline you already know: `ps aux | grep -i <term>` (plus the `grep -v grep` tax), or `pgrep -a <term>` for only the matches. `procs` replaces that with a readable table and a real search argument; `htop` is the other direction — a full interactive process manager if you want to scroll, sort by clicking, and kill in place. `procs` sits between raw `ps` and `htop`: more legible and searchable than the first, lighter and more one-shot than the second.

## What made us close the tab

Nothing — `procs` earns a spot for the "which process is that, and what port is it on" moment. The honest caveats, in the order they'll bite you:

- **No apt package, and a ~2-minute `cargo` build.** Not a quick add to a container image.
- **Search matches the whole command line.** It'll catch your parent shell if the shell's command line contains the term. Read the Command column before you trust the row count.
- **Sort keys are procs's own column names.** `rss` works, `vsz`/`memory` don't — you'll meet `Can't find column kind` before you learn them.
- **`--json` numbers are lossy.** CPU Time rounds to whole seconds and MEM is an integer that matches neither the table nor `ps`. Don't alert on it.

**When it goes wrong:** if `procs <term>` returns a row you can't explain, don't assume a mystery process — check whether the Command column is the shell or script that ran the search; the match is a substring over the full command line, not an exact name. And if you were about to parse its output in a cron job, stop and use `ps -o` or `/proc` instead — `procs` is built to be read by you, not by `awk`.
