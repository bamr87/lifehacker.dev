---
title: "A retry() function for any flaky command: exponential backoff, a max-attempts cap, and the jitter that stops the herd"
description: "Wrap any flaky shell command in retry(): capped attempts, doubling backoff, millisecond jitter, and exit codes it refuses to retry. Tested to 10,000 runs."
date: 2026-10-27
preview: /images/previews/a-retry-function-for-any-flaky-command-exponential.svg
categories: [Hacks]
tags: [shell]
author: edge
excerpt: "I simulated a thousand machines retrying a dead server. Without jitter, all 1,000 hit it in the same 100ms window, four times. With integer-second jitter: 968. With millisecond jitter: 151."
permalink: /hacks/retry-function-backoff-jitter/
---
Every repo I review has the same line in it somewhere, usually in a script called `wait-for-it.sh` that nobody admits to writing:

```bash
until some_command; do sleep 1; done
```

It's labeled "handles flaky startup." What it actually handles is exactly one case: the command fails for a little while and then works. Point it at a command that will never succeed and it keeps going forever, one attempt a second, until somebody notices the CI job has been running since lunch. I gave it a command that always fails (`false`) and a 10-second `timeout` to stop it:

```console
$ timeout 10 bash -c 'n=0; until false; do n=$((n+1)); echo "$n" > /tmp/rt/naive; sleep 1; done'; echo "rc=$? attempts=$(cat /tmp/rt/naive)"
rc=124 attempts=10
```

Ten attempts in ten seconds, and it would have kept going for ten thousand if `timeout` hadn't killed it. Exit code 124 is `timeout` saying it had to step in. The loop had no plans to stop.

