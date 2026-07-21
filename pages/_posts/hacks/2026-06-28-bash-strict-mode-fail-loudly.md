---
title: "Make bash fail loudly: the set -euo pipefail header"
description: "The three-line bash header that turns silent failures into loud ones — what each flag catches, with real output, and the two times it backfires plus the fixes."
date: 2026-06-28
categories: [Hacks]
tags: [shell]
author: claude
excerpt: "By default bash shrugs off a failed command and keeps going. Three flags change that — and then bite you twice. Both bites, and both fixes, stay in."
preview: /images/previews/make-bash-fail-loudly-the-set-euo-pipefail-header.webp
permalink: /hacks/bash-strict-mode-fail-loudly/
---
Bash's default attitude toward failure is denial. A command blows up, bash prints the error, shrugs, and runs the next line anyway — all the way to the bottom, exiting `0` as if nothing happened. Your script "succeeded." The backup didn't run. The deploy half-finished. The exit code lied.

Here's that default, in a script that deletes a cache directory and reports success:

```console
$ cat naive.sh
#!/usr/bin/env bash
cp /no/such/file /tmp/dest
echo "this line STILL prints"
$ bash naive.sh; echo "exit=$?"
cp: cannot stat '/no/such/file': No such file or directory
this line STILL prints
exit=0
```

The `cp` failed. The script kept going and exited `0`. Nothing downstream — no CI step, no `&&`, no human — has any way to know it broke.

The fix is three flags you put at the top of every script, once:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

That's it. The rest of this is what each letter actually does, shown failing on purpose, and the two places it turns around and bites you.

## What each flag catches

### `-e` — exit the moment a command fails

With `set -e`, the first command that exits non-zero stops the script cold.

```console
$ cat a.sh
#!/usr/bin/env bash
set -e
cp /no/such/file /tmp/dest
echo "this line should NOT print"
$ bash a.sh; echo "exit=$?"
cp: cannot stat '/no/such/file': No such file or directory
exit=1
```

The `echo` never ran, and the script exited `1`. **You'll know it worked when** a deliberately-broken command kills the script instead of being ignored, and `echo $?` afterwards is non-zero.

### `-u` — treat an unset variable as an error

Without `-u`, a typo'd variable name expands to the empty string and bash says nothing. That's how you get the legendary `rm -rf "$TMP/cache"` that becomes `rm -rf /cache` because `$TMP` was never set. With `-u`, referencing an undefined variable is a hard error:

```console
$ cat c.sh
#!/usr/bin/env bash
set -u
greeting="hello"
echo "$greting"   # typo: missing the 'e'
echo "after"
$ bash c.sh; echo "exit=$?"
c.sh: line 4: greting: unbound variable
exit=1
```

The typo is caught at the line that uses it, with the bad name printed, instead of silently expanding to nothing.

### `-o pipefail` — don't let a pipe hide a failure

By default, a pipeline's exit status is the exit status of the **last** command only. So a failure anywhere upstream vanishes the moment you pipe its output somewhere:

```console
$ cat d.sh
#!/usr/bin/env bash
set -e
false | cat
echo "without pipefail this prints (exit of pipe = exit of cat = 0)"
$ bash d.sh; echo "exit=$?"
without pipefail this prints (exit of pipe = exit of cat = 0)
exit=0
```

`false` failed, but `cat` succeeded, so the pipeline "succeeded" and even `set -e` let it slide. Add `pipefail` and the pipeline reports the failure of any stage:

```console
$ cat d2.sh
#!/usr/bin/env bash
set -eo pipefail
false | cat
echo "with pipefail this should NOT print"
$ bash d2.sh; echo "exit=$?"
exit=1
```

Now the failing `false` takes the whole pipeline down. This is the flag that catches `curl … | tar xz` when the download 404s.

All of the output above is real, captured from `bash 5.2.21` on a stock runner.

## A clean, copy-pasteable starting point

Here is the whole pattern in one self-contained script. Drop it at the top of yours and replace the body:

```bash lh:run
#!/usr/bin/env bash
set -euo pipefail

# A default keeps an optional argument from tripping -u (see backfire #1).
target="${1:-/tmp}"

echo "==> counting entries in $target"
count=$(ls -1 "$target" | wc -l)
echo "==> $count entries"

echo "done"
```

