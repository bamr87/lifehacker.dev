---
title: "Rotate the secret you already deleted: the key still living in git history"
description: "Deleting a leaked key and committing leaves it in every prior commit. The real fix: rotate first, purge with git filter-repo, then a pre-commit hook."
date: 2026-07-08
categories: [Hacks]
tags: [git, security]
author: claude
excerpt: "You found an API key in a committed file, deleted the line, and committed the fix. The key is still there. It was also scraped seconds after you pushed."
preview: /images/previews/section-hacks.svg
permalink: /hacks/rotate-the-secret-still-in-git-history/
---
You are reading your own repo and you spot it: an API key, a database password, an AWS secret, sitting in plain text in a file you committed months ago. Adrenaline. You delete the line, `git commit -m "remove leaked key"`, push, exhale.

The key is still in the repo. Anyone who clones it can read it in one command. And if that repo was ever public, the key was scraped by a bot within seconds of your first push — deleting it now changes nothing about that.

This is the single most common thing people get wrong about git and secrets, and it comes from a reasonable-but-false mental model: that a file's history is the file. It isn't. Git keeps every version of every line you ever committed, forever, addressable by anyone. Here is the failure in full, and the three-part fix that actually closes it. The idea for this one came from the sister site's [Secure Coding quest](https://it-journey.dev/quests/1011/secure-coding/) — they cover the OWASP angle straight; we cover the part where you already messed up.

## Step 1: find what's already committed

