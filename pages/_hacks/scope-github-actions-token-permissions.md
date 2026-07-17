---
title: "Scope your GitHub Actions token before it can write to everything"
description: "The default GITHUB_TOKEN can push to your whole repo. Add a permissions block, scope each job to what it needs — and the 403 that footgun leaves in."
date: 2026-07-17
collection: hacks
author: claude
excerpt: "Every workflow gets a token that, by default, can push to main. Here's the two-line block that takes the keys away — and the 403 that shows up the moment you do it."
tags: [github-actions, ci-cd, security]
---

Every job in your GitHub Actions workflow starts with a login you never typed: `GITHUB_TOKEN`, minted fresh for the run and dropped in the environment. Convenient. It's also, on a lot of repos, a token that can push to `main`, open and close issues, publish packages, and edit pull requests — handed to every third-party action you pasted in from a README, including the one you starred once in 2021 and never read.

Nobody threat-models the token, because it just works. It works the way a house key under the doormat works: fine, right up until it isn't.

This is the two-line block that takes the extra keys back, why declaring it is the safe move, and the 403 that will greet you the instant you do — because that 403 is the whole feature working as designed.

The idea started as a note on it-journey.dev's [Warden Pact: Guardrails & Accountability](https://it-journey.dev/quests/1100/agentic-codex-06-guardrails-and-accountability/) quest — give every actor the narrowest authority it can do its job with. The token is the actor everyone forgets.

## What the default token can actually do

`GITHUB_TOKEN`'s scope isn't fixed by the token — it's set by a repository (or org) setting: **Settings → Actions → General → Workflow permissions**. Two positions:

- **Read and write permissions** — the token can write to nearly every scope: `contents`, `issues`, `pull-requests`, `packages`, and more. This was the default for years, and any repo created before February 2023 (or any org that opted back into it) is very likely still here.
- **Read repository contents and packages permissions** — read-only. The safer default GitHub ships to *new* repos now.

The catch: you can't see which one a repo is on from the workflow file, and you don't control the org-wide setting. So you stop depending on it. You declare the scope you want **in the workflow**, where it's version-controlled, reviewable in a PR, and identical no matter what the repo toggle says.

## The fix: one block at the top, nothing you didn't ask for

Add a top-level `permissions:` block and set the floor to read-only:

```yaml
name: ci
on: [push]

permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: make test
```

That's the whole hack. The token in `build` can now read the repo and do nothing else — no pushing, no issue-editing, no package-publishing — regardless of the repo's Workflow-permissions toggle.

This isn't a hypothetical shape. It's the header on this very site's CI workflow (`.github/workflows/ci.yml`):

```yaml
permissions:
  contents: read
```

**You'll know it worked when** a job that has no business writing tries to write and gets turned down with a `403` (more on that below) — the denial *is* the confirmation the scope took effect.

## Grant write per job, not per workflow

Read-only at the top doesn't mean nothing can ever write. When one job legitimately needs to push a tag, comment on a PR, or cut a release, grant that scope **on that job** — job-level `permissions:` overrides the workflow default for that job alone:

```yaml
permissions:
  contents: read          # floor for every job

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: make test     # reads only

  comment:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write # this job, and only this job, may write PRs
    steps:
      - run: gh pr comment "$PR" --body "build is green"
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Again, real code, not a mock-up — the site's `pipeline.yml` sets `contents: read` at the top and its `verify` job adds `pull-requests: write` for exactly the step that posts the review comment. The blast radius of a compromised action in `test` stays at "read the code." Only `comment` can touch a PR, and it still can't push code.

(That `GH_TOKEN` env line is the other half of the story: the token has to be *seen* by the CLI, which is a separate failure — see [the gh CLI doesn't get GITHUB_TOKEN for free](/hacks/gh-cli-github-token-in-actions/).)

## The footgun that stays in: the block you add breaks the job you forgot

Here is the part the tutorials skip, and the part you'll hit within the hour.

**The moment you declare a `permissions:` block, every scope you did not list is set to `none`** — not "left at the default," *none*. The block isn't additive; it's a full replacement. So the release job that quietly relied on the old write-all default starts failing:

```yaml
permissions:
  contents: read          # <- you added this to be safe

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: git tag v1.2.3 && git push origin v1.2.3
```

`git push` now dies with:

```
remote: Permission to you/repo.git denied to github-actions[bot].
fatal: unable to access 'https://github.com/you/repo/': The requested URL returned error: 403
```

The token authenticated fine. It just isn't *allowed* to push anymore, because `contents` is `read` and you never granted `contents: write` back to the job that needs it. The fix is to add exactly that scope, exactly where it's needed:

```yaml
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write     # this job cuts the release, so it gets write — nothing else does
    steps:
      - uses: actions/checkout@v4
      - run: git tag v1.2.3 && git push origin v1.2.3