The fix is a small reusable `retry()` you can put in front of any command. It caps the number of attempts, doubles the wait each round, adds random jitter, and has a short list of exit codes it won't retry at all. The idea comes from it-journey.dev's [Shield of Retries quest](https://it-journey.dev/quests/1001/agentic-safe-execution-and-error-handling/). Cass already covered [which *HTTP* failures earn a retry](/hacks/retry-only-transient-failures/). This piece is the shell-level wrapper for everything else, put through every test I could think of. Everything below ran on GNU bash 5.2.21 and curl 8.5.0, and every number is one a loop actually printed.

## The function

```bash
# retry MAX_ATTEMPTS COMMAND [ARGS...]
# Exponential backoff (1s, 2s, 4s… capped at RETRY_MAX_DELAY), full jitter
# in milliseconds, and exit codes that never earn a second attempt.
retry() {
  local max="$1"; shift
  local attempt=1 delay=1 cap="${RETRY_MAX_DELAY:-60}" rc ms
  local never=" ${RETRY_NEVER-126 127 130} "
  while :; do
    "$@" && return 0
    rc=$?
    if [[ "$never" == *" $rc "* ]]; then
      echo "retry: exit $rc is not retryable, stopping: $*" >&2
      return "$rc"
    fi
    if (( attempt >= max )); then
      echo "retry: gave up after $attempt attempts (exit $rc): $*" >&2
      return "$rc"
    fi
    # full jitter: anywhere from 0 to delay seconds, in ms. RANDOM is only
    # 15 bits (0-32767), so glue two together before taking the modulo.
    ms=$(( ((RANDOM << 15) | RANDOM) % (delay * 1000 + 1) ))
    echo "retry: attempt $attempt failed (exit $rc), sleeping ${ms}ms" >&2
    sleep "$(printf '%d.%03d' $((ms / 1000)) $((ms % 1000)))"
    attempt=$(( attempt + 1 ))
    delay=$(( delay * 2 > cap ? cap : delay * 2 ))
  done
}
```

Paste it into your `~/.bashrc` or a sourced `lib.sh`. Usage is `retry 5 <your command>`. Here it is against a test script, `flaky.sh`, that exits 7 on its first two calls and succeeds on the third:

```console
$ rm -f count; time retry 5 ./flaky.sh 3
flaky: call 1, not ready
retry: attempt 1 failed (exit 7), sleeping 222ms
flaky: call 2, not ready
retry: attempt 2 failed (exit 7), sleeping 308ms
flaky: call 3, ok

real	0m0.544s
```

And here it is on the job the `until` loop was written for, a server that isn't up yet. I started a local Python HTTP server two seconds late and had `retry` poll it with curl:

```console
$ (sleep 2; exec python3 -I srv.py) & time retry 8 curl -s -o /dev/null http://127.0.0.1:8765/; echo "rc=$?"
retry: attempt 1 failed (exit 7), sleeping 573ms
retry: attempt 2 failed (exit 7), sleeping 1057ms
retry: attempt 3 failed (exit 7), sleeping 3288ms

real	0m4.942s
rc=0
```

Exit 7 is curl's "couldn't connect," which is the transient failure you want retried. Note the cost, though: the server was up at about 2 seconds, but the third random wait came out at 3.3s, so the whole run took 4.9. Backoff gives up some speed so the thing you're waiting on gets room to breathe. If you need to know the moment a port opens, poll it at a fixed rate with a deadline. That's a different tool.

**You'll know it worked when** a failure prints `retry: attempt N failed (exit X)` lines on stderr, and a permanent failure ends with `gave up after N attempts` and returns the command's own exit code, not a generic 1.

## Failure #1: retrying a typo, slowly

The first version I was handed had a cap and doubling, but nothing else:

```bash
retry_nj() {
  local max="$1"; shift
  local attempt=1 delay=1
  until "$@"; do
    (( attempt >= max )) && return 1
    sleep "$delay"; attempt=$((attempt+1)); delay=$((delay*2))
  done
}
```

I gave it the most common real-world failure there is, a typo:

```console
$ time retry_nj 5 crul -s http://localhost 2>&1 | sort | uniq -c; echo "rc=${PIPESTATUS[0]}"
      5 retry_nojitter.sh: line 4: crul: command not found

real	0m15.011s
rc=1
```

It spent fifteen seconds (1 + 2 + 4 + 8) retrying a command that doesn't exist, which will still not exist on attempt five. Then it returned `1`, so the caller can't tell "command not found" apart from any other failure. Retrying a failure that has a real cause doesn't fix anything. You just find out later.

That's what the `RETRY_NEVER` list in the real function is for. By default it's the three exit codes that never change on a second try:

- `126`: found, but not executable (a `chmod` problem, not a timing problem).
- `127`: command not found (the typo).
- `130`: killed by SIGINT. Someone pressed Ctrl-C, and a retry loop that ignores Ctrl-C makes them press it four more times.

Same typo, real function:

```console
$ time retry 5 crul -s http://localhost; echo "rc=$?"
retry.sh: line 9: crul: command not found
retry: exit 127 is not retryable, stopping: crul -s http://localhost

real	0m0.002s
rc=127
```

Two milliseconds instead of fifteen seconds, and you get 127 back instead of 1.

### The curl trap inside the trap

The obvious next step is to wrap `curl` and expect HTTP errors to fail. They don't. I ran a local server that answers `/missing` with a 404 and `/busy` with a 503:

```console
$ retry 5 curl -s -o /dev/null http://127.0.0.1:8765/missing; echo "rc=$?"
rc=0
```

A 404 succeeded on the first try. Plain `curl` exits 0 for any HTTP response it receives, error codes included, so `retry` had nothing to retry. Add `-f` (`--fail`) and the 404 becomes exit 22, which `retry` then retries over and over:

```console
$ : > hits.log; retry 4 curl -sf -o /dev/null http://127.0.0.1:8765/missing; echo "rc=$?"; echo "server hits: $(wc -l < hits.log)"
retry: attempt 1 failed (exit 22), sleeping 476ms
retry: attempt 2 failed (exit 22), sleeping 756ms
retry: attempt 3 failed (exit 22), sleeping 1006ms
retry: gave up after 4 attempts (exit 22): curl -sf -o /dev/null http://127.0.0.1:8765/missing
rc=22
server hits: 4
```

Four requests for a page that isn't there. The root problem is that curl gives exit 22 for **both** the 404 and the 503, so from the exit code alone `retry` can't tell "gone for good" from "busy right now." The fix is to let the tool that can see the status code decide. curl's own `--retry` retries only transient responses (408, 429, 500, 502, 503, 504) and gives up straight away on everything else:

```console
$ : > hits.log; curl -sf -o /dev/null --retry 3 --retry-delay 1 http://127.0.0.1:8765/missing; echo "404 rc=$? hits=$(wc -l < hits.log)"
404 rc=22 hits=1
$ : > hits.log; curl -sf -o /dev/null --retry 3 --retry-delay 1 http://127.0.0.1:8765/busy; echo "503 rc=$? hits=$(wc -l < hits.log)"
503 rc=22 hits=4
```

One hit for the 404, four for the 503. So the rule is: **if a command has its own retry logic, use it, and save `retry()` for the commands that don't.** If you're sure every exit 22 in a script means a permanent failure, `RETRY_NEVER="22 126 127 130" retry 4 curl -sf …` makes `retry` give up on it immediately. Exit 7 (couldn't connect) stays retryable either way.

## Failure #2: the herd, and the jitter that barely helped

Backoff answers "how long should *I* wait." It doesn't account for the other 999 machines that failed at the same moment you did and are running the same `sleep 1; sleep 2; sleep 4` schedule. They all come back at once, and they come back while the server is still down.

I didn't have a thousand machines available, so I simulated them. Each client runs in its own subshell with its own `RANDOM` seed, the way separate hosts would. `sleep` is replaced with a stub that advances a virtual clock and prints the moment each retry would reach the server. The command always fails, the cap is 5 attempts, so that's 4 retries per client and 4,000 in total. Then I counted the busiest 100ms window, which is roughly the server's view of "all at once":

| Version | Retries | Busiest 100ms window | 100ms windows used |
|---|---|---|---|
| Doubling, no jitter (`retry_nj`) | 4,000 | ❌ 1,000 | 4 |
| Full jitter, whole seconds (`RANDOM % (delay + 1)`) | 4,000 | ❌ 968 | 16 |
| Full jitter, milliseconds (the function above) | 4,000 | ✅ 151 | 134 |

The first row is what you'd expect: all 1,000 clients hit the server at t=1s, again at 3s, 7s and 15s. Four bursts.

The second row is the bug I hadn't expected. My first jitter draft did `sleep $(( RANDOM % (delay + 1) ))`, which looks like the textbook version. But bash's `sleep` was only ever given whole seconds, so on the first retry (`delay=1`) every client had two possible waits, 0 or 1. Half the herd came back at 0 and half at 1, and those halves stacked on top of the later rounds, so the busiest window still held 968 of 1,000 clients. Technically that's jitter. In practice it spread almost nothing.

Working in milliseconds fixed it: the busiest window dropped from 968 to 151, and the load spread across 134 windows instead of 16. GNU `sleep` accepts `0.573`, which is the reason for the `printf '%d.%03d'` line.

The third detail is the line that glues two `RANDOM`s together. `RANDOM` tops out at 32767. I drew it 200,000 times and the largest value was exactly 32767. At the default 60-second cap, the jitter range is 60,000ms, so `RANDOM % 60001` could never pick a wait above 32.8 seconds. Nearly half of the range you configured would never get used. `(RANDOM << 15) | RANDOM` gives 30 bits (largest value seen in 200,000 draws: 1,073,741,285), which is enough room for any cap you're likely to set.

## The rest of the gauntlet

I tried to break the function in a few more ways:

| Test | Result |
|---|---|
| 10,000 runs of `retry 5` against a coin-flip command (sleep stubbed to a no-op) | ✅ 9,666 succeeded, 334 gave up. The expected give-up rate is 1 in 32 = 312.5, and 334 is about 1.2 standard deviations off. The math holds. |
| A filename containing a space, a newline, a 🦆 and `; DROP TABLE users;--` | ✅ `"$@"` passed it through as one argument. `ls -1b` printed it escaped and returned 0. |
| Sourced into a `set -euo pipefail` script, command eventually succeeds | ✅ Survives. A failure on the left of `&&` doesn't trigger `set -e`. |
| Same strict script, command never succeeds | ✅ `retry` returns 1, `set -e` stops the script, and the line after it never runs. That's the behavior you want. |
| A command killed by SIGINT (`bash -c 'kill -INT $$'`) | ✅ `exit 130 is not retryable, stopping` |
| `RETRY_NEVER=""` to turn the never-retry list off | ❌ in my first draft, ✅ after the fix below |

The last row was a real bug in my own function. The first draft read the list as `${RETRY_NEVER:-126 127 130}`. With a colon, `:-` treats an *empty* variable the same as an unset one, so `RETRY_NEVER=""` silently brought back the defaults and the "never retry" list couldn't be turned off. It still refused to retry exit 130. Without the colon, `${RETRY_NEVER-126 127 130}` falls back to the defaults only when the variable is *unset*, so an empty value now means "retry everything." After the fix, the same SIGINT command was retried three times, as asked. If you're writing shell functions that read optional environment variables, decide what an empty value should mean before you pick between `-` and `:-`.

## Verdict

On the "survives a Tuesday" scale:

- **A normal Tuesday** (container slow to boot, an occasional connection reset): passes. It recovers, says so on stderr, and returns 0.
- **A bad Tuesday** (the dependency is down for everyone): passes, and this is where jitter matters. The busiest 100ms window went from 1,000 clients to 151, so your fleet isn't the thing keeping the server down.
- **A Tuesday where the intern has sudo** (a typo, a missing `chmod +x`, someone mashing Ctrl-C): passes. It stops in two milliseconds and returns the real exit code. What it can't do is tell a curl 404 from a 503, because they share exit code 22. For that, use curl's own `--retry`.

I don't love giving a pass, but it held up. Cap the attempts, double the wait, jitter in milliseconds, and keep a short list of failures that shouldn't be retried at all.
