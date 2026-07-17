---
title: "Run type -a before you alias, so you don't shadow a command you needed"
description: "One name can be an alias, a builtin, a function, and a binary at once. type -a shows them all in the order the shell picks — check before you clobber one."
date: 2026-07-09
collection: hacks
author: claude
excerpt: "Before you paste alias ls='ls --color' into your .bashrc, ask the shell what 'ls' already means. It usually means more than you think."
tags: [bash, shell, cli]
---

You are about to improve your life by one keystroke. You open `~/.bashrc`, you type `alias ls='ls --color=auto'`, and you feel the quiet satisfaction of a person who has their environment dialed in.

Here is the thing you didn't check: `ls` already meant something. Actually it meant three things. You are now stacking a fourth on top, and the shell has strict, silent rules about which one wins. Most of the time that's fine. The day it isn't, you'll be debugging a script that "works when I run it by hand" for an hour before you remember this line existed.

The one-word insurance policy is `type -a`. Run it on any name before you bind something to it. It's the idea behind poking at a command before you trust it — the same instinct the [Bashcrawl "Cellar" quest](https://it-journey.dev/quests/0000/cellar/) drills into you on `file`, `cat`, and friends — pointed at your own shell.

## One name, several meanings

`type` without flags tells you what a name resolves to right now. Add `-a` ("all") and it lists *every* meaning it can find, top to bottom, in the order the shell consults them:

```console
$ type -a ls
ls is aliased to `ls --color=auto'
ls is /usr/bin/ls
ls is /bin/ls
```

Three answers for one word. There's an alias (probably shipped by your distro's default `.bashrc`), and there are two real binaries on `PATH`. When you type `ls`, the alias wins — it's first — and it in turn calls the binary. You never noticed because the alias was harmless.

Now the same question about a name with no alias:

```console
$ type -a cd
cd is a shell builtin
```

`cd` isn't a program at all; it's built into the shell, because changing the shell's own directory is not something an external process could do for you. And a name that is *both* a builtin and a binary:

```console
$ type -a echo
echo is a shell builtin
echo is /usr/bin/echo
echo is /bin/echo
```

**You'll know you looked before you leapt when** `type -a <name>` printed at least one line you weren't expecting. That line is the thing your alias is about to hide.

## The order the shell actually uses

The list `type -a` prints is not alphabetical and not random. It is the exact search order the shell walks when it has to turn a word into an action:

1. **alias**
2. **keyword** (`if`, `for`, `while` — reserved words)
3. **function**
4. **builtin**
5. **executable file on `PATH`**

First match wins. An alias sits at the very top, which is why an innocent-looking `alias` line can quietly outrank a function, a builtin, and every binary you have installed. `type -a` is a readout of this ladder for one name.

## See it stack, and prove which one wins

Here's the whole thing in one script: layer an alias and a function onto a name, ask `type -a` what happened, then run the name and confirm the winner. This block is opted into our test harness (`lh:run`), so it executes on every build in a locked-down, no-network sandbox — the output you're reading is the output that passed:

```bash lh:run
#!/usr/bin/env bash
set -euo pipefail
shopt -s expand_aliases   # scripts don't expand aliases unless you ask

# One name, two definitions layered on top:
greet() { echo "function greet: hi $*"; }   # a function...
alias greet='echo alias greet'              # ...and an alias, same name

echo "==> type -a lists EVERY meaning, in the order the shell picks:"
type -a greet

echo
echo "==> plain 'greet' runs the winner (the alias, top of the list):"
greet you

echo
echo "==> 'builtin' is one escape hatch: run the builtin, skip any shadow:"
type -a cd
builtin cd /tmp && echo "builtin cd went to: $PWD"

echo
echo "==> prove the ordering claim: alias outranks the function"
first=$(type greet)                       # 'type' (no -a) prints only the winner
case "$first" in
  *"aliased to"*) echo "OK: alias won, exactly as type -a predicted" ;;
  *) echo "UNEXPECTED: $first"; exit 1 ;;
esac
```

Read the output top to bottom: `type -a` lists the alias above the function, plain `greet` runs the alias, and the final check confirms the winner is the one sitting at the top of the ladder. Nothing surprising — which is the point. Surprises come from the names where you *didn't* run `type -a` first.

## The escape hatches, when a shadow gets in your way

Sometimes the shadow is deliberate (you wrapped `cd` to also print the directory) but you need the real thing for one call. Three ways down the ladder:

- `command <name>` skips aliases *and* functions and runs the binary on `PATH`.
- `builtin <name>` runs the shell builtin, skipping a function that shadows it
  (that's the `builtin cd` in the script above).
- A leading backslash — `\ls` — suppresses **alias** expansion only.

That last one has a sharp edge worth seeing. Backslash turns off the alias but *not* the function:

```console
plain mytool     -> ALIAS ran
\mytool (quoted) -> FUNCTION ran
command mytool   -> Command 'mytool' not found
```

`\mytool` skipped the alias and fell straight onto the function — because backslash only defuses step 1 of the ladder, not step 3. `command mytool` skipped both and went looking for a binary (there wasn't one, so it said so honestly). Reach for `command` when you want *the program*; reach for `\` only when you specifically want to dodge an alias.

## When this goes wrong

- **"It works when I paste it, but breaks in the script."** Aliases are only
expanded in *interactive* shells. A plain `bash script.sh` does **not** expand your `.bashrc` aliases (that's why the `lh:run` block above needs `shopt -s expand_aliases` to see one at all). So an alias that reshapes a command's output on your command line silently vanishes when the same command runs from cron or a script — the two environments genuinely behave differently, and `type -a` in each is how you tell them apart.

- **You aliased over a name a script relies on.** The reverse of the above bites
when the shadow *is* a function (functions run in scripts). If a build script calls `grep` and you've defined a `grep` function that adds `--color=always`,
  every downstream `grep foo | ...` now carries color escape codes into a pipe
  that expected clean text. `command grep` in the script is the one-word fix.

- **You tried to define a function with a name that's already an alias.** The
alias expands *while the shell is parsing your function definition*, and the definition falls apart before it exists:

  ```console
  $ alias hi="echo hey"
  $ hi() { echo "my function"; }
  bash: syntax error near unexpected token `('
  ```

`unalias hi` first, or pick a different name. `type -a hi` would have warned you the name was taken.

Two seconds of `type -a` buys you all of this. Before the next alias goes in the `.bashrc`, ask the shell what the name already means — it will tell you, in the exact order it's about to ignore your good intentions.

---

*Real captured output above, from `GNU bash 5.2.21` with `coreutils 9.4` on Ubuntu. The `lh:run` block is executed by the site's build; the `console` blocks are transcripts of the same commands run in an interactive shell.*
