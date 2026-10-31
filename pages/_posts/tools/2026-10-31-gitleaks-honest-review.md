---
title: "gitleaks: the secret scanner that takes orders from the repo it's scanning"
description: "gitleaks catches real tokens, even deleted or base64'd. It also obeys the scanned repo's own ignore files. Threat-modeled and tested on 8.30.1."
date: 2026-10-31
preview: /images/previews/gitleaks-the-secret-scanner-that-takes-orders-from.svg
categories: [Tools]
tags: [files, system]
author: cass
verdict: "Use it, as a pre-commit hook and in CI. Detection is good and it reads history. But in CI, pin the config outside the repo, turn off the inline escape hatch, and always pass --redact."
excerpt: "A guard dog that sniffs every commit for API keys. It has a good nose. It also accepts a note from the burglar saying 'this room is fine', and in CI that note can arrive in the same pull request."
permalink: /tools/gitleaks-honest-review/
---
**Verdict: use it. `gitleaks` scans files and git history for API keys, tokens and passwords. It caught every real-format token I planted, including one I deleted in a later commit and one I base64-encoded to be clever. The catch is about trust, not detection. The repository being scanned can ship its own `.gitleaks.toml`, its own `.gitleaksignore`, and inline `gitleaks:allow` comments, and gitleaks obeys all three. Below is what it catches, what got past it, and the three settings that keep the scanned code from writing its own pass.** I have no relationship with gitleaks or its maintainers. It's MIT-licensed, nobody paid me, and I checked the license against GitHub's API instead of the README, because I don't trust anything that reads secrets for a living.

Every developer has the same nightmare and nobody threat-models it: you paste a token into a config file "for one second," commit on autopilot, push, and somewhere a bot that scrapes public commits files it under *Free Cloud Credits* before your coffee cools. Scale that up and the bot works for a three-letter agency, your token opens the production database, and the whole incident gets turned into a slide at a conference you'll never be invited to. Back to reality: the bots that scrape public commits for keys are real and fast, the agency is optional, and the fix is a scanner that runs before the push. gitleaks is that scanner, so I tested the scanner.

Everything below ran for real on Ubuntu 24.04 with `gitleaks 8.30.1` (the `linux_x64` release binary from GitHub) and git 2.56.0. Each test used a throwaway repo or directory under `/tmp/gl`. The "secret" is a fake GitHub personal access token: `ghp_` plus 36 random characters from `/dev/urandom`, which is the format gitleaks' `github-pat` rule looks for. In the output below I've cut it to `ghp_csYV…`, and its base64 form to `Z2hwX2NzWVZ…`. The scanner saw all 40 characters. Publishing them would set off every secret scanner that reads this page, and that would be embarrassing.

## What earns the install

Commit the token and scan the history:

```console
$ cat deploy.py
import requests
TOKEN = "ghp_csYV…"
$ git add . && git commit -qm "add deploy"

$ gitleaks git . -v --no-banner --no-color
Finding:     ghp_csYV…
Secret:      ghp_csYV…
RuleID:      github-pat
Entropy:     4.921928
File:        deploy.py
Line:        2
Commit:      eea7292881635f4dc352e155b12f0133cfdd6b83
Author:      t
Email:       t@t
Date:        2026-10-31T23:02:59Z
Fingerprint: eea7292881635f4dc352e155b12f0133cfdd6b83:deploy.py:github-pat:2

11:03PM WRN leaks found: 1
$ echo $?
1
```

It found the token, named the rule, the commit and the line, and exited 1 so CI goes red. Now for the classic move: delete the file and commit the deletion, which is what everyone does in the first four minutes of a leak.

```console
$ git rm -q deploy.py && git commit -qm "oops remove"

$ gitleaks dir . --no-banner --no-color
11:03PM INF no leaks found
$ gitleaks git . --no-banner --no-color
11:03PM WRN leaks found: 1
```

There are two modes, and they answer different questions. `gitleaks dir` scans the files on disk, which are clean now. `gitleaks git` scans every commit, and the token is still in commit `eea7292`, so it's still public to anyone who clones. Deleting the file fixed nothing except how you felt about it. `SEVERITY: your git log. ATTACK VECTOR: git log -p.`

Encoding doesn't hide it either. gitleaks decodes recursively (the default `--max-decode-depth` is 5):

