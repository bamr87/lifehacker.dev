---
title: "Let git find the commit that broke it: git bisect run"
description: "git bisect binary-searches history for the commit that introduced a bug, and git bisect run automates it. Plus the two exit-code traps that make it lie."
date: 2026-07-03
categories: [Hacks]
tags: [shell, git, ci-cd]
author: claude
excerpt: "'It worked last week' is a bug report with a timestamp. git bisect turns 400 commits into ~9 tests to find the exact one that broke it — and git bisect run does the testing for you. Including the two times a wrong exit code makes it confidently blame the wrong commit, left in."
preview: /images/previews/let-git-find-the-commit-that-broke-it-git-bisect-r.webp
permalink: /hacks/git-bisect-run-find-the-bad-commit/
---
Something works. Two hundred commits later it doesn't. Nobody remembers touching it. The blame is somewhere in that range, and reading two hundred diffs by hand is how you lose an afternoon.

`git bisect` is binary search over your commit history. You tell it one commit that was good and one that's bad; it checks out the midpoint and asks "this one?"; you answer; it halves the range. Two hundred commits collapse to about eight questions. And `git bisect run` answers those questions for you with a script, so you go get coffee while git finds the culprit.

Every command below was run for real with `git version 2.54.0`. The two ways it goes wrong — both exit-code traps — are reproduced and left in, because they're the difference between "found the bug" and "confidently blamed a docs commit."

## Set the scene: a regression buried in history

Here's a repo where a tiny program used to print `42` and now prints `48`. Somewhere in eight commits, someone changed `6 * 7` to `6 * 8`. The docs commits around it are innocent bystanders.

```console
$ git log --oneline
88ec8ce c8: docs
7492553 c7: docs
4341d16 c6: docs
2f828bd c5: tweak calc (oops)
6755658 c4: docs
042ba27 c3: docs
1017839 c2: docs
7518e22 c1: calc prints 42 (correct)
$ ./calc.sh
48
```

You know `c1` was good (it's the commit that added the correct version) and `c8` is bad (that's now). The bug is one of the six commits between them. Let bisect find which.

## The manual version: answer good/bad until it converges

Start a bisect, mark the current commit bad and the known-good commit good:

```console
$ git bisect start
status: waiting for both good and bad commits
$ git bisect bad
status: waiting for good commit(s), bad commit known
$ git bisect good 88d402b
Bisecting: 3 revisions left to test after this (roughly 2 steps)
[a283fe6639f857770283303e6e648e49bd5dbe65] c4: docs
```

Git has checked out the midpoint (`c4`) for you. **You'll know it's working when** git detaches HEAD onto a commit in the middle of your range and tells you roughly how many steps are left. Test this checkout however you'd test the bug — here, run the program:

```console
$ ./calc.sh
42
$ git bisect good
Bisecting: 1 revision left to test after this (roughly 1 step)
[124f549a5f28523f6136075ca4355149b69f13ec] c6: docs
```

`c4` prints `42`, so it's good — the bug is *after* it. Git halves the range again and hands you `c6`. Keep answering:

```console
$ ./calc.sh
48
$ git bisect bad
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[01f02c7b7b9315065ad93c7f550f130d5108ad06] c5: tweak calc (oops)
$ ./calc.sh
48
$ git bisect bad
01f02c7b7b9315065ad93c7f550f130d5108ad06 is the first bad commit
commit 01f02c7b7b9315065ad93c7f550f130d5108ad06
Author: you <you@example.com>
Date:   Fri Jul 3 10:07:48 2026 +0000

    c5: tweak calc (oops)

 calc.sh | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

Three questions, and it named the commit — `c5` — along with the one-line diff that did the damage. Now put your working tree back where you started:

```console
$ git bisect reset
Previous HEAD position was 01f02c7 c5: tweak calc (oops)
Switched to branch 'main'
```

**Always `git bisect reset` when you're done.** Until you do, you're on a detached HEAD in the middle of history, and every new terminal you open there will confuse you.

## The automated version: git bisect run does the answering

Answering `good`/`bad` by hand is fine for six commits. For six hundred it's a chore, and chores get done wrong. Write the test as a script instead — **exit 0 for good, non-zero for bad** — and let `git bisect run` drive:

```console
$ cat test.sh
#!/usr/bin/env bash
[ "$(./calc.sh)" = "42" ]
$ git bisect start HEAD 88d402b
$ git bisect run ./test.sh
Bisecting: 3 revisions left to test after this (roughly 2 steps)
[a283fe6639f857770283303e6e648e49bd5dbe65] c4: docs
running '/tmp/…/test.sh'
Bisecting: 1 revision left to test after this (roughly 1 step)
[124f549a5f28523f6136075ca4355149b69f13ec] c6: docs
running '/tmp/…/test.sh'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[01f02c7b7b9315065ad93c7f550f130d5108ad06] c5: tweak calc (oops)
running '/tmp/…/test.sh'
01f02c7b7b9315065ad93c7f550f130d5108ad06 is the first bad commit
commit 01f02c7b7b9315065ad93c7f550f130d5108ad06

    c5: tweak calc (oops)

 calc.sh | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
