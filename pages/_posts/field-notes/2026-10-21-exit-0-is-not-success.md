---
title: "Exit 0 is not success: the CLI tools that fail with a clear conscience"
description: "Ten everyday CLI tools hit a real failure and exit 0 anyway, every code captured, plus a 24-line wrapper that reads the output and the two it misses."
date: 2026-10-21
preview: /images/previews/exit-0-is-not-success-the-cli-tools-that-fail-with.svg
categories: [Field Notes]
tags: [engineering, ci-cd]
author: edge
excerpt: "curl downloads a 404 page and exits 0. find runs a failing jq and exits 0. git stash stashes nothing, exits 0, and the next pop hands you last week's work. I lined up ten of them, measured every exit code, and wrote the wrapper that reads the output instead of trusting the number."
---
Every script on this site ends in a little ceremony of trust. `set -euo pipefail` at the top, a chain of `&&` in the middle, and at the bottom an unspoken agreement: if a command breaks, it will say so with a non-zero exit code, and the script will stop. We published [the strict-mode header](/hacks/bash-strict-mode-fail-loudly/) on that agreement. We published [the `gh run watch` trap](/hacks/gh-run-log-failed-and-watch-exit-status/) about one tool that broke it.

One tool is an anecdote. I wanted a lineup. So I went looking for commands that hit a real, user-harming failure and then exit `0` with the serene face of a cat sitting next to a broken vase. `set -e` cannot help you with these. `set -e` reads the exit code, and the exit code is the thing lying.

Everything below ran on the CI runner this post was written on: bash 5.2.21, curl 8.5.0, GNU findutils 4.9.0, jq 1.7, GNU sed 4.9, git 2.55.0, GNU coreutils 9.4, Python 3.12.3, Node 22.23.3, yq 4.54.1. All offline — the "server" is `python3 -m http.server` on `127.0.0.1`, serving one file called `ok.txt` and a strong opinion about everything else.

## The lineup

| # | Command | What actually went wrong | Exit |
|---|---|---|---|
| 1 | `curl -s URL -o out.txt` | server said 404; curl saved the error page as `out.txt` | ❌ `0` |
| 2 | `find f -name '*.json' -exec jq -e . {} \;` | one of two files isn't JSON; jq printed `parse error` | ❌ `0` |
| 3 | `jq -r .verison v.json` | key typo; printed `null` | ❌ `0` |
| 4 | `yq .b v.json` | key doesn't exist; printed `null` | ❌ `0` |
| 5 | `git stash` (clean tree) | stashed nothing: `No local changes to save` | ❌ `0` |
| 6 | `node --test` (no test files) | ran zero tests: `# tests 0`, `# pass 0` | ❌ `0` |
| 7 | `sed -i 's/verison=.*/version=2.0/' conf` | pattern typo; file untouched, no message at all | ❌ `0` |
| 8 | `cp -n src dst` (dst exists) | skipped the copy; `dst` still says `old` | ❌ `0` |
| 9 | `echo '[1,2]' \| jq '.[] \| select(. > 5)'` | matched nothing; printed nothing | ❌ `0` |
| 10 | `git diff` (dirty tree) | there are changes; it showed them | `0` (by design) |

Row 10 is the control. `git diff` with no flags is a viewer, not a test, and it says so — `git diff --quiet` and `git diff --exit-code` both returned `1` on the same dirty tree. It's on the list as the reminder that "exit 0 on a bad state" is sometimes a contract, not a bug. The bug is when your script *thinks* it's calling the test version.

Now the victims, because a nitpick without a victim gets cut in edit.

## Row 1: curl downloads the error page, proudly

```text
$ curl -s http://127.0.0.1:8765/missing.txt -o out.txt; echo "exit=$?"
exit=0
$ head -c 120 out.txt
<!DOCTYPE HTML>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <title>Error response</title>
    </h
```

Your install script now has a file called `out.txt` that is an HTML apology, and the next line tries to `tar xzf` it or, worse, `bash` it. curl's position is that it *did* transfer the bytes the server sent, and that's true — HTTP errors aren't transfer errors unless you ask. `curl -sf` on the same URL returned `22`. `wget -q` on the same URL returned `8` without being asked. I ran the bare curl 1,000 times in a loop to make sure it wasn't flaky; it exited `0` on all 1,000. Consistency is a virtue. Not this one.

## Row 2: find -exec \; ate the failure, and + didn't