```console
$ cat conf.txt
TOKEN=Z2hwX2NzWVZ…
$ gitleaks dir . -v --no-banner --no-color | grep -E 'RuleID|Tags'
RuleID:      generic-api-key
RuleID:      github-pat
Tags:        [decoded:base64 decode-depth:1]
```

It flagged the base64 blob as a generic key, then decoded it and found the GitHub token inside. Hex-encoding got the same result (`decoded:hex`). A `.env` line, a JSON value, and `api_key =`, `secret =`, `db_password =` or `PASSWORD=` followed by 32 random characters were all caught, the last four by the `generic-api-key` rule.

## What got past it

Credit given. Now the misses, in order of how surprised I was.

**A split string.** `TOKEN = "ghp_" + "csYV…"` returned `no leaks found`. gitleaks matches patterns in text. It doesn't run your code, so it can't see what the string becomes once Python joins the two halves. That's expected for a regex scanner, but worth knowing about the one coworker who does this "for readability."

**A password with punctuation in it.** These are three runs on a one-line file, `db_password = "<value>"`:

| value | result |
| --- | --- |
| `Tr0ub4dor3-horse-Battery-staple-9xQ` | leaks found: 1 |
| `Tr0ub4dor&3-horse-Battery-staple-9xQ` | no leaks found |
| `Tr0ub4dor!3-horse-Battery-staple-9xQ` | no leaks found |

One `&` or `!` in an otherwise identical password and the generic rule let it go. So the strong human-made password your password policy demands, the one with a symbol in it, is the kind the generic rule missed in my runs. A low-entropy `password = "hunter2"` and an all-lowercase `correcthorsebatterystaple` weren't flagged either. The generic rule is tuned for machine-made keys. `RATING: CVE-YOUR-OWN-COMPLEXITY-REQUIREMENTS.`

**The scanned repo telling the scanner what to ignore.** This is the one that matters. `gitleaks dir --help` lists where the config comes from, in order:

```console
$ gitleaks dir --help | sed -n '/config file path/,/default config/p'
  -c, --config string                 config file path
                                      order of precedence:
                                      1. --config/-c
                                      2. env var GITLEAKS_CONFIG
                                      3. env var GITLEAKS_CONFIG_TOML with the file content
                                      4. (target path)/.gitleaks.toml
                                      If none of the four options are used, then gitleaks will use the default config
```

Number 4. If you don't pin a config, gitleaks uses the one inside the code it's scanning. So I played the attacker, or the tired developer who wants the build green by Friday. I put `deploy.py` back in a third commit, so the token now sits in two commits, and added four lines to the repo:

```console
$ gitleaks dir . --no-banner --no-color
11:03PM WRN leaks found: 1

$ printf '[extend]\nuseDefault = true\n[allowlist]\npaths = [".*"]\n' > .gitleaks.toml
$ gitleaks dir . --no-banner --no-color
11:03PM INF no leaks found
$ gitleaks git . --no-banner --no-color
11:03PM INF no leaks found
```

All the default rules are still loaded, then an allowlist covering every path switches them off. The history scan went quiet too: the working-tree config applies to every commit, so one file hides every secret ever committed. In CI, the pull request that adds the secret can add this file in the same push. That isn't a bug in gitleaks. Project-level config is a feature, and it's documented right there in `--help`. Every convenience is an attack surface with better marketing, and this one comes with a TOML schema.

`.gitleaksignore` does the same thing for single findings. You paste in a finding's fingerprint and it's suppressed. I expected `-i` (the "path to .gitleaksignore" flag) to control which ignore file is used. It doesn't replace the one in the target:

```console
$ echo "deploy.py:github-pat:2" > .gitleaksignore
$ gitleaks dir . -i /tmp/gl/nowhere --no-banner --no-color
11:03PM INF no leaks found
```

The flag points at an empty directory, and the repo's own ignore file still won. (Scanning from outside the repo with an absolute path changes the fingerprint to `/tmp/gl/repo/deploy.py:github-pat:2`. Put that in the file and it's suppressed too.) And the smallest hole of all is an inline comment:

```console
$ cat a.py
TOKEN = "ghp_csYV…"  # gitleaks:allow
$ gitleaks dir . --no-banner --no-color
11:03PM INF no leaks found
$ gitleaks dir . --ignore-gitleaks-allow --no-banner --no-color
11:03PM WRN leaks found: 1
```

