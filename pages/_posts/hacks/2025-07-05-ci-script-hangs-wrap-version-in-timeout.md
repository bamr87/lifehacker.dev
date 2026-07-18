---
title: "Why your CI script hangs forever: wrap --version in timeout"
description: "A version check that runs fine locally can hang a GitHub Actions job until it times out. Bound it with coreutils timeout, and stop set -e from killing it."
date: 2025-07-05
categories: [Hacks]
tags: [shell, ci-cd]
author: amr
excerpt: "The script worked locally and hung in CI. The fix is one word — timeout — plus the set -e gotcha that turns a survivable stall into a dead job."
preview: /assets/images/previews/debugging-github-actions-workflows-ai-assisted-tro.png
permalink: /hacks/ci-script-hangs-wrap-version-in-timeout/
---
A workflow that ran clean for months started hanging. Not failing — hanging. The job would sit there, the spinner spinning, until GitHub's six-hour ceiling killed it and billed you for the wait. No error. No stack trace. One step that never finished.

The script ran fine on a laptop. It ran fine in a local container. It only hung in CI. That combination is the tell, and the culprit was a line nobody looks at twice: a prerequisite checker calling `some-tool --version` to log which version was installed.

![A retro terminal depicting a stalled, hanging CI job](/assets/images/previews/debugging-github-actions-workflows-ai-assisted-tro.png)

## Why `--version` hangs in CI and not on your machine

`--version` is supposed to print a line and exit. Most tools do. But some read from standard input first, or block waiting for a TTY, or pop a pager. On your laptop none of that bites, because you have a real terminal attached. In CI there is no TTY, stdin is whatever the runner handed it, and a tool that waits for input that never comes will wait forever.

You don't get to audit every binary on the runner for this behavior. What you can do is refuse to wait more than a few seconds for any of them.

## The fix: bound every external call with `timeout`

`timeout` is part of coreutils — it's already on the runner. You hand it a duration and a command; if the command outlives the duration, `timeout` kills it and exits with code `124`.

```bash
# a command that never returns, killed after 2 seconds:
timeout 2 sleep 5
echo "exit=$?"

# the same wrapper when the command finishes in time:
timeout 2 sleep 1
echo "exit=$?"
```

We ran that. Real output:

```text
exit=124
exit=0
```

Exit `124` is `timeout`'s signature for "I had to kill it." Exit `0` is the command finishing on its own with time to spare. That `124` is the difference between a job that fails in two seconds with a clear cause and a job that hangs until the platform's patience runs out.

So the version probe becomes:

```bash
version=$(timeout 3 "$cmd" --version 2>/dev/null | head -n1)
```

You'll know it worked when a misbehaving tool stops your step in three seconds instead of stalling the whole run.

## The part where it broke

Here is the bug the obvious fix still has, and we left it in because it cost real time to find.

The tidy one-liner is `timeout 3 "$cmd" --version | head -n1 || echo "Version unknown"`. The idea is: if the probe fails, fall back to a placeholder. It does not work, and `head` is why.

```bash
cd "$(mktemp -d)"
mkdir -p bin
printf "%s\n" "#!/bin/bash" "sleep 600" > bin/sulky   # a tool whose --version hangs
chmod +x bin/sulky
export PATH="$PWD/bin:$PATH"

# Naive: timeout 3 sulky --version | head -n1 || echo fallback
v=$(timeout 3 sulky --version 2>/dev/null | head -n1 || echo "version unknown")
echo "got: [${v}]"
echo "pipestatus: ${PIPESTATUS[*]}"
```

We ran that. Real output:

```text
got: []
pipestatus: 0
```

The fallback never fired and `$v` came out **empty**. In a pipeline the exit code is the *last* command's — `head` — and `head` succeeded reading zero bytes. `timeout` killed the tool with `124`, but that code lives in `${PIPESTATUS[0]}`, not `$?`, so the `|| echo` saw success and stayed quiet. You get an empty version string and no warning that anything timed out.

Capture the exit code directly instead of piping through `head` and hoping:

```bash
cd "$(mktemp -d)"
mkdir -p bin
printf "%s\n" "#!/bin/bash" "sleep 600" > bin/sulky
chmod +x bin/sulky
export PATH="$PWD/bin:$PATH"

probe() {
  local out
  out=$(timeout 3 "$1" --version 2>/dev/null)   # no pipe, so $? is timeout's
  local rc=$?
  if [ "$rc" -eq 124 ]; then echo "version unknown (timed out)"; return; fi
  printf '%s\n' "$out" | head -n1
}
echo "got: [$(probe sulky)]"
```

We ran that. Real output:

```text
got: [version unknown (timed out)]
```

Now the timeout is visible. Run `timeout` with nothing downstream to swallow its exit code, read `$?` immediately, *then* trim with `head`.

## The other half: `set -e` turns a stall into a dead job

The script that hung had `set -euo pipefail` at the top — usually good hygiene. But with `set -e`, any non-zero exit aborts the script, and a timed-out probe exits `124`. So the moment `timeout` does its job and kills a hanging version check, `set -e` kills your whole script — right where you wanted it to recover and move on.

```bash
echo "# With set -e, a timeout kill (124) aborts the whole script:"
bash -c '
set -e
echo before
timeout 2 sleep 5
echo after            # never prints
'
echo "set -e script exited $?, before its work was done"

echo
echo "# Guard the probe, and the script survives:"
bash -c '
echo before
timeout 2 sleep 5 || echo "probe gave up, moving on"
echo after            # prints
'
echo "resilient script exited $?"
```

We ran that. Real output:

```text
# With set -e, a timeout kill (124) aborts the whole script:
before
set -e script exited 124, before its work was done

# Guard the probe, and the script survives:
before
probe gave up, moving on
after
resilient script exited 0
```

Two ways out, depending on what you want:

- **Keep `set -e`, but make the probe a non-event.** Append `|| true` (or a real fallback) to the timeout call so a kill counts as handled, not as failure. The script reads `124`, shrugs, continues.
- **Drop `set -e` for the section that probes optional tools.** A prerequisite checker's whole job is to survey what's present and report it. That is the opposite of fail-fast. Track problems in your own flag (`PREREQ_FAILED=1`) and decide at the end whether to exit non-zero, instead of letting one slow `--version` abort the survey on line three.

Neither is "turn off error handling." Both are: a probe that's *allowed* to fail shouldn't be wired to a mechanism that treats every failure as fatal.

## You'll know it worked when

- A misbehaving tool fails your step in seconds with exit `124`, instead of hanging until the platform's timeout.
- Your fallback string actually appears in the logs when a probe dies — not an empty value.
- One slow optional dependency no longer takes the whole prerequisite check down with it.

## The honest accounting

This doesn't make anything faster. A version check that completes in 40 milliseconds completes in 40 milliseconds with or without `timeout` wrapped around it. The wrapper earns its keep exactly once: the day a tool decides to hang, when it converts a six-hour billed stall into a two-second, clearly-labeled failure.

That's the whole trade. You pay one word per external call — `timeout 3` — and in exchange no single binary on the runner can ever hold your pipeline hostage again. Wrap the calls. Read the exit code before you pipe it anywhere. And don't let `set -e` mistake a probe that gave up on purpose for a script that broke.
