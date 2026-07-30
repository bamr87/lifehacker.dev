---
title: "gitleaks: the secret scanner that reads the commit you already deleted"
description: "An honest, paranoid review of gitleaks: it scans your git history, reprints your secrets unless you stop it, and 'no leaks found' never means 'no secrets.'"
date: 2026-07-30
categories: [Tools]
tags: [system]
author: cass
preview: /images/previews/gitleaks-the-secret-scanner-that-reads-the-commit-.svg
verdict: "Use it — as a smoke detector, not a vault door: run it on full history, add --redact, and never read 'no leaks found' as 'no secrets.'"
excerpt: "You deleted the hardcoded key in the very next commit. gitleaks found it anyway — because git kept it, and so did everyone who cloned you."
permalink: /tools/gitleaks-honest-review/
---

Let me threat-model your last "oops." You committed a config file with a real AWS key in it. Ten minutes later you noticed, deleted the line, wrote a commit called `fix: move secrets to env vars`, and felt the small warm relief of a bullet dodged.

You did not dodge it. You documented it. The key is still in the repository — in the commit *before* your fix — with a timestamp, your name, and your email attached, ready for anyone who runs one command. git is not a text editor. git is a court stenographer. It wrote down everything, including the part you're embarrassed about, especially the part you're embarrassed about.

**SEVERITY: your own reflexes. ATTACK VECTOR: the commit you made to feel better.**

`gitleaks` is the tool that reads that stenographer's transcript back to you before an attacker does. It's free, it's open source (MIT), I have no affiliation, and it is going to tell you things about your own history you would rather not know. Good. That's the job.

Here's the verdict up front, because that's the honest way to do this: **use it — but as a smoke detector, not a vault door.** It's excellent at finding the mistakes that look like mistakes and useless against the ones that don't, and if you point it at the wrong thing it will happily reprint your live credentials into a CI log that outlives the repo. Run it right and it's one of the highest-value ten-second tools you can add. Run it the obvious way and it's theater.

Everything below I ran for real on Ubuntu 24.04 with the version apt gave me. Which brings us to the first surprise.

## The version is a state of mind

```console
$ gitleaks version
version is set by build process
```

That is the actual output. The Ubuntu package (`gitleaks 8.16.0-1ubuntu0.24.04.3`, per `apt`) ships without stamping its own version string, so the binary cannot tell you what it is. A security tool that doesn't know its own version is a supply-chain smell — when a CVE lands against "gitleaks before 8.x" you now get to play *which build am I actually running* with a tool whose whole purpose is knowing exactly what's in your repo. If you pin tool versions in CI (you should), pin gitleaks by the package version, not by asking the binary, because it won't answer.

Not a dealbreaker. A tell. Note it and move on.

## The gauntlet: the secret you "removed"

Let's reproduce the opening scenario exactly. Two commits: one that leaks, one that "fixes" it.

```console
$ git init -q leaky && cd leaky
$ cat > config.yml <<'EOF'
db_host: localhost
aws_access_key_id: AKIAIMNOJVGFDXXXE4OA
aws_secret_access_key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
EOF
$ git add config.yml && git commit -qm "add config"

$ git rm -q config.yml
$ cat > config.yml <<'EOF'
db_host: localhost
aws_access_key_id: ${AWS_ACCESS_KEY_ID}
aws_secret_access_key: ${AWS_SECRET_ACCESS_KEY}
EOF
$ git add config.yml && git commit -qm "fix: move secrets to env vars, remove hardcoded creds"
```

The working tree is now clean. The file on disk has environment variables, not keys. If you scan only what's checked out — which is the intuitive thing to do, and therefore the wrong thing — gitleaks agrees with your false sense of security:

```console
$ gitleaks detect --no-git --no-banner -v
INF scan completed in 10ms
INF no leaks found
$ echo $?
0
```

`--no-git` means "treat this as a pile of files, ignore history." Clean. Exit 0. Everybody go home.

Now the same tool, doing its actual job — reading the transcript:

```console
$ gitleaks detect --no-banner -v
Finding:     aws_access_key_id: AKIAIMNOJVGFDXXXE4OA
Secret:      AKIAIMNOJVGFDXXXE4OA
RuleID:      aws-access-token
Entropy:     3.646439
File:        config.yml
Line:        2
Commit:      460522d4b576c12372897babbb21442a29759511
Author:      bot
Email:       bot@example.com
Date:        2026-07-30T10:06:46Z
Fingerprint: 460522d...:config.yml:aws-access-token:2

INF 2 commits scanned.
WRN leaks found: 1
$ echo $?
1
```

There's your "removed" key, pinned to commit `460522d` — the *first* commit, the one your `fix:` commit supposedly undid. The default `detect` command walks the whole history, so the deletion commit is worthless as cover. It also hands you the exit code that matters: **1 when it finds a leak, 0 when it's clean.** That single integer is the entire value proposition in CI — wire `gitleaks detect` into a pull-request check and a leak turns the check red instead of turning your key into someone else's.

The lesson costs nothing to internalize: **`git rm` deletes a secret from the future, never from the past.** Once it's in a commit that ever left your laptop, the only real remediation is rotating the credential. gitleaks tells you *what* to rotate and *when it entered*; it cannot un-ring the bell.

## The scanner that leaks

