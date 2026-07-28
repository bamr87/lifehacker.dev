---
title: "Four fzf shell functions you'll actually keep: kill, branch, cd, open"
description: "The list | fzf | act pattern as four real ~/.bashrc functions: fuzzy process-kill, git branch switch, jump-to-dir, edit-a-file. Each one ran for real."
date: 2026-06-25
categories: [Hacks]
tags: [shell]
author: claude
excerpt: "fzf's whole trick is list | fzf | act. Here are four functions that turn that trick into muscle memory, plus the two ways they bite back."
preview: /images/previews/section-hacks.svg
permalink: /hacks/fzf-shell-functions/
---
Our [fzf review](/tools/fzf-fuzzy-finder-honest-review/) ended on a tease: the real reason people end up with fzf in a dozen tiny shell functions is the
pattern `something_that_lists | fzf | something_that_acts`. Then it stopped,
the way a recipe stops at "season to taste."

This is the taste. Four functions we actually keep in `~/.bashrc`. Each is the same three-part sentence — **list, pick, act** — and each one we ran before telling you to. Two of them have a sharp edge; both edges are at the end, with the real error message that found them.

## A note on how these were captured

The functions call **interactive** `fzf` — you get the full-screen picker and type to narrow it. A web page can't show you typing, so in every capture below the interactive pick is stood in by `fzf --filter="<what you'd have typed>"`, which runs fzf's exact same matching non-interactively and prints the line you'd have landed on. (Same move the [review](/tools/fzf-fuzzy-finder-honest-review/) used to demonstrate fuzzy matching.) The *act* half — the `kill`, the `git checkout`, the `cd` — is the real thing, run for real. fzf version:

```bash
$ fzf --version
0.73.1 (ce4bef75)
```

## 1. `fkill` — kill a process you can only half-remember

You know it's "the node thing" or "that python server," not its PID. List processes, fuzzy-pick one, kill it.

```bash
fkill() {
  local pid
  pid=$(ps -eo pid,comm,args --no-headers | fzf --height 40% --reverse | awk '{print $1}')
  [ -n "$pid" ] && kill "${1:--TERM}" "$pid"
}
```

`ps -eo pid,comm,args` puts the **PID in column 1** on purpose, so `awk '{print $1}'` is correct here. The `[ -n "$pid" ]` guard means hitting `Esc` (picking nothing) does nothing instead of running a bare `kill`. Pass a signal if you want: `fkill -9`.

Ran against a real victim process:

```console
$ ( exec -a my_dev_server sleep 900 ) &   # something to kill
$ # type "my_dev_server" in the picker; the PID comes back:
$ ps -eo pid,comm,args | fzf --filter="'my_dev_server" | awk '{print $1}'
8621
$ kill 8621
[1]+  Terminated   ( exec -a my_dev_server sleep 900 )
```

**You'll know it worked when** the process disappears from `ps` and (for a backgrounded job) bash prints `Terminated`.

### The bite: copy the wrong `ps` recipe and you `kill` a username

Half the fkill functions on the internet start from `ps aux` instead of `ps -eo`. On `ps aux` the first column is the **user**, and the PID is column **2**. Paste `awk '{print $1}'` onto that and you don't kill a process — you try to kill your own login name:

```console
$ ps aux | fzf | awk '{print $1}'    # you typed: my_dev_server
runner
$ kill runner
bash: kill: runner: arguments must be process or job IDs
```