The nation-state version: an operative spends a year in your open-source project to earn commit rights, then lands a pull request with a token and a friendly `# gitleaks:allow`. The realistic version needs no operative. The comment is in the docs, it's the fastest way to make a red check go green, and someone will paste it in before lunch.

**And the report keeps the secret.** `-r report.json` writes findings to a file, which CI then uploads as an artifact:

```console
$ gitleaks dir /tmp/gl/env -r /tmp/gl/r.json --no-banner; grep -o '"Secret": "[^"]*"' /tmp/gl/r.json
"Secret": "ghp_csYV…"
$ gitleaks dir /tmp/gl/env --redact -r /tmp/gl/r2.json --no-banner; grep -o '"Secret": "[^"]*"' /tmp/gl/r2.json
"Secret": "REDACTED"
```

Without `--redact`, the scanner's report is a neatly labeled list of every secret it found, saved to a file you then upload. The same goes for `-v` in a public CI log.

## The three mitigations, ranked

I ran each of these in the sandbox above.

**1. Run it before the commit exists: a pre-commit hook.** A leak caught before the commit means nothing to rotate. The hook is two lines:

```console
$ cat .git/hooks/pre-commit
#!/bin/sh
exec gitleaks git --pre-commit --staged --redact --no-banner -v

$ git add settings.env && git commit -m "add settings"
Finding:     GITHUB_TOKEN=REDACTED
Secret:      REDACTED
RuleID:      github-pat
Entropy:     4.921928
File:        settings.env
Line:        1
Fingerprint: settings.env:github-pat:1
11:04PM INF 0 commits scanned.
11:04PM INF scanned ~54 bytes (54 bytes) in 161ms
11:04PM WRN leaks found: 1
$ git log --oneline
fatal: your current branch 'main' does not have any commits yet
```

The commit was refused, and a clean file committed straight after went through. Be honest about what a hook is, though: it runs on your machine, so it's a seatbelt, not a lock. `git commit --no-verify` skipped it and the token went in (I checked, and the CI-side `gitleaks git .` caught it right after: `leaks found: 1`). That's why there's a #2.

**2. In CI, pin the config outside the repo and turn off the inline escape hatches.** The check that guards the pull request must not take its config from the pull request. Pass it through the environment (or `-c` with a path outside the checkout), and add `--ignore-gitleaks-allow` and `--redact`. With the hostile `.gitleaks.toml` still in place:

```console
$ gitleaks git . --no-banner --no-color
11:03PM INF no leaks found
$ GITLEAKS_CONFIG_TOML=$'[extend]\nuseDefault = true' gitleaks git . --no-banner --no-color
11:03PM WRN leaks found: 2
$ gitleaks git . -c /tmp/gl/pinned.toml --no-banner --no-color
11:03PM WRN leaks found: 2
```

The pinned default config ignores the repo's allowlist and finds the token in both commits that contain it. `.gitleaksignore` is harder, because `-i` didn't override the target's copy in my tests. If your project needs one for real false positives, list it, along with `.gitleaks.toml`, in `CODEOWNERS` so a change to it needs a named human's review. That last step is GitHub configuration I didn't test here, so treat it as advice, not a receipt.

**3. Scan history, and when it finds something, rotate. Don't delete.** Run `gitleaks git`, not just `gitleaks dir`, at least once over the whole repo and on every pull request. The deletion test above is the whole argument: `dir` said clean, `git` said `leaks found: 1`, and anyone with a clone has that commit. Revoke the token where it was issued first, then clean up the history if you want to. Rewriting history without revoking is a cover-up. Revoking without rewriting is just untidy.

## Bottom line

gitleaks has a good nose. It found real-format tokens in plain text, base64, hex, `.env`, JSON and deleted history, and it exits 1 so it can fail a build. It missed a split string and two passwords with symbols in them, which is the normal limit of pattern-matching, not a scandal. The real risk is who it takes orders from. Out of the box it reads its config, its ignore list and its exceptions from the repo it's guarding, so a pull request can change its own security check. Run it as a hook, run it in CI with a config the repo can't edit and `--redact` on, scan history, and rotate anything it finds. Source and docs: [github.com/gitleaks/gitleaks](https://github.com/gitleaks/gitleaks).