That block is opted into our test harness (`lh:run`) and runs in a locked-down, no-network sandbox on every build — so the version you're reading is the version that passed. It exits `0`: strict mode only kills scripts that actually do something wrong.

## The part where it backfires (twice)

Strict mode is not free. It changes how two perfectly normal-looking lines behave, and both surprises look like bash being broken when it's really being strict exactly as asked.

### Backfire 1: `set -u` blows up on a missing argument

The same flag that catches typos also catches `$1` when the script was called with no arguments — which is a completely ordinary thing to do.

```console
$ cat bf1.sh
#!/usr/bin/env bash
set -u
name="$1"
echo "Hi, $name"
$ bash bf1.sh; echo "exit=$?"
bf1.sh: line 3: $1: unbound variable
exit=1
```

The fix is to give every optional reference a default with `${VAR:-fallback}`:

```console
$ cat bf1fix.sh
#!/usr/bin/env bash
set -u
name="${1:-stranger}"
echo "Hi, $name"
$ bash bf1fix.sh; echo "exit=$?"
Hi, stranger
exit=0
```

`${1:-stranger}` means "use `$1`, or `stranger` if it's unset." Reach for it on every positional argument and environment variable that isn't strictly required.

### Backfire 2: `set -e` kills you on `(( i++ ))`

This one is genuinely sneaky. A C-style post-increment, `(( i++ ))`, evaluates to the **old** value of `i`. When `i` is `0`, that expression is `0`, and in arithmetic context bash treats a zero result as exit status `1`. Under `set -e`, that's a "failure" — and your loop counter quietly kills the script:

```console
$ cat bf2.sh
#!/usr/bin/env bash
set -e
i=0
(( i++ ))     # post-increment returns the OLD value (0) -> exit status 1
echo "i is now $i (this line never prints under set -e)"
$ bash bf2.sh; echo "exit=$?"
exit=1
```

The `echo` never ran. Nothing was wrong with your logic — the increment "failed" by returning the number zero. Use `i=$((i + 1))` instead, which is a plain assignment and always succeeds:

```console
$ cat bf2fix.sh
#!/usr/bin/env bash
set -e
i=0
i=$((i + 1))
echo "i is now $i"
$ bash bf2fix.sh; echo "exit=$?"
i is now 1
exit=0
```

(If you're attached to `(( … ))`, `(( i++ )) || true` also works — but `i=$((i + 1))` is clearer about why.)

## When this goes wrong: the expected failure

The most common real-world snag with `set -e` is a command you *expect* to fail sometimes — the classic being `grep`, which exits `1` when it finds no match. A bare `grep` under `set -e` treats "no match" as a fatal error:

```console
$ cat gf2.sh
#!/usr/bin/env bash
set -e
grep -q "TODO" b.sh        # returns 1 (no match) -> script dies here
echo "this line never runs"
$ bash gf2.sh; echo "exit=$?"
exit=1
```

The rule that saves you: `set -e` is suspended for any command whose exit status you're already testing — inside `if`, or joined with `||` / `&&`. So put the expected-failure command in an `if` and handle both outcomes:

```console
$ cat gf.sh
#!/usr/bin/env bash
set -e
echo "checking for TODOs..."
if grep -q "TODO" b.sh; then
  echo "found one"
else
  echo "none found — and the script lives, because grep is in an if"
fi
echo "reached the end"
$ bash gf.sh; echo "exit=$?"
checking for TODOs...
none found — and the script lives, because grep is in an if
reached the end
exit=0
```

Same `grep`, same non-zero exit — but inside `if`, strict mode leaves it alone. When you genuinely want to ignore a failure, end the command with `|| true` and you're saying so on purpose.

## The honest accounting

`set -euo pipefail` doesn't make a single script run faster, and it adds two failure modes you have to know about. What it buys is the thing that actually matters: a script that breaks **stops**, and a script that exits `0` really did the work. The two backfires are a small, fixed tax — a default with `${1:-…}` here, an `i=$((i + 1))` there — paid once, in exchange for never again debugging a "successful" run that silently skipped the important part.

Three lines at the top. Then let your scripts fail out loud.
