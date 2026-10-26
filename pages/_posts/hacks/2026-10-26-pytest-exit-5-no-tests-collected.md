---
title: "Your CI is red but nothing failed: pytest exits 5 when it collects zero tests"
description: "pytest returns exit code 5 when it collects no tests. Handle it on purpose: keep real failures red, allow an empty lane explicitly, and set a test-count floor."
date: 2026-10-26
preview: /images/previews/your-ci-is-red-but-nothing-failed-pytest-exits-5-w.svg
categories: [Hacks]
tags: [ci-cd, shell]
author: cass
excerpt: "A red build with zero failing tests is pytest telling the truth. The bigger risk is the convenient one-liner people use to make it go green."
permalink: /hacks/pytest-exit-5-no-tests-collected/
---
Here's the threat nobody models: the test suite that ran nothing. No assertion failed. No stack trace. Your pipeline goes red anyway, and the log has nothing in it to blame. The first instinct is to treat this as a flaky runner, or a cosmic ray, or an AWS intern tripping over a cable in us-east-1. It's none of those. It's pytest reporting that it looked for tests and found zero.

`SEVERITY: an empty directory. ATTACK VECTOR: a file named check_math.py.`

The red build isn't the risk here. The risk is what a tired human types to make it green, because the quickest fix also switches off your test gate. That's where this one gets genuinely dangerous, so I'll start with the bug and then go through the fixes, including two popular ones that are worse than the bug. The it-journey.dev [System Engineer quest report](https://it-journey.dev/quest-reports/2026-07-10-system-engineer-1000/) is where this one surfaced. Everything below I ran against pytest 9.1.1 in a throwaway directory, and the output is pasted, not typed from memory.

## Reproduce it in one command

An empty `tests/` folder, one command, and a look at the exit code:

```console
$ mkdir -p tests && pytest; echo "exit=$?"
============================= test session starts ==============================
platform linux -- Python 3.12.3, pytest-9.1.1, pluggy-1.7.0
rootdir: /tmp/demo
collected 0 items

============================ no tests ran in 0.00s =============================
exit=5
```

Exit `5`, not `0`. pytest has a documented table of exit codes, and you can print it straight from the library instead of trusting a blog post (including this one):

```console
$ python -c 'import pytest; print([(e.name, e.value) for e in pytest.ExitCode])'
[('OK', 0), ('TESTS_FAILED', 1), ('INTERRUPTED', 2), ('INTERNAL_ERROR', 3), ('USAGE_ERROR', 4), ('NO_TESTS_COLLECTED', 5), ('MAX_WARNINGS_ERROR', 6)]
```

Your CI runner only sees "not zero", and not zero means red. That's correct behavior. "I ran nothing" shouldn't be reported as "everything passed."

## Three ways to get there without trying

You rarely ship an empty folder on purpose. You get to zero collected tests in one of these ways, and I reproduced each one:

**The file doesn't match `test_*.py`.** pytest only collects files named `test_*.py` or `*_test.py` by default. I wrote a perfectly good test into a file called `check_math.py`:

```console
$ pytest -q; echo "exit=$?"

no tests ran in 0.00s
exit=5
$ mv tests/check_math.py tests/test_math.py
$ pytest -q; echo "exit=$?"
.                                                                        [100%]
1 passed in 0.00s
exit=0
```

Same test, same assertion. The filename alone decided whether it existed.

**The `-k` filter has a typo.** A keyword filter that matches nothing deselects everything:

```console
$ pytest -q -k adds_typo; echo "exit=$?"

1 deselected in 0.00s
exit=5
```

**A rename or a move.** Someone reorganizes `tests/` into `spec/`, or renames the module to match a new house style, and discovery quietly stops finding it. That's the same problem as the first case, just with a commit message attached.

In all three cases, exit 5 is doing its job. It's the only thing that tells you the gate is checking nothing.

## The two "fixes" I'd confiscate

**Confiscated fix #1: `|| true`.** It's the most convenient line in shell, and convenience is an attack surface with better marketing. I added a test that asserts `2 + 2 == 5` and ran it the way GitHub Actions runs a `bash` step (`-eo pipefail`):

```console
$ bash -eo pipefail -c 'pytest -q >/dev/null || true'; echo "step exit=$?"
step exit=0
```

A failing test, a green step. `|| true` doesn't only swallow exit 5. It swallows 1, 2, 3, 4 and 6 too, so your test gate turns into a decorative step that reports success no matter what. Any regression, including the security fix someone reverted by accident, now merges without a word.

`SEVERITY: you, six months ago. ATTACK VECTOR: a commit titled "fix ci".`

**Confiscated fix #2: the one-liner that looks right.** The usual advice is `pytest; [ $? -eq 5 ] && exit 0`. I ran it three ways, and it failed differently each time:

```console
$ bash -eo pipefail -c 'pytest -q -k nothing_matches >/dev/null; [ $? -eq 5 ] && exit 0'; echo "step exit=$?"
step exit=5
$ bash -c 'pytest -q >/dev/null; [ $? -eq 5 ] && exit 0'; echo "step exit=$?"
step exit=1
$ bash -c 'pytest -q -k nothing_matches >/dev/null; [ $? -eq 5 ] && exit 0'; echo "step exit=$?"
step exit=0
```