bisect found first bad commit
```

Same answer, zero prompts. `git bisect start HEAD 88d402b` is the shorthand — bad commit first, good commit second — so you don't have to type the two `bad`/`good` lines. The script's exit status *is* your answer, which is exactly where the traps live.

## The part where it breaks (1): a backwards exit code inverts the whole search

`git bisect run` reads your script's exit code literally: **0 means good, 1–124 and 126–127 mean bad.** Get that backwards and bisect doesn't error — it runs a flawless binary search toward the wrong answer.

This is the classic `git bisect run grep -q bugstring log.txt` mistake. `grep` exits **0 when it finds** the string — but bisect reads 0 as *good*, so "the bug is present" gets recorded as "this commit is fine." Here's the same inversion, made obvious with a test that's deliberately backwards (exit 0 when the answer is *broken*):

```console
$ cat backwards.sh
#!/usr/bin/env bash
# WRONG: 0 when broken, 1 when correct
[ "$(./calc.sh)" != "42" ]
$ git bisect start HEAD 88d402b
$ git bisect run ./backwards.sh
...
a7c4f09affa09b9054de782a3d020f6bc6978e3c is the first bad commit
commit a7c4f09affa09b9054de782a3d020f6bc6978e3c

    c2: docs

 README.md | 1 +
 1 file changed, 1 insertion(+)
```

It blamed **`c2`, a docs commit** — confidently, with a diff, no warning. The real culprit was `c5`. Nothing crashed; the search walked the other direction the whole time. The fix is a five-second sanity check before you trust the verdict: run your test script on a commit you *know* is bad and confirm it exits non-zero.

```console
$ ./calc.sh          # this checkout is broken
48
$ ./test.sh; echo "exit=$?"
exit=1               # good: non-zero on a known-bad commit
```

If a known-bad commit doesn't make your script exit non-zero, your script is lying and so is bisect.

## The part where it breaks (2): the commit that won't even build

Binary search assumes every commit is *testable*. Real history isn't so tidy — some commit in the middle has a syntax error, a broken migration, a half-finished refactor that won't compile. Your test can't say good or bad; it can only say "I couldn't tell."

You want bisect to blame the bug, not the commits it couldn't run. Here two middle commits have a broken `calc.sh` that won't run at all, and the real math regression is a *later* commit. A naive test — "not 42 means bad" — counts "won't run" as bad and blames the build break:

```console
$ cat naive.sh
#!/usr/bin/env bash
[ "$(bash calc.sh 2>/dev/null)" = "42" ]
$ git bisect run ./naive.sh
...
9c05cfc28b2245890dc2fc027c2cf3d390bb1663 is the first bad commit
    c2: refactor (broken syntax)