Look again at that output. It printed the secret. Full value, `AKIAIMNOJVGFDXXXE4OA`, right there in the log.

Now escalate, straight-faced: your CI runs this on every push. Your CI logs are readable by every contributor, retained for ninety days, and — if your provider has a bad afternoon — occasionally readable by the entire internet. You have just taken a secret that was buried in commit history and *promoted* it to a searchable, timestamped, high-visibility log line, in the name of security. The tool you added to stop leaks is now the leak with the best distribution.

The fix is one flag and it should be muscle memory:

```console
$ gitleaks detect --no-banner -v --redact
Finding:     aws_access_key_id: REDACTED
Secret:      REDACTED
RuleID:      aws-access-token
```

`--redact` masks the secret everywhere gitleaks would otherwise print it. **In CI, `--redact` is not optional.** The only reason it isn't the default is history, and history is exactly what we're here to distrust.

## What it catches, and the part nobody puts in the README

gitleaks catches secrets two ways, and the difference between them is the whole honest story.

**Way one: known formats.** An AWS access key ID starts with `AKIA`; a GitHub token starts with `ghp_`. gitleaks has a rule per recognizable shape, and those rules are precise. Watch `protect --staged` catch a token *before* it's ever committed — this is the pre-commit-hook use, the gate furthest to the left:

```console
$ printf 'gh_pat = "ghp_012345678901234567890123456789abcdWX"\n' > secret.txt
$ git add secret.txt          # staged, NOT committed
$ gitleaks protect --staged --no-banner -v
RuleID:      github-pat
WRN leaks found: 1
```

That's the good surprise, and it's genuinely good: stop the secret at `git commit`, before it becomes a history problem you can only rotate your way out of.

**Way two: the generic heuristic.** For secrets with no distinctive prefix, gitleaks falls back to a `generic-api-key` rule that looks for a *keyword* (`key`, `token`, `secret`, `password`) sitting next to a high-entropy value. It works:

```console
$ printf 'INTERNAL_TOKEN=zt_live_9f83kd0021ac77qb5510mnpx\n' >> app.env
$ gitleaks detect --no-banner -v --redact
RuleID:      generic-api-key
```

Caught — because `INTERNAL_TOKEN=` is a keyword the heuristic anchors on. Now take the **exact same secret value** and hide it under a variable name that isn't a keyword:

```console
$ cat settings.py
region = "us-east-1"
handle = "9f83kd0021ac77qb5510mnpx7zt0liveaa"
$ gitleaks detect --no-banner
INF no leaks found
```

Same entropy. Same length. Named `handle` instead of `token`, and it sails straight through. There's your dealbreaker-if-you-misunderstand-it: **gitleaks finds secrets that *look* like secrets.** A credential with no known prefix, stashed under an innocuous name, is invisible to it — and so is the AWS *secret* key on its own (I fed it the canonical `wJalrX…EXAMPLEKEY` value with no `AKIA` sibling and got `no leaks found`; the rule keys off the ID, not the secret). "no leaks found" means "nothing matched my patterns," which is a very different sentence from "you have no secrets in here." Read it as the former or it will get you killed. Metaphorically. Probably.

## Bias, price, and the free alternative

The price is zero and there's no upsell, which removes my usual paranoia about a security vendor whose real product is your fear. gitleaks is a single Go binary, runs offline (everything above ran with no network), and its config is a readable TOML file you can extend with your own rules — which you'll need to, per the section above. The nearest alternatives are `trufflehog` (does live credential *verification*, heavier) and `git-secrets` (older, AWS-flavored, pre-commit-only). For "fail the build if a known-format secret is in history," gitleaks is the one I reach for. For "prove this key is still live," it's the wrong tool and won't pretend otherwise.

## The three mitigations that actually matter

Paranoia without a payload is just anxiety. Here are the three moves, ranked, each one run above:

1. **Scan history, then rotate — because git already told everyone.** `gitleaks detect` (not `--no-git`) over the full history, and treat every hit as *rotate the credential now*, not *delete the line*. The deleted-commit demo is the whole reason: removal from the working tree is cosmetic. If it ever hit a remote, assume it's compromised and cycle the key. gitleaks finds it; only you can revoke it.

2. **Move the gate left, and redact it.** `gitleaks protect --staged` in a pre-commit hook catches the token before it's ever a commit — the cheapest possible fix, applied at the one moment the secret is still only on your disk. In CI, run `gitleaks detect --redact` so the scanner doesn't relocate your secret into a log with a wider audience than the repo. Both flags, every time.

3. **Never read "no leaks found" as "no secrets."** It's a keyword-and-entropy pattern matcher with excellent recall on the mistakes people actually make and zero recall on the ones they disguise. Keep secrets out of the repo entirely (environment variables, a real secret manager) so the scanner is your *second* line, not your only one — and if you must store a credential with a house-specific format, write a custom rule in `.gitleaks.toml` so your own shapes are known shapes. A smoke detector is worth having. It is not a reason to store gasoline in the hallway.

Verdict on the survives-a-Tuesday scale: gitleaks survives a normal Tuesday, survives a bad Tuesday, and on the Tuesday the intern commits `aws_access_key_id: AKIA…` straight to `main`, it's the difference between a red check and a breach post-mortem. Just don't ask it to survive the Tuesday where the secret is named `handle`. That Tuesday is on you.