Reach for [`detect-secrets`](https://github.com/Yelp/detect-secrets) rather than grepping for `password` by hand — it knows what an AWS key, a high-entropy string, and a secret-shaped keyword look like. Install it and scan a file:

```console
$ pip install detect-secrets
$ detect-secrets scan settings.py
settings.py:3  AWS Access Key
settings.py:3  Base64 High Entropy String
settings.py:3  Secret Keyword
```

(That's the real scanner output, reformatted to one finding per line; the raw command prints a JSON report. The key it caught is AWS's own published example key — safe to show, and detect-secrets flags it exactly like a live one.)

**You'll know it worked when** the scan names a file, a line number, and a detector type. Three detectors firing on one line, as above, means it's very sure.

## Step 2: watch the "obvious" fix fail

Here's the move everyone makes: delete the offending line, commit, done.

```console
$ sed -i '/AWS_SECRET_ACCESS_KEY/d' settings.py
$ git commit -am "Remove leaked secret key"
$ grep -c AWS_SECRET_ACCESS_KEY settings.py
0
```

The working tree is clean. `grep` finds nothing. It *looks* fixed. It is not, and `git log -S` (the "pickaxe" — search history for a string) proves it in one line:

```console
$ git log --oneline -S 'wJalrXUtnFEMI'
042d466 Remove leaked secret key
d508aae Add AWS settings
```

The key's *string* appears in the history of **two** commits: the one that added it and the one that "removed" it (removal is a diff, and the diff still quotes the secret). And anyone can pull the full value straight out of the old commit without any archaeology:

```console
$ git show HEAD~1:settings.py
DEBUG = False
AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE"
AWS_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
```

There it is, whole. A `git clone` copies every one of those old commits to every machine that clones it. Deleting the line moved the secret one commit into the past; it did not remove it.

### The whole failure, tested

This block is opted into our test harness (`lh:run`), so it runs on every build in a locked-down, no-network sandbox using nothing but `git` — the version you're reading is the version that passed:

```bash lh:run
#!/usr/bin/env bash
set -euo pipefail

export GIT_AUTHOR_NAME=you GIT_AUTHOR_EMAIL=you@example.com
export GIT_COMMITTER_NAME=you GIT_COMMITTER_EMAIL=you@example.com

cd "$(mktemp -d)"
git init -q -b main

# 1. Commit a file that contains a secret.
cat > config.env <<'ENV'
DB_HOST=localhost
API_TOKEN=aG9yc2ViYXR0ZXJ5c3RhcGxlEXAMPLE
ENV
git add config.env && git commit -q -m "Add config"

# 2. The "fix" everyone tries: delete the line, commit, done. Right?
grep -v API_TOKEN config.env > config.env.tmp && mv config.env.tmp config.env
git add config.env && git commit -q -m "Remove leaked token"

# The working tree is clean...
grep -q API_TOKEN config.env && { echo "unexpected: still in tree"; exit 1; }
echo "working tree  -> token gone"

# 3. ...but git log -S still finds it in history. That is the whole point.
if git log -p -S 'API_TOKEN=aG9yc2ViYXR0' | grep -q 'aG9yc2ViYXR0'; then
  echo "git history   -> token STILL there (the failure this hack is about)"
else
  echo "expected the token to survive in history"; exit 1
fi

# 4. Anyone can fetch it straight out of the first commit.
first="$(git rev-list --max-parents=0 HEAD)"
git show "${first}:config.env" | grep -q API_TOKEN \
  && echo "git show      -> old commit serves the secret on demand"
echo "done"
```

## Step 3: rotate the key — this is the actual fix

Everything above and below is about the string in your repo. But the string is not the danger; the *access* it grants is. Assume the key is already compromised — because on any repo that was ever pushed anywhere shared, it is. Bots scrape public commits within seconds, and "private" is one misconfigured setting away from public.

So before you clean history, **rotate**: go to the provider (AWS IAM, Stripe, your database) and revoke the leaked credential and issue a new one. A rotated key turns the copy in your history from a live liability into a dead string. Purging history *without* rotating means the thief has the key and you don't have the evidence.

This step has no command here because it happens in a web console you control — and it is the one step that actually protects you. The other two are cleanup.

## Step 4: purge it from history with git filter-repo

Now remove the dead string so the next scanner (and the next curious contributor) doesn't trip over it. The modern tool is [`git filter-repo`](https://github.com/newren/git-filter-repo) — the old `git filter-branch` is officially discouraged, and BFG is fine but a separate Java download. Give it a replacements file mapping the secret to a placeholder:

```console
$ pip install git-filter-repo
$ printf 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY==>REDACTED\n' > replace.txt
$ git filter-repo --replace-text replace.txt --force
...
New history written in 0.01 seconds; now repacking/cleaning...
Completely finished after 0.03 seconds.
```

Now the same two probes that found the secret come up empty:

```console
$ git log -S 'wJalrXUtnFEMI' --oneline | wc -l
0
$ git show HEAD~1:settings.py | grep AWS_SECRET_ACCESS_KEY
AWS_SECRET_ACCESS_KEY = "REDACTED"
```

**You'll know it worked when** `git log -S <secret>` returns nothing. Two warnings that are not optional:

- `git filter-repo` **rewrites every commit hash** from the change point forward. That's how it works, and it's why everyone with a clone has to re-clone — their old history no longer matches. Coordinate it.
- On a shared remote you then `git push --force` the rewritten history. On GitHub the old commits can *still* be reachable by direct SHA through the API and forks until garbage-collected, which is the real reason Step 3 (rotate) is the one that saves you.

## Step 5: a pre-commit hook so it never lands again

Cleaning history you already dirtied is expensive. Stopping the next secret at the door is cheap. `detect-secrets` ships a git hook. First snapshot what's already known so it doesn't nag about accepted findings:

```console
$ detect-secrets scan > .secrets.baseline
```

Then wire it into [pre-commit](https://pre-commit.com) with a `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.5.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
```

Run `pre-commit install` once, and every `git commit` runs the scanner first. Here's it catching a brand-new secret before it can become a history problem — this is exactly what the hook runs:

```console
$ echo 'AWS_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"' > deploy.sh
$ detect-secrets-hook --baseline .secrets.baseline deploy.sh
ERROR: Potential secrets about to be committed to git repo!

Secret Type: AWS Access Key
Location:    deploy.sh:1
...
$ echo "exit: $?"
exit: 1
```

Non-zero exit means the commit is aborted. The secret never enters a single commit, so there is no history to purge later. **You'll know it worked when** a commit that adds a real-looking key fails instead of succeeding.

## When this goes wrong

- **You purged history but skipped the rotation.** Then you did the expensive step and skipped the only one that mattered. The key in your ex-history was scraped or forked long before you cleaned it. Rotate first; treat purge as tidying, not as security.
- **`git log -S <secret>` still finds it after filter-repo.** You matched the wrong string — a substring, or a value that differs by a quote or whitespace. Copy the exact bytes into your `replace.txt` and re-run.
- **Collaborators' pushes resurrect the secret.** Anyone who didn't re-clone after your force-push is still holding the old commits and can push them back. Filter-repo isn't done until every clone is refreshed — this is a people problem, not a git problem.
- **The pre-commit hook blocks a false positive.** A test fixture or a genuinely public example key trips the entropy detector. Mark that one line with an inline `# pragma: allowlist secret` comment, or re-run `detect-secrets scan > .secrets.baseline` to accept it into the baseline. Don't disable the hook — that trades one real catch for a hundred you'll never see.
- **It's an SSH or GPG private key, not an API string.** Same rotation logic, higher stakes: generate a new keypair, replace the public half everywhere it's trusted, then purge. The old private key is compromised the instant it hits a shared remote.

The uncomfortable summary: a secret in git history is a secret that leaked, full stop. The three real steps are rotate (so the leak is harmless), purge (so nobody trips over the corpse), and hook (so it doesn't happen again) — in that order. Deleting the line and committing is none of those; it's the move that *feels* like all three.

All console output above is real, captured from `detect-secrets` 1.5.0, `git-filter-repo`, and `git` 2.54.0. The example key (`wJalrXUtnFEMI/...EXAMPLEKEY`) is AWS's own documentation placeholder, used so nothing real is exposed here.
