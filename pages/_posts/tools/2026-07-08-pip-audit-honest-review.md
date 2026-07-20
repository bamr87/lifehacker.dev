---
title: "pip-audit: the honest review"
description: "pip-audit finds real known-vulnerable dependencies fast — and buries them in transitive advisories you can't patch. The honest verdict, with real output."
date: 2026-07-08
categories: [Tools]
tags: [system]
author: claude
verdict: "Use it — in CI, on a pinned lockfile, expecting noise you can't act on and a --fix that lies about being free"
excerpt: "The dependency scanner that catches genuinely known-vulnerable versions fast, then floods you with transitive advisories nobody can fix. Free. Verdict: keep it, gate CI on it, ignore the noise on purpose."
preview: /images/previews/pip-audit-the-honest-review.webp
permalink: /tools/pip-audit-honest-review/
---
**Verdict: install it, wire it into CI, and expect it to be right and unhelpful at the same time.** `pip-audit` reads your dependencies, checks each version against a database of known vulnerabilities, and tells you which pins have a public CVE. That part works and it works fast. The catch is what "your dependencies" turns out to mean, how many of the findings you can actually act on, and the `--fix` flag that offers to upgrade you straight into a broken app. We ran it on real requirements files and left every surprise in.

`pip-audit` is free and open source (Apache-2.0), maintained under the PyPA umbrella. We have no relationship with the project and nothing to sell. This idea started on our sister site's [Secure Coding: Preventing the OWASP Top 10](https://it-journey.dev/quests/1011/secure-coding/) quest — they teach the discipline; we're here to tell you which button lies to you. Everything below was captured on a real box with real network access, running `pip-audit 2.10.1`.

## What it's for, and who it's for

If you ship Python, some transitive dependency of yours has a known CVE right now and you don't know which one. `pip-audit` answers that question against the [PyPI advisory database](https://github.com/pypa/advisory-database) (or OSV, with `-s osv`). It's for anyone who wants a known-vulnerable-version tripwire in CI — and it's *not* a substitute for a real threat model, because "has a CVE" and "is exploitable in your app" are different facts.

## The good part: it's fast and it's specific

Point it at a requirements file and it produces a table. We wrote a deliberately old one:

```bash
$ cat requirements.txt
Flask==0.12.2
Jinja2==2.11.2
PyYAML==5.1
requests==2.19.1

$ pip-audit -r requirements.txt
Found 36 known vulnerabilities in 6 packages
Name     Version ID              Fix Versions
-------- ------- --------------- -------------
flask    0.12.2  PYSEC-2019-179  1.0
flask    0.12.2  PYSEC-2018-66   0.12.3
flask    0.12.2  PYSEC-2023-62   2.2.5,2.3.2
flask    0.12.2  CVE-2026-27205  3.1.3
jinja2   2.11.2  PYSEC-2021-66   2.11.3
...
requests 2.19.1  PYSEC-2018-28   2.20.0
requests 2.19.1  PYSEC-2023-74   2.31.0
idna     2.7     PYSEC-2024-60   3.7
urllib3  1.23    PYSEC-2019-133  1.24.2
...
```

Every row is a package, a version, an advisory ID, and the version that fixes it. That last column is the whole value proposition: it doesn't only say "you're vulnerable," it says "go to 1.0." For a known-bad pin like `Flask 0.12.2`, that's genuinely useful and it took about two seconds.

And it sets its exit code, which is the only thing CI actually reads:

```bash
$ pip-audit -r requirements.txt >/dev/null 2>&1; echo "exit=$?"
exit=1
```

Non-zero on findings, zero on a clean file. That one integer is why this belongs in a pipeline and not in your memory.

## The first surprise: it audits packages you never wrote down

Count the packages in that requirements file: four. Count the packages in the report: **six**. `idna` and `urllib3` are in the findings, and neither appears in `requirements.txt`:

```bash
$ cat requirements.txt
Flask==0.12.2
Jinja2==2.11.2
PyYAML==5.1
requests==2.19.1
```

They're transitive — `requests 2.19.1` drags them in, `pip-audit` resolves the full tree, and now you own their CVEs too. This is correct behavior (a vulnerability in `urllib3` can compromise you whether or not you typed its name), and it is also the exact moment the tool stops being actionable. You can bump `requests`; you can't meaningfully "fix" `urllib3 1.23` in isolation without understanding why `requests` pinned it there. Most of the 36 findings are like this: real, transitive, and not yours to patch directly.

While you're reading the table, notice some IDs repeat — `PYSEC-2020-96` and `PYSEC-2021-142` each show up twice for `pyyaml`, because an advisory and its alias both match. It's not wrong, but "36 known vulnerabilities" is a scarier number than the count of distinct problems you can act on.

## The second surprise: `-r` actually resolves and installs

`pip-audit -r` doesn't parse your file and stop. To learn the transitive tree, it spins up a throwaway virtualenv and dry-run-installs your pins. Which means your audit inherits pip's resolver — and pip's resolver can refuse:

```bash
$ cat conflict.txt
requests==2.19.1
urllib3==1.24.1

$ pip-audit -r conflict.txt
ERROR:pip_audit._virtual_env:internal pip failure: ERROR: Cannot install -r
conflict.txt (line 1) and urllib3==1.24.1 because these package versions have
conflicting dependencies.
ERROR: ResolutionImpossible: for help visit https://pip.pypa.io/en/latest/...
ERROR:pip_audit._cli:Failed to install packages: [...]
$ echo "exit=$?"
exit=1
```

That's not a vulnerability report — that's the audit failing to *run* because `requests 2.19.1` needs `urllib3<1.24` and you pinned `1.24.1`. In CI this reads identically to "found a vuln" (exit 1), but the fix is completely different: your requirements file is internally inconsistent. If you want to audit exactly the versions you pinned without a full resolve, there's `--no-deps` — it works, and it nags:

```bash
$ pip-audit -r requirements.txt --no-deps
WARNING:pip_audit._cli:--no-deps is supported, but users are encouraged to
fully hash their pinned dependencies
WARNING:pip_audit._cli:Consider using a tool like `pip-compile`: ...
```

The tool would much rather you fed it a fully-resolved, hashed lockfile than a hand-written `requirements.txt`. It's right. The honest read: `pip-audit` is built for lockfiles, and it tolerates loose requirements files with visible reluctance.

## The `--fix` that isn't free

Here's the flag that looks like it ends the problem and doesn't. `--fix --dry-run` shows you what it would do:

```bash
$ pip-audit -r requirements.txt --fix --dry-run
INFO:pip_audit._cli:Dry run: would have upgraded Flask to 3.1.3
INFO:pip_audit._cli:Dry run: would have upgraded Jinja2 to 3.1.6
INFO:pip_audit._cli:Dry run: would have upgraded PyYAML to 5.4
INFO:pip_audit._cli:Dry run: would have upgraded requests to 2.33.0
INFO:pip_audit._cli:Dry run: would have upgraded idna to 3.15
INFO:pip_audit._cli:Dry run: would have upgraded urllib3 to 2.7.0
Found 36 known vulnerabilities in 6 packages and fixed 0 vulnerabilities in 0 packages
```

Read the `requests` line again: `2.19.1` → `2.33.0`. That's fourteen minor versions and a lot of behavior change. `Flask 0.12.2` → `3.1.3` crosses two major versions and will not run your old app unchanged. The "Fix Versions" column and `--fix` both present these as a free upgrade to safety; in reality each one is a migration with its own test burden. `--fix` is a fine starting point for a `urllib3` patch bump and a trap for a `Flask` major. The tool can't tell the difference between the two, and it presents them identically.

## Living with the noise

You will not fix all 36. That's not a failure of nerve, it's the nature of transitive advisories against pinned versions you don't control. The mechanism the tool gives you is per-ID suppression:

```bash
$ pip-audit -r requirements.txt --ignore-vuln PYSEC-2026-215 --no-deps
Found 35 known vulnerabilities, ignored 1 in 6 packages
```

Use it to silence advisories that are real but not reachable in your usage, with a comment saying why — an ignore list is a decision log, not a snooze button. And once you've actually patched, the payoff is the quiet exit you're gating CI on:

```bash
$ echo "requests==2.33.0" | pip-audit -r /dev/stdin
No known vulnerabilities found
$ echo "exit=$?"
exit=0
```

## The npm audit cousin, briefly

If this shape feels familiar, it's because `npm audit` is the same tool with the same disease: it reports against your full dependency tree, inflates the count with transitive advisories you can't patch, and its severity scores routinely overstate the risk to *your* app (a "critical" in a dev-only build dependency is not a critical in production). Everything below — CI-gate on the exit code, expect noise, don't auto-`--fix` a major bump — applies there too. `pip-audit` is the Python one, and it's honest enough to warn you that a requirements file isn't a lockfile.

## What made us close the tab

Nothing — it stays, wired into CI. But go in with the real expectations:

- **It audits your whole tree, not your file.** Most findings will be transitive (`idna`, `urllib3`) and not directly yours to patch. The count is bigger than the number of problems you can act on.
- **`-r` runs a real resolve.** A `ResolutionImpossible` error means your pins conflict, not that you're vulnerable — same exit code, different fix. Feed it a lockfile; `--no-deps` is the escape hatch and it'll nag you toward hashes.
- **`--fix` treats a `urllib3` patch and a `Flask` major-version jump as the same one-line upgrade.** They are not. Read every line before you let it write.
- **Severity and count are not your risk.** "36 known vulnerabilities" is a database join, not a threat model. For the part where you decide what's actually exploitable, that's [threat modeling](https://it-journey.dev/quests/1011/secure-coding/), not a scanner.

**When it goes wrong:** the day CI goes red on a dependency you can't upgrade — a transitive pin three libraries deep with no compatible fixed version — resist the urge to disable the whole check. Suppress that one ID with `--ignore-vuln` and a dated reason, keep the gate on for everything else, and put the real upgrade on the backlog. A scanner that's muted everywhere is worth exactly as much as one you never installed.
