---
title: "I built a CLI that writes its own PRD from git history, and it started documenting itself"
description: "A small Python CLI that distills a product requirements doc from git log, flags reverts and fixes as conflicts, and shouts when the doc goes stale."
date: 2025-11-28
categories: [Field Notes]
tags: [automation, cli-tools, documentation, python, git]
author: amr
excerpt: "The requirements doc is always stale. So I made the git log write it — and then the script ended up describing the script."
preview: /assets/images/previews/prd-machine-building-a-self-writing-product-requir.png
---

![A retro machine assembling a product requirements doc from git history](/assets/images/previews/prd-machine-building-a-self-writing-product-requir.png)

The product requirements doc goes stale the instant you save it. Not because anyone is lazy — because the truth lives in the commit log and the markdown files, and the PRD lives in a separate document that nobody remembers to update. So the PRD drifts, and three weeks later it describes a product that no longer exists.

I got tired of being the person who remembers. So I wrote a small CLI that reads the signals already in the repo — git commits, markdown front matter, a feature list — and regenerates the doc. The real win is not the doc. It's that the doc can never be more than one run out of date, because a run is one command.

This is the working version, including the parts where it broke.

## The one command that does the thing

Three subcommands. `sync` writes the doc, `status` tells you how stale it is, `conflicts` shows the contradictions it found.

```python
def main():
    parser = argparse.ArgumentParser(description="Generate a PRD from repo signals")
    sub = parser.add_subparsers(dest="command")

    sync = sub.add_parser("sync", help="generate or update PRD.md")
    sync.add_argument("--days", type=int, default=30)
    sync.add_argument("--output", default="PRD.md")

    sub.add_parser("status", help="check how stale the PRD is")
    sub.add_parser("conflicts", help="show detected requirement conflicts")
```

Nothing clever. The clever part is what feeds it.

## Reading git as a list of decisions

A commit history is a record of decisions. You only have to get it out of git in a shape you can parse. The trick is `--pretty=format` with a delimiter that won't show up in a commit subject. I used a pipe, which is good enough until someone writes a commit message with a pipe in it (more on that below).

I actually ran this against this repo to confirm the shape:

```bash
# lh:run
git log --since=2025-01-01 --pretty=format:'%h|%s|%an' -n 8
```

```console
ab81285|content-import: require front-matter preview: + plain code fences (#62)|Amr
097c068|hacks: 10 it-journey imports rewritten on-voice (import batch 1) (#61)
2bd303f|content-import: a repeatable triage→rewrite→batch flow for bulk imports (#60)
dcc19e0|doc: how the robot grades its own homework (the verification harness) (#59)
5766cb8|post: the day my to-do list had nothing I was allowed to do (#58)
f0f0d1e|tool: jq — the JSON tool you paste and pray, reviewed honestly (#57)
```

One field per pipe, one decision per line. The Python that consumes it is exactly that, with a `--since` window so you only ingest recent history:

```python
def ingest_git_commits(self, days=30):
    since = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%d")
    out = subprocess.run(
        ["git", "log", f"--since={since}", "--pretty=format:%H|%s|%an|%ad"],
        capture_output=True, text=True,
    ).stdout

    commits = []
    for line in filter(None, out.splitlines()):
        parts = line.split("|")
        commits.append({
            "sha": parts[0][:7],
            "subject": parts[1],
            "author": parts[2] if len(parts) > 2 else "",
            "date": parts[3] if len(parts) > 3 else "",
        })
    return commits
```

Markdown files get ingested the same way — glob the content directories, parse the front matter, keep the title and tags. Feature definitions, if you keep a `features.yml`, are one `yaml.safe_load`. None of that is interesting. The commits are where the signal is.

**You'll know it worked when** `status` reports a non-zero commit count and the generated doc names commits you recognize.

## Conflicts are just commit messages, read suspiciously

This is the part I expected to be hard and turned out to be embarrassingly simple. A "requirement conflict" leaves fingerprints in the log. A revert means a decision was un-made. A `fix:` commit means the original requirement was wrong or incomplete. You don't need an LLM for this. You need `grep`.

I tested the heuristic on a throwaway repo before trusting it:

```bash
# lh:run
cd "$(mktemp -d)"
git init -q && git config user.email a@b.c && git config user.name t
git commit -q --allow-empty -m "feat: add login"
git commit -q --allow-empty -m "fix: login crashes on empty password"
git commit -q --allow-empty -m 'Revert "feat: add login"'
git log --pretty=format:'%s' | grep -iE '^(revert|fix)'
```

```console
Revert "feat: add login"
fix: login crashes on empty password
```

