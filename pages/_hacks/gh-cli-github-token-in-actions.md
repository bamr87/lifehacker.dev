---
title: "The gh CLI doesn't get GITHUB_TOKEN for free: set GH_TOKEN in env"
description: "Your Actions job has a token, but gh can't see it. The one env line that fixes 'GitHub CLI is not authenticated' — and why a present secret isn't enough."
date: 2025-07-10
preview: /assets/images/previews/github-actions-authentication-fix-resolving-ci-cd-.png
collection: hacks
author: amr
excerpt: "GitHub Actions hands every job a token. It does not hand that token to the gh CLI. Here's the one-line bridge — and the failure that made it obvious."
tags: [github-actions, gh-cli, ci-cd, authentication]
---

![A retro terminal showing a GitHub Actions authentication error](/assets/images/previews/github-actions-authentication-fix-resolving-ci-cd-.png)

The script worked on your laptop. You ran it forty times. Then it hit CI and died on the first command that touched GitHub, with a message that reads like the runner has never heard of you:

```
❌ [ERROR] GitHub CLI is not authenticated
❌ [ERROR]    Run: gh auth login
💀 Some required prerequisites are missing.
```

`gh auth login` opens a browser and waits for you to paste a code. There is no browser in a GitHub Actions runner. There is no you. The advice is correct and completely impossible to follow, which is the most CI error of all CI errors.

Here is the part that makes you doubt your sanity: the workflow *has* a token. GitHub Actions mints one for every job automatically and drops it in `secrets.GITHUB_TOKEN`. You used it in the checkout step. It's right there.

It's right there, and `gh` cannot see it.

## Why the token is invisible

`secrets.GITHUB_TOKEN` exists, but a secret is not an environment variable. The `actions/checkout` step gets it because you (or the action's defaults) hand it over explicitly:

{% raw %}
```yaml
- uses: actions/checkout@v4
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
```
{% endraw %}

That `with:` block passes the token to *that one step*. It does not leak into the shell environment of your other steps. So when a later step runs the `gh` CLI, the CLI looks for its credentials the only way it knows how: it reads the `GH_TOKEN` environment variable, then `GITHUB_TOKEN`, then a stored login from `gh auth login`. None of those exist in the job's environment. The secret is sitting in the vault; nobody handed `gh` the key.

The fix is to put the token where `gh` actually looks.

## The one line

Set `GH_TOKEN` in the workflow (or job, or step) `env` from the secret:

{% raw %}
```yaml
env:
  GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```
{% endraw %}

That's the whole bridge. `secrets.GITHUB_TOKEN` is the secret; `GH_TOKEN` is the environment variable the CLI reads. The line copies one into the other so every step under that `env` scope runs with `gh` already authenticated.

In context, at the workflow level so it covers every job:

{% raw %}
```yaml
name: ci
on: [push]

permissions:
  contents: read
  issues: write          # match this to what gh actually does

env:
  GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: gh issue list --limit 5
```
{% endraw %}

### You'll know it worked when

The step that was dying on `gh auth login` now runs clean. If you want an explicit tell before the real command, drop in a status check:

```yaml
- run: gh auth status
```

A green run prints something like `Logged in to github.com account ... (GH_TOKEN)` — note it tells you *which* source it used. If it still says "not logged in," the `env` line didn't reach that step's scope (see the scope trap below).

## If your script gatekeeps on the token itself

A lot of CI scripts run a prerequisite check before doing real work, and a common version of that check only looks for *one* token variable — usually a personal access token the author used locally. In CI that variable is empty, so the check fails even though `gh` itself would have been fine.

If you control that script, widen the check to accept any of the names a token might arrive under, and report which one it found so future-you can debug it in one read instead of three:

```bash
# Accept GH_TOKEN, a personal token, or the Actions-provided GITHUB_TOKEN.
if   [ -n "${GH_TOKEN:-}" ];     then token_source="GH_TOKEN"
elif [ -n "${GITHUB_PAT:-}" ];   then token_source="GITHUB_PAT"
elif [ -n "${GITHUB_TOKEN:-}" ]; then token_source="GITHUB_TOKEN"
else token_source=""
fi

if [ -n "$token_source" ]; then
    echo "pass: GitHub auth configured (via $token_source)"
else
    echo "fail: set GH_TOKEN, GITHUB_PAT, or GITHUB_TOKEN"
    exit 1
fi
```

The `${VAR:-}` form matters: under `set -u` (which any script that respects itself runs with), a bare `$GH_TOKEN` on an unset variable aborts the script before your check even runs. The `:-` gives it an empty default so the `-n` test can do its job.

## The part where it broke

The first fix attempt looked complete and still failed, and the reason is `env:` scope.

If you put `GH_TOKEN` only inside one step's `env`, it covers that step and nothing else:

{% raw %}
```yaml
steps:
  - run: gh issue list
    env:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}   # only THIS step is authed

  - run: gh pr list                            # this one is NOT — different step
```
{% endraw %}

The second `gh` call is back to square one, with the same "not authenticated" error, in a step you swore you already fixed. Step-level `env` does not carry forward. Put the line at the **workflow level** (top of the file) or the **job level** if you want it to apply to every step; reserve step-level `env` for the rare case where you deliberately want a *different* token (say a PAT with extra scopes) for one specific command.

The second thing that bites: a present token is not the same as a *permitted* one. `GITHUB_TOKEN` only has the scopes your `permissions:` block grants. If `gh` authenticates fine but then a write fails with `HTTP 403`, the token is being seen — it isn't allowed to do that thing. Add the scope (`issues: write`, `pull-requests: write`, `contents: write`) to `permissions:`. Auth and authorization are two different failures that look similar; the 403 is the one telling you it's the second.

## The honest accounting

This saves you exactly one line of YAML's worth of typing, which is to say it saves you nothing measurable. What it actually saves is the forty-minute detour where you stare at a token that exists, in an environment that has it, in front of a CLI that swears it's missing, while the error politely suggests you open a browser that isn't there.

Two facts, written down so you don't relearn them at 1 a.m.:

- A secret is not an environment variable. `gh` reads `GH_TOKEN` / `GITHUB_TOKEN` from the environment, so you have to put it there.
- `env:` scope is local. Workflow-level reaches everything; step-level reaches one step.

Set the line at the top, match `permissions:` to what `gh` does, and let the runner authenticate itself.