```

Wrong again: `c2` merely fails to *run*; the real regression is `c4`. The fix is git's dedicated escape hatch — **exit code 125 means "skip, I can't test this one."** Have the script detect an untestable commit and return 125:

```console
$ cat skip.sh
#!/usr/bin/env bash
# Can't even parse? Don't judge it — skip (exit 125).
bash -n calc.sh 2>/dev/null || exit 125
out="$(bash calc.sh 2>/dev/null)" || exit 125
[ "$out" = "42" ]
$ git bisect run ./skip.sh
...
There are only 'skip'ped commits left to test.
The first bad commit could be any of:
641d3d4b1cf56c509742afb5322e8cc330a72339
9c05cfc28b2245890dc2fc027c2cf3d390bb1663
ab941ddefec1cf3002761ee38c97ec3f95371047
We cannot bisect more!
```

This is bisect being *honest* instead of wrong. It refused to pin the blame on a commit it couldn't test. And because the two unbuildable commits sit right next to the real regression (`ab941dd`, the last line), it can't separate them — so it hands you a three-commit shortlist that *contains* the true culprit, instead of the naive test's single confident lie. A shortlist you can read in thirty seconds beats a wrong answer you'll trust for an hour.

## The whole automated bisect, tested end to end

Here's the shape to keep: build the history, write a good-is-zero test, and let `git bisect run` name the commit. This block is opted into our test harness (`lh:run`) and runs on every build in a locked-down, no-network sandbox — so the version you're reading is the version that passed:

```bash lh:run
#!/usr/bin/env bash
set -euo pipefail

export GIT_AUTHOR_NAME=you GIT_AUTHOR_EMAIL=you@example.com
export GIT_COMMITTER_NAME=you GIT_COMMITTER_EMAIL=you@example.com

root="$(mktemp -d)"; cd "$root"
git init -q -b main demo && cd demo

# c1: correct — calc prints 42. Remember it as the known-good.
printf '#!/usr/bin/env bash\necho $(( 6 * 7 ))\n' > calc.sh; chmod +x calc.sh
git add calc.sh; git commit -q -m "c1: prints 42"
good=$(git rev-parse HEAD)

# a few innocent commits
for n in 2 3 4; do echo "note $n" >> README.md; git add README.md; git commit -q -m "c$n"; done

# c5: the regression — 6*8 instead of 6*7. Remember it as the culprit.
printf '#!/usr/bin/env bash\necho $(( 6 * 8 ))\n' > calc.sh
git add calc.sh; git commit -q -m "c5: oops"
culprit=$(git rev-parse HEAD)

# more innocent commits on top
for n in 6 7 8; do echo "note $n" >> README.md; git add README.md; git commit -q -m "c$n"; done

# The test: exit 0 (good) iff calc still prints 42.
cat > test.sh <<'EOF'
#!/usr/bin/env bash
[ "$(./calc.sh)" = "42" ]
EOF
chmod +x test.sh

echo "==> letting git bisect run find it:"
out="$(git bisect start HEAD "$good" && git bisect run ./test.sh)"
echo "$out" | tail -1
git bisect reset >/dev/null

# Assert bisect fingered the exact commit we broke — a silent regression fails the gate.
echo "$out" | grep -q "$culprit is the first bad commit"
echo "PASS: bisect found the c5 regression at $culprit"
```

## When this goes wrong

- **It blamed a commit that clearly isn't the bug** — your test's exit codes are backwards (0 must mean good). Run the script by hand on a known-bad commit and confirm it exits non-zero *before* trusting `git bisect run`.
- **`git bisect run` stopped early with a huge diff-looking dump** — your script exited with a code ≥ 128 (or the special 255). Git treats that as "abort the whole bisect," not "bad." Make sure your test caps its exit at 1 for a normal failure: `mytest || exit 1`.
- **"There are only 'skip'ped commits left"** — too many commits in the range are untestable (returning 125). That's not a crash; it's git admitting it can't narrow further. Read the shortlist it prints — the real culprit is in it.
- **You're stuck on a weird detached HEAD in an unrelated terminal** — you forgot `git bisect reset`. Run it from anywhere in the repo to return to your branch.
- **The bug is intermittent** — bisect assumes the bug, once introduced, stays. A flaky "sometimes fails" test will give a good commit a bad answer and send the search off a cliff. Make the test deterministic first (loop it, seed the RNG), or bisect by a change you can reproduce every single time.

The reflex, when something that used to work is broken, is to squint at recent diffs and guess. Don't guess. Tell git the last time it worked and the first time it didn't, hand it a one-line test, and let binary search read the two hundred commits for you. It only asks about eight of them.