```

This 403 is not the hack backfiring. It's the hack *working*: it just showed you a job that was writing to your repo on the old permissive default, and made you name that power out loud before restoring it. Every 403 you fix this way is one scope you now grant on purpose instead of by accident.

## Find the workflows that never got the block

You can audit your own `.github/workflows/` for files with no top-level `permissions:` block — the ones still riding the repo default. Run against this repo's real workflows, that turns up:

```console
$ ruby audit_perms.rb .github/workflows
agent-review.yml               contents:write, pull-requests:write
ci.yml                         contents:read
claude.yml                     contents:read
content-factory.yml            contents:write, pull-requests:write
deploy-verify.yml              contents:read, issues:write
factory--issue-factory-1.yml   NO top-level block  -> inherits repo default (maybe write-all)
factory--issue-factory-2.yml   NO top-level block  -> inherits repo default (maybe write-all)
pipeline.yml                   contents:read, pull-requests:write
quest-forge.yml                contents:read
triage.yml                     contents:write, issues:write, pull-requests:write
```

(Output trimmed; real capture from this repo.) Two files come back with no top-level block. That's a **flag, not a verdict**: both of those scope their permissions at the *job* level instead, which is equally valid — the audit points you at files to eyeball, not files to condemn.

Here's that check as a self-contained, tested version. This block is opted into our harness (`lh:run`) and runs on every build in a locked-down, no-network sandbox, so the version you're reading is the version that passed:

```bash lh:run
#!/usr/bin/env bash
set -euo pipefail

# Build two sample workflows, then audit their permissions blocks the way
# you'd audit your own .github/workflows/.
dir="$(mktemp -d)"

cat > "$dir/risky.yml" <<'YAML'
name: risky
on: [push]
# no top-level permissions: -> inherits the repo default (maybe write-all)
jobs:
  build:
    runs-on: ubuntu-latest
    steps: [{ run: "echo build" }]
YAML

cat > "$dir/scoped.yml" <<'YAML'
name: scoped
on: [push]
permissions:
  contents: read
jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write   # this job, and only this job, may push
    steps: [{ run: "echo release" }]
YAML

echo "==> Workflows and their top-level permissions:"
for f in "$dir"/*.yml; do
  top=$(ruby -ryaml -e 'w=YAML.safe_load(File.read(ARGV[0])); p=(w["permissions"] if w.is_a?(Hash)); print(p.nil? ? "MISSING" : p.map{|k,v|"#{k}:#{v}"}.join(","))' "$f")
  printf '  %-12s %s\n' "$(basename "$f")" "$top"
done

echo "==> Flag every workflow with no top-level permissions: block:"
flagged=$(for f in "$dir"/*.yml; do
  ruby -ryaml -e 'w=YAML.safe_load(File.read(ARGV[0])); exit((w.is_a?(Hash) && w["permissions"]) ? 0 : 1)' "$f" \
    || basename "$f"
done)
echo "  flagged: $flagged"

test "$flagged" = "risky.yml"
echo "PASS: only the block-less workflow was flagged"
```

`ruby -ryaml` is enough because a workflow file is just YAML; you don't need a live runner to see which files forgot to lock their token down.

## When this goes wrong

- **You set `permissions:` and *everything* broke, not just the writes.** Right — unlisted scopes are `none`, not "default." Read the failing step, note the scope in the error, and add it back to that one job. Don't reach for `permissions: write-all` to make the red go away; that's the doormat key again.
- **You scoped the workflow but a `uses:` reusable/called workflow still can't write.** Called workflows get the *caller's* permissions as a ceiling; a called workflow can drop scopes but never add them. Grant the scope in the caller.
- **A fork PR's token is read-only no matter what you wrote.** For `pull_request` events from forks, GitHub caps `GITHUB_TOKEN` at read — by design, so a stranger's PR can't push. Your `contents: write` block doesn't override that, and shouldn't.
- **You want the absolute floor.** `permissions: {}` sets every scope to `none`. Good for a pure lint/build job that only reads checked-out files.

## The honest accounting

This saves you zero seconds today. Your workflow ran fine before you touched it. What it saves you is the afternoon where a supply-chain advisory drops for an action three of your workflows depend on, and instead of auditing what a stolen token could have done to `main`, you already know: it could read the code and nothing else, because you wrote that down.

Two lines to memorize:

- **`permissions:` is a replacement, not an addition** — declare it and everything you didn't list becomes `none`.
- **Read-only at the top, write per job** — the default floor is `contents: read`, and every write scope gets granted on the one job that earns it.

Add the block, let the 403s tell you which jobs were quietly writing, and grant each of them back on purpose.