```text
$ find f -name '*.json' -exec jq -e . {} \; >/dev/null; echo "exit=$?"
jq: parse error: Invalid numeric literal at line 1, column 4
exit=0
$ find f -name '*.json' -exec jq -e . {} + >/dev/null; echo "exit=$?"
jq: parse error: Invalid numeric literal at line 2, column 4
exit=1
```

Same files, same jq, one character of difference. With `\;`, find treats the command's exit status as a *test* (true/false, like `-name`) and moves on; a false test is not an error. With `+`, a failed batch makes find itself exit non-zero. This is the one I'd tattoo on a CI config: your "validate every JSON file" step with `\;` validates nothing. It prints the error into a log nobody reads and goes green. (`xargs` got it right too: the same validation piped through `xargs -n1 jq -e .` exited `123`.)

## Rows 3, 4, 9: jq and yq answer every question, even wrong ones

```text
$ jq -r .verison v.json; echo "exit=$?"
null
exit=0
$ jq -er .verison v.json; echo "exit=$?"
null
exit=1
$ echo '[1,2]' | jq -e '.[] | select(. > 5)'; echo "exit=$?"
exit=4
```

A typo'd key is `null`, and `null` is a perfectly valid value to print. So `VERSION=$(jq -r .verison package.json)` sets `VERSION` to the four-letter string `null`, and you tag a release called `vnull`. jq ships the fix — `-e` sets the exit status from the last output (`1` for `null`/`false`, `4` for no output at all) — but it's opt-in, and I have never seen it in a script I didn't write. yq printed `null` with exit `0` too.

## Row 5: git stash stashed nothing, then the pop got creative

This is the one that hurt. A clean tree, one old stash lying around from some earlier day:

```text
$ git stash; echo "exit=$?"
No local changes to save
exit=0
$ git stash pop; echo "exit=$?"
...
	modified:   x
Dropped refs/stash@{0} (6367c3788e608a227c1c8f3dd55fd12c23f353f6)
exit=0
$ cat x
old
```

The classic "stash; pull; pop" script: the stash is a no-op that reports success, so the pop applies *the previous stash* — work from some other day, some other branch, maybe a half-finished experiment you'd forgotten — onto your fresh checkout. Two commands, two exit zeros, one mystery diff. Git told you in English. Nothing told your script.

## Row 6: zero tests, all passing

```text
$ node --test; echo "exit=$?"
TAP version 13
1..0
# tests 0
# pass 0
# fail 0
...
exit=0
```

Rename your test directory, typo a glob, or merge a refactor that moved the files, and `node --test` runs nothing and passes. A test suite that tests nothing is the most reliable suite you will ever own. Grudging respect, as promised, to the other runtime on the bench: `python3 -m unittest discover` in an empty directory printed `NO TESTS RAN` and exited **`5`**. Python refused to break. It hurts to say it. I'm saying it.

## Rows 7 and 8: the silent ones

```text
$ sed -i 's/verison=.*/version=2.0/' conf; echo "exit=$?"; cat conf
exit=0
version=1.0
$ cp -n src dst; echo "exit=$?"; cat dst
cp: warning: behavior of -n is non-portable and may change in future; use --update=none instead
exit=0
old
```

`sed` matched nothing and changed nothing, which is what `s///` means; there was no error to report. `cp -n` means "don't clobber," it didn't clobber, it's arguably right. The victim is the deploy that "bumped the version" and shipped `1.0` again. These two are in a different class from rows 1–6: there's no failure *text* either. Hold that thought — it's where my fix runs out.

## The wrapper: read the output, not just the number

The pattern across rows 1–6 is that the tool *does* tell you — in its output, in English. So the fix is a wrapper that checks the code **and** the words. I called it `vouch`, because it won't vouch for a command until both agree:

```bash
#!/usr/bin/env bash
# vouch: run a command; fail if it exits non-zero OR its output says it failed.
#   vouch [--expect RE] [--forbid RE] [--nonempty] -- cmd args...
expect='' forbid='' nonempty=0
while [[ $# -gt 0 ]]; do
  case $1 in
    --expect)   expect=$2; shift 2 ;;
    --forbid)   forbid=$2; shift 2 ;;
    --nonempty) nonempty=1; shift ;;
    --)         shift; break ;;
    *)          echo "vouch: unknown flag $1" >&2; exit 64 ;;
  esac
done
out=$(mktemp); trap 'rm -f "$out"' EXIT
"$@" >"$out" 2>&1; rc=$?
cat "$out"
if (( rc != 0 )); then echo "vouch: exit $rc" >&2; exit "$rc"; fi
if [[ -n $forbid ]] && grep -Eq -- "$forbid" "$out"; then
  echo "vouch: exit 0, but output matched --forbid /$forbid/" >&2; exit 70; fi
if [[ -n $expect ]] && ! grep -Eq -- "$expect" "$out"; then
  echo "vouch: exit 0, but output never matched --expect /$expect/" >&2; exit 70; fi
if (( nonempty )) && [[ ! -s $out ]]; then
  echo "vouch: exit 0, but printed nothing" >&2; exit 70; fi
exit 0
```

A real non-zero passes straight through (`vouch -- jq -e . f/b.json` returned jq's own `5`). An exit-0 lie becomes `70` (`EX_SOFTWARE` in `sysexits.h`, "internal software error," which felt fair). shellcheck 0.9.0 on the runner had nothing to say about it, which is the only compliment shellcheck gives.

Every row, rerun through it:

| # | Invocation | Bare exit | Through `vouch` |
|---|---|---|---|
| 1 | `vouch --expect '^200$' -- curl -s -o got.txt -w '%{http_code}\n' URL` | `0` | ✅ `70` — "never matched --expect /^200$/" |
| 2 | `vouch --forbid 'parse error' -- find … -exec jq -e . {} \;` | `0` | ✅ `70` |
| 3 | `vouch --forbid '^null$' -- jq -r .verison v.json` | `0` | ✅ `70` |
| 4 | `vouch --forbid '^null$' -- yq .b v.json` | `0` | ✅ `70` |
| 5 | `vouch --forbid 'No local changes' -- git stash` | `0` | ✅ `70` |
| 6 | `vouch --forbid '^# tests 0$' -- node --test` | `0` | ✅ `70` |
| 7 | `vouch -- sed -i 's/verison=.*/…/' conf` | `0` | ❌ `0` — nothing to match |
| 8 | `vouch --nonempty -- cp --update=none -v src dst` | `0` | ✅ `70` — "printed nothing" |

Then the boring passes, because a check that only ever fails is just a fancier `false`: `vouch --expect '^200$'` around curl fetching the real `ok.txt`, 1,000 runs in a loop — **1,000 passed, 0 failed**. The same wrapper around the 404, 1,000 runs — **0 passed, 1,000 failed**. Both correct, both every time.

## Where it broke

Three places, and they stay in.

**Row 7 is uncatchable from the outside.** `sed` printed nothing on success *and* on the typo, so there is no regex that tells them apart. The only honest fix is to check the effect, not the command: `sed -i … conf && grep -qx 'version=2.0' conf` exited `1`, which is the first time anything in this experiment told the truth about that file. A wrapper can read output. It can't read your intent.

**Row 8 only worked by changing the command.** My first `cp` catch was a fluke: `--forbid 'warning'` tripped on coreutils' *deprecation* warning for `-n`, not on the skipped copy. The day that warning goes away, the "fix" goes with it. The real fix was `cp --update=none -v`, which prints `'src' -> 'dst2'` when it copies and nothing when it doesn't — so `--nonempty` has something real to measure. If your check depends on a tool's chattiness, make the tool chatty on purpose.

**`--forbid` is a regex, and regexes have victims too.** I ran `vouch --forbid 'error' -- ls logs` in a directory containing a file named `error-budget.md`. It printed the filename and failed with `70`. A perfectly healthy `ls`, convicted on its vocabulary. Anchor your patterns (`^null$`, `^# tests 0$`) or prefer `--expect` on the success shape — "the status line is exactly `200`" can't be fooled by a filename.

And one cost by design: `vouch` merges stderr into stdout so it can grep both, which means you can't pipe a wrapped `jq` into another `jq` and keep the streams separate. It's a guard for steps whose output you *check*, not a filter you build pipelines out of.

## The verdict

On the "survives a Tuesday" scale: `set -e` alone survives a normal Tuesday, right up until the first tool on this list shows up. With the opt-in flags each tool already ships (`curl -f`, `find … +`, `jq -e`, `git diff --exit-code`) you survive a bad Tuesday. With an output check on the steps that matter — and an effect check on the silent ones like `sed` — you survive the Tuesday where the intern renamed the test directory and the pipeline stayed green anyway.

The exit code is a claim. The output is the evidence. Read the evidence.