Under `set -e`, which is how Actions runs your `run:` block by default, pytest's exit 5 kills the shell before the `[ $? -eq 5 ]` check ever runs, so the fix does nothing. Without `-e` it's worse in a sneakier way: on a **passing** suite, `[ 0 -eq 5 ]` is false, the `&&` short-circuits, and the script ends on that false test, so a green suite gets reported as exit 1. It only works in the one case it was written for. I trust code like that about as much as a USB stick found in a parking lot.

## The payload: three mitigations, ranked

### 1. Fix discovery so "no tests" can't happen by accident

Name test files `test_*.py`, and tell pytest where they live so it doesn't wander. A `pytest.ini` at the repo root:

```ini
[pytest]
testpaths = tests
```

That also closes a quieter leak in the other direction. Before I added it, a stray `scripts_old/test_stray.py` was being collected and run alongside the real suite (`2 passed`). With `testpaths = tests`, pytest only looked in `tests/` (`1 passed`). Discovery that's pinned down can't drift silently in either direction. Check what it actually finds with `pytest --collect-only -q`:

```console
$ pytest --collect-only -q
tests/test_math.py::test_adds

1 test collected in 0.00s
```

### 2. Allow an empty lane explicitly, and only exit 5

Sometimes zero tests really is fine: a brand-new package, or a matrix lane for a component that has no tests yet. In that case, make it a decision you wrote down, not a side effect. This wrapper captures the exit code without tripping `set -e`, lets **only** 5 through, and passes every other code back unchanged:

```bash
#!/usr/bin/env bash
# run-tests.sh: treat "no tests collected" (exit 5) as OK; everything else stays real.
set -euo pipefail
rc=0
pytest "$@" || rc=$?
if [ "$rc" -eq 5 ]; then
  echo "run-tests: no tests collected; allowed for this lane" >&2
  exit 0
fi
exit "$rc"
```

The `|| rc=$?` is what makes this safe. A command on the left side of `||` doesn't trigger `set -e`, so the code is stored instead of killing the shell. I ran all four outcomes through it:

```console
$ ./run-tests.sh -q >/dev/null; echo "exit=$?"                       # passing suite
exit=0
$ ./run-tests.sh -q -k nothing_matches >/dev/null; echo "exit=$?"    # zero collected
run-tests: no tests collected; allowed for this lane
exit=0
$ ./run-tests.sh -q >/dev/null; echo "exit=$?"                       # with the 2 + 2 == 5 test
exit=1
$ ./run-tests.sh -q --no-such-flag >/dev/null 2>&1; echo "exit=$?"   # usage error
exit=4
```

Pass stays 0, empty becomes 0 **with a message in the log**, failure stays 1, and a broken command line stays 4. Use it only in the lanes where an empty run is legitimate. Your main suite should keep the bare `pytest` and its honest exit 5.

### 3. Set a floor, because exit 5 only catches *zero*

This is the one I lose sleep over. Exit 5 protects you when a filter matches nothing. It does nothing when a filter matches *one* thing. With four tests in the suite, `-k t1` runs a single test, passes, exits 0, and your pipeline happily reports green after checking a quarter of what it should. So assert a minimum:

```bash
#!/usr/bin/env bash
# floor.sh: fail if pytest would collect fewer than MIN_TESTS tests.
set -euo pipefail
min=${MIN_TESTS:-1}
n=$(pytest --collect-only -q "$@" | grep -c '::' || true)
if [ "$n" -lt "$min" ]; then
  echo "floor: collected $n test(s), expected at least $min" >&2
  exit 1
fi
echo "floor: collected $n test(s)"
```

```console
$ MIN_TESTS=4 ./floor.sh; echo "exit=$?"
floor: collected 4 test(s)
exit=0
$ MIN_TESTS=4 ./floor.sh -k t1; echo "exit=$?"
floor: collected 1 test(s), expected at least 4
exit=1
$ MIN_TESTS=4 ./floor.sh -k typo; echo "exit=$?"
floor: collected 0 test(s), expected at least 4
exit=1
```

The `|| true` here is allowed, and only because of where it sits. It guards `grep -c` (which exits 1 when it counts zero matches) and the pipeline's exit 5, and the very next line checks the number it produced. A `|| true` with a check right after it is fine. A `|| true` with nothing after it is the problem from confiscated fix #1. Set `MIN_TESTS` a little under your real count and raise it when the suite grows. It's one number in your CI config, and it's the only one of these three checks that notices a suite that got smaller.

## When this goes wrong

- **The floor drifts stale.** If you delete tests on purpose, the floor fails, and that's the point. Lower it in the same PR so a reviewer sees the suite shrink and has to sign off on it.
- **`--collect-only` counts parametrized cases.** `test_x[a]` and `test_x[b]` each contain `::`, so they count as two. That's what pytest runs, so it's the right number. Just don't set the floor from a hand count of `def test_` lines.
- **The wrapper ends up on the main suite.** Once `run-tests.sh` exists, someone will use it everywhere because it's convenient. Keep it in the lanes that truly can be empty. Everywhere else, exit 5 is a smoke alarm, so don't take its batteries out.

None of these is "be more careful." They're a two-line config and two ten-line scripts, and I ran every one of them. Your test suite is a security control. Make sure it's actually running tests.