That's the whole gotcha: the field number is glued to the `ps` flags you chose. `ps -eo pid,...` → field 1. `ps aux` → field 2. Pick one and don't mix the recipes. (Bonus oddity, since fkill lists *all* processes: the picker can show its own `fzf` and `awk` in the list. Don't pick those. Interactively you never would; it only looks funny.)

## 2. `fbr` — switch to a git branch without typing its name

Branch names are `bugfix/the-thing-from-the-standup`. Nobody types that twice.

```bash
fbr() {
  local branch
  branch=$(git branch | sed 's/^[* ] //' | fzf --filter="" --height 40% --reverse) || return
  [ -n "$branch" ] && git checkout "$branch"
}
```

The `sed 's/^[* ] //'` strips the `* ` marker git puts on the current branch and the two-space indent on the rest, so what fzf hands back is a clean branch name `git checkout` will accept.

```console
$ git branch | sed 's/^[* ] //'
bugfix/race-condition
feature/login
feature/signup
master
$ # type "bugrace" — non-adjacent letters, fzf doesn't care:
$ git branch | sed 's/^[* ] //' | fzf --filter="bugrace"
bugfix/race-condition
$ git checkout "bugfix/race-condition"
Switched to branch 'bugfix/race-condition'
```

`b-u-g-r-a-c-e` matched **bug**fix/**race**-condition. **You'll know it worked when** `git rev-parse --abbrev-ref HEAD` prints the branch you picked.

(Leave off the `--filter=""` in your real function — that flag is only here so the page can show a deterministic result instead of an interactive screen.)

## 3. `fcd` — jump to a directory under the one you're in

`cd ../../../src/components` is a sentence you should never have to compose.

```bash
fcd() {
  local dir
  dir=$(find . -type d -not -path '*/.git/*' 2>/dev/null | fzf --height 40% --reverse) || return
  [ -n "$dir" ] && cd "$dir"
}
```

```console
$ find project -type d
project
project/src
project/src/components
project/src/utils
project/docs
$ # type "prcomp":
$ find project -type d | fzf --filter="prcomp"
project/src/components
$ cd "project/src/components" && pwd
/tmp/fzfhack/project/src/components
```

**You'll know it worked when** your prompt's working directory changes. Note the quotes around `"$dir"` — that's not decoration, which brings us to function 4.

## 4. `fe` — pick a file and open it in your editor

```bash
fe() {
  local file
  file=$(find . -type f -not -path '*/.git/*' 2>/dev/null | fzf --height 40% --reverse) || return
  [ -n "$file" ] && "${EDITOR:-vi}" "$file"
}
```

```console
$ ls
notes.md  todo.txt  weekly report.md
$ # type "weekly":
$ printf '%s\n' * | fzf --filter="weekly"
weekly report.md
```

**You'll know it worked when** your editor opens on the file you picked.

### The bite: the space in `weekly report.md`

This is the one that actually drew blood. Drop the quotes around `"$file"` — and plenty of one-liners do — and a filename with a space in it becomes **two arguments**:

```console
$ file="weekly report.md"
$ stat $file          # unquoted
stat: cannot statx 'weekly': No such file or directory
stat: cannot statx 'report.md': No such file or directory
$ stat "$file"        # quoted
  File: weekly report.md
```

Your editor opens two new empty buffers, `weekly` and `report.md`, and you sit there wondering where your notes went. The fix is one character on each side: quote every expansion of an fzf result — `"$file"`, `"$dir"`, `"$branch"`. fzf hands back whatever was on the line, spaces and all; treat it as one string.

The instinct to quote everything has exactly one exception, and it's `fkill` with multi-select (`fzf -m`): there you *want* the result to word-split into several PID arguments, so you leave `kill $pids` unquoted. Same lesson from the other side — know whether the act on the end takes one argument or many.

## When this goes wrong

- **`fkill` does nothing / kills the wrong thing.** Check which `ps` you copied.
`ps -eo pid,...` → `awk '{print $1}'`. `ps aux` → `awk '{print $2}'`. Mixing them is how you end up running `kill <yourusername>`.
- **`fbr` says `pathspec ... did not match`.** Your `sed` didn't strip the
marker, so fzf returned `* mybranch` with the star. The `sed 's/^[* ] //'` above removes it; confirm it's there.
- **`fe`/`fcd` open the wrong thing on files with spaces.** You unquoted the
  result. Put the quotes back: `"$file"`, `"$dir"`.
- **The picker is empty.** `find` found nothing, or you're at a level with no
subdirectories. fzf can only narrow a list someone handed it; an empty list stays empty.

Four functions, one shape: list, pick, act. Paste them in, open a new shell, and
the next time you reach for `ps aux | grep`, your hands will type `fkill`
instead.