Two lines out of three. Those two are the conflicts: a feature that got reverted, and a fix that implies the spec missed a case. In Python it's the same predicate:

```python
def detect_conflicts(self):
    conflicts = []
    for c in self.signals.get("commits", []):
        subject = c["subject"].lower()
        if subject.startswith("revert") or subject.startswith('revert "'):
            conflicts.append({"type": "revert", "source": c,
                "note": "a change was reverted — a decision got un-made"})
        if subject.startswith("fix:") or "bug" in subject:
            conflicts.append({"type": "fix", "source": c,
                "note": "a fix implies the requirement missed a case"})
    return conflicts
```

It is a blunt instrument. It will flag a `fix: typo in README` as a requirements conflict, which is wrong, and it will miss a conflict expressed in prose with no keyword, which is also wrong. But blunt and running beats sharp and imaginary. It surfaces the commits a human should look at, and a human still decides.

## The part where it broke: the pipe in the message

The delimiter was the bug, of course. The first time someone landed a commit with a `|` in the subject — a table, a shell pipe quoted in the message — `line.split("|")` produced extra fields and shoved half the subject into the author column. The doc came out with a commit "authored by" the second half of its own message. It didn't crash. It lied quietly instead, which is worse.

Two honest fixes. Either pick a delimiter that can't occur in a subject — git supports `%x00` for a NUL byte and `%x1f` for ASCII unit-separator — or use `split("|", maxsplit=3)` so anything past the last field you care about stays glued together. I went with `maxsplit` because a NUL-delimited stream is a pain to eyeball when you're debugging:

```python
parts = line.split("|", 3)   # subject keeps its pipes; author column stays clean
```

**You'll know it worked when** a commit whose subject contains a pipe still shows the right author in the generated doc.

## Telling you when it's stale

The whole point is freshness, so the doc has to be able to report its own age. That's the file's modification time against now:

```python
def check_status(self):
    prd = Path(self.repo_path) / "PRD.md"
    if not prd.exists():
        return self.log("WARNING", "no PRD yet — run sync")

    mtime = datetime.fromtimestamp(prd.stat().st_mtime, tz=timezone.utc)
    age_hours = (datetime.now(timezone.utc) - mtime).total_seconds() / 3600

    if age_hours < 6:
        self.log("OK", f"fresh ({age_hours:.1f}h)")
    elif age_hours < 24:
        self.log("WARNING", f"stale ({age_hours:.1f}h)")
    else:
        self.log("ERROR", f"outdated ({age_hours:.1f}h)")
```

Mtime, not a timestamp baked into the doc. If you write "last synced" into the file body, the act of writing it makes it true even when the content is wrong. Mtime is the file system telling you the truth instead of the file telling you what it wishes were true.

## Wiring it to CI

To keep the doc honest you run `sync` on a schedule and on the pushes that change the signal, then commit the result if it changed. This block talks to GitHub Actions, so it's documentation, not something I ran on this laptop.

{% raw %}
```yaml
name: prd sync
on:
  schedule:
    - cron: '0 */6 * * *'      # every 6 hours
  push:
    branches: [main]
    paths: ['pages/_posts/**', 'features/**']
jobs:
  sync-prd:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0        # without this, --since sees almost no history
      - uses: actions/setup-python@v5
        with: { python-version: '3.11' }
      - run: ./prd-machine sync
      - run: |
          git config user.name "prd-bot"
          git add PRD.md
          git diff --staged --quiet || git commit -m "chore(prd): auto-sync"
          git push
```
{% endraw %}

The line that bit me there is `fetch-depth: 0`. Actions does a shallow clone by default, so `git log --since` ran against a history one commit deep and produced an almost-empty PRD on every scheduled run. The doc kept "freshening" itself into nothing. Fetch the full history or the whole exercise distills air.

## The part I didn't expect

Once it ran against its own repo, the script started documenting itself. Its commits were in the log, so its own features showed up in the doc it generated — including a `fix:` for the pipe bug, which it dutifully filed as a requirements conflict against itself. That's not as profound as it sounds. It's a parser reading a log that happens to contain the parser. But it's a good reminder of the actual limit here: the tool surfaces signal, it doesn't have judgment. The revert it flags might be the right call. The fix it flags might be a typo. Keep the human veto, because the failure mode of an automated documenter isn't laziness — it's confident, well-formatted fiction.

## What this is and isn't

It's a way to make the requirements doc a build artifact instead of a chore — generated, dated, and loud when it rots. It is not a replacement for deciding what to build. It reads the decisions you already made and writes them down so you stop being the one who remembers. The day I stopped remembering was a good day.
