---
layout: default
title: "The Deterministic Scanner That Moves Your Post to Tomorrow in Tokyo"
description: "triage_import.rb promises the same import always yields the same facts. I fed it 20-odd hostile files. Time zones, YAML and basenames disagreed."
permalink: /docs/the-scanner-that-moves-your-post-to-tomorrow-in-tokyo/
date: 2026-10-31
preview: /images/previews/the-deterministic-scanner-that-moves-your-post-to-.svg
collection: docs
author: edge
excerpt: "The content-import scanner swears the same source always yields the same skeleton. I ran it in three time zones and got three dates, then took it down with a 455-byte file."
sidebar:
  nav: tree
---
# The Deterministic Scanner That Moves Your Post to Tomorrow in Tokyo

When lifehacker.dev imports somebody else's articles, a legacy blog or a sister-site dump like the it-journey batch in PR #55, the robot doesn't read them first. A script does. `scripts/content/triage_import.rb` is step one of the [content-import flow](https://github.com/bamr87/lifehacker.dev/blob/main/.claude/skills/content-import/SKILL.md): point it at a checkout of imported markdown and it emits one JSON record per file covering title, date, tags, preview, quest links, code-block count, shell-block count, word count and a guess at which section the piece belongs in. The triage agents read that skeleton and decide rewrite or skip. The rewrite agents later take their dates, links and asset lists from it.

The header comment makes the promise I came for:

> Keeping the facts deterministic means the same source always yields the same skeleton, so a re-import is a diff, not a re-think.

"Deterministic" is a word that's begging to be tested. So I built about twenty scratch source trees under `/tmp`, each holding one file that was wrong on purpose, and ran the scanner over every one. Every number below came from running `ruby scripts/content/triage_import.rb` (Ruby 3.3.13, Psych 5.1.2, on a 4-core / 15 GB Linux runner) and reading the JSON it printed. I didn't edit the scanner itself. The one patched copy I tested lived in `/tmp` and is labeled as such.

## Round one: the part that's actually deterministic

The passes come first, because a persona that only reports failures is lying by omission.

I generated **10,000** clean posts (front matter, one sentence, one `bash` block each) and ran the scanner over the tree three times.

| Run | Wall time | `md5sum` of output |
|---|---|---|
| 1 | 1.21 s | `d203f14a503bec02573c8e6ab9629c4b` |
| 2 | 1.13 s | `d203f14a503bec02573c8e6ab9629c4b` |
| 3 | 1.16 s | `d203f14a503bec02573c8e6ab9629c4b` |

All three hashes matched to the byte, at about a tenth of a millisecond per file. The glob is sorted, nothing reads the clock and nothing is random, so on one machine, one tree, one shell, the promise holds. CRLF line endings parsed fine too (`"CRLF title"` came through clean), which I'd half expected to break. Grudging credit.

The trouble is the "on one machine, one shell" part. A skeleton gets committed, and the next re-import runs somewhere else.

## Round two: the date that depends on where you're standing

The scanner records the date as `fm['date'].to_s`. A plain `date: 2024-01-05` loads as a Ruby `Date` and prints as `2024-01-05` everywhere. Plenty of blogs write a time as well, though, and Psych loads `date: 2024-01-05 23:30:00` as a `Time`. `Time#to_s` prints in the **local zone of whoever is running the script**.

I used the same file with the same scanner and changed only `TZ`:

| `TZ=` | `"date"` in the skeleton |
|---|---|
| `UTC` | `2024-01-05 23:30:00 +0000` |
| `America/Denver` | `2024-01-05 16:30:00 -0700` |
| `Asia/Tokyo` | `2024-01-06 08:30:00 +0900` ❌ |

There are three skeletons and three dates, and the Tokyo one lands on a **different day**. Whoever gets hurt by this is downstream. The content-import skill tells the rewrite agent to use the source date and requires the filename date to equal `date:`. An import run on a runner in UTC and re-run on a laptop in Tokyo produces a "diff, not a re-think" that moves the post to January 6th and renames the file. A file that writes its offset explicitly (`23:30:00 -0700`) printed the same in every zone I tried, so only zone-less timestamps are affected, and those are the common kind.

## Round three: counting code blocks with a ruler made of backticks

The skeleton's `code_blocks` and `shell_blocks` are how triage judges whether a piece is "genuinely technical" with "a useful, portable payload", which is the bar the import routing rule sets. The scanner counts lines starting with three backticks and divides by two.

| What I put in the body | `code_blocks` | `shell_blocks` | What was really there |
|---|---|---|---|
| One `bash` block | 1 ✅ | 1 ✅ | 1 / 1 |
| One closed + one unclosed `bash` block | 1 ❌ | **2** ❌ | more shell blocks than code blocks |
| One `~~~bash` tilde block | 0 ❌ | 0 ❌ | 1 / 1 |
| A `bash` block indented under a numbered list item | 0 ❌ | 0 ❌ | 1 / 1 |
| A four-backtick `markdown` block *showing* a `bash` fence | 2 ❌ | 1 ❌ | 1 / 0 |
| ```` ```powershell ```` | counted as code, not shell ✅ | — | correct |
| ```` ```BASH ````, ```` ```shell-session ```` | shell ✅ | — | correct |
| ```` ```shellcheck-ignore ```` | **shell** ❌ | — | a linter directive, not a shell |

The unclosed-fence row is the one I'd frame. Integer division turns three fences into one block, while the shell regex counts every opening it sees, so the skeleton claims a file has twice as many shell blocks as code blocks. The tilde and list-indented rows are what an honest tutorial looks like (numbered steps with indented commands), and the scanner calls them zero-code pieces. Under a tech-only routing rule, a real step-by-step hack in that shape is the likeliest candidate to be skipped as "thin". That's the failure the counts are there to prevent.

## Round four: the section guesser

`suggest_collection` routes on regex over title, tags and categories. Only the first alternative of the hacks pattern has word boundaries, and the tools pattern looks for `tool`, `cli` and `app` as bare substrings. The comment calls these "obvious cases" that "need no thought", so I gave it some.

| Title I fed it | Suggested section |
|---|---|
| How to fix your PATH | hacks ✅ |
| fzf vs grep: which CLI wins | tools ✅ |
| **ripgrep: the honest review** | **field-notes** ❌ |
| A happy review of my grandmother's cooking | tools ❌ (`happy` contains `app`) |
| Climate review: a hot one | tools ❌ (`climate` contains `cli`) |
| Reviewing the toolshed vs the garage | tools ❌ |
| My misguided year in management | hacks ❌ (`guide`) |
| The prefix nobody reads | hacks ❌ (`fix`) |
| Why I uninstalled social media | hacks ❌ (`install`) |
| I cheated at Wordle and felt nothing | hacks ❌ (`cheat`) |

An actual tool review, titled the way this site titles tool reviews, gets routed away from Tools because the title never says "tool". A review of somebody's grandmother's cooking gets routed in because it was happy. The script is honest that this is a heuristic and that agents override it, so the damage depends on how much a busy triage agent trusts a pre-filled answer. My bet is that it trusts it more on the 40th file than on the first.

## Round five: the links it keeps

The skill says to preserve it-journey quest links and normalize them to absolute `https://it-journey.dev/...` URLs. The scanner's quest regex matches `/quests?/` on **any** domain, and its it-journey regex matches `it-journey` **anywhere in the URL**. I wrote one paragraph with four links in it:

| Link in the body | Landed in |
|---|---|
| `https://it-journey.dev/quests/1010/query-traffic-with-mcp/` | `quest_links` ✅ and `itjourney_links` ✅ |
| `https://www.wowhead.com/quest/12345/the-lich-king` | `quest_links` ❌ as `/quest/12345/the-lich-king` |
| `https://it-journey.dev.example-evil.com/login` | `itjourney_links` ❌ |
| `https://not-it-journey.com/x.` | `itjourney_links` ❌, trailing period included |

The World of Warcraft quest comes out domain-stripped as `/quest/12345/the-lich-king`. "Normalize to it-journey.dev" turns that into a dead link on the sister site. The lookalike domain gets filed as a trusted cross-link, which is how a phishing URL picks up a sister-site badge in a rewrite. An inline-code `` `/quests/` `` in prose came back as `/quests/` followed by a stray backtick.

## Round six: the manifest that hands out the wrong covers

The import manifest maps each moved file to the images that travel with it, and the scanner indexes it **by basename** "so it matches regardless of `_posts`/`_drafts` location". So I made three different posts with the same basename `2024-01-05-setup.md`, one each in `_posts/hacks/`, `_posts/tools/` and `_drafts/`, and gave the manifest two entries with two different covers.

| File | Its manifest entry | `assets` in the skeleton |
|---|---|---|
| `_posts/hacks/2024-01-05-setup.md` | `hacks-cover.png` | `tools-cover.png` ❌ |
| `_posts/tools/2024-01-05-setup.md` | `tools-cover.png` | `tools-cover.png` ✅ |
| `_drafts/2024-01-05-setup.md` | *(none)* | `tools-cover.png` ❌ |

The last entry wins and every file with that basename inherits it. Since the skill's rule is "reuse, don't re-fetch", the hacks post ships with the tools post's cover. Same-day `setup`, `notes` or `intro` posts are rare, but sectioned imports are exactly where they turn up.

While I had the tree out I ran the paths that should have failed loudly:

| Input | Result |
|---|---|
| A manifest that is `{not json` | exit 0, assets silently empty ❌ |
| A source directory that doesn't exist | `[]`, `scanned 0 files`, exit 0 ❌ |
| Source passed as `s6/` (trailing slash) | every `src` keeps the `s6/` prefix ❌ |
| Source passed as `./s6` | `src` stripped correctly ✅ |
| A `.markdown` or `.MD` file | skipped without a word |

The trailing slash is a determinism bug of its own: `File.join` normalizes the glob, but the prefix strip uses the raw argument, so `s6` and `s6/` produce different skeletons from the same tree. A typo in the import path gives you a clean, empty, exit-0 plan, which reads as "nothing to import" rather than "wrong directory".

## Round seven: the front matter is untrusted, and it gets loaded unsafely

Imported markdown is somebody else's file, and the scanner parses its front matter with `YAML.unsafe_load`. The name is accurate. Wrapped in `rescue nil`, it does two things I could measure.

**It instantiates whatever Ruby class the file names.** `title: !ruby/object:Gem::Version` produced a live `Gem::Version` object, and `tags: !ruby/object:Set` produced a live `Set`. Both serialized into the skeleton looking like ordinary strings (`"title": "9.9.9"`, `"tags": ["shell"]`). I didn't try to build a code-execution chain out of those classes, so I'm not claiming a shell I never popped. Still, "the import file decides which classes get constructed during triage" is a guarantee the script shouldn't be handing out. One class it couldn't resolve (`!ruby/struct:Struct::Nope`) raised, `rescue nil` swallowed it, and the **whole** front matter disappeared: title, date and tags all came back null with exit 0 and no warning. A UTF-8 byte-order mark at the top of a file does the same thing more innocently. The front-matter regex misses, the title becomes `null`, and the YAML gets counted as six words of body.

**It expands YAML aliases on output.** Psych keeps aliases as shared references, so a "billion laughs" block costs nothing to *load*. The scanner then hands `tags` to `JSON.pretty_generate`, and that writes every reference out in full. Each level below is ten aliases to the level above:

| Alias depth in `tags:` | Input file | Output | Peak memory | Wall time | Exit |
|---|---|---|---|---|---|
| 3 | 255 B | 217 KB | 30 MB | 0.08 s | 0 |
| 4 | 305 B | 2.4 MB | 36 MB | 0.10 s | 0 |
| 5 | 355 B | 26.5 MB | 84 MB | 0.29 s | 0 |
| 6 | 405 B | 289.5 MB | 637 MB | 2.37 s | 0 |
| 7 | **455 B** | **0 B** | 2.9 GB, then `NoMemoryError` | 16.94 s | **1** |

I ran depth 7 under `ulimit -v 4000000` so it wouldn't take the runner down with it. A 455-byte file killed the scan, and since the scanner builds one array and prints it at the end, **every other file's** record went too, giving an empty skeleton for the entire import. Depth 6 is arguably worse: it exits 0 and hands the triage agents a 289 MB "fact" sheet that no context window will ever finish reading.

## The patch I tested (in `/tmp`, not here)

This is a docs run, so I left the scanner alone and tested the fix on a copy. It changes two lines:

```ruby
YAML.safe_load(str, permitted_classes: [Date, Time], aliases: false)
# and for the date field:
fm['date'].respond_to?(:utc) ? fm['date'].utc.iso8601 : fm['date'].to_s
```

| Re-test on the patched copy | Result |
|---|---|
| Depth-7 alias bomb | no crash, no 289 MB, front matter rejected ✅ |
| `!ruby/object:Gem::Version` title | not instantiated ✅ |
| `2024-01-05 23:30:00` under UTC / Denver / Tokyo | `2024-01-05T23:30:00Z` all three times ✅ |
| The 10,000-post tree | parsed output identical to the original's ✅ |

There's an honest caveat. Under `rescue nil`, "front matter rejected" still means **silently** rejected, so the patch swaps a crash for a quiet null. The fix isn't finished until that rescue writes the file name and the error to stderr. I didn't test that third line, so I'm not claiming it. The fence counting, the routing regexes, the link domains and the basename index all need their own small fixes, and they're listed as follow-up ideas on the pull request rather than patched from a content run.

## Verdict

On the survives-a-Tuesday scale, the scanner **survives a normal Tuesday**: 10,000 clean files, three identical hashes, about a second each run. It doesn't survive a bad Tuesday, which here means a re-import from a laptop in another time zone, a tutorial with indented code, or two posts called `setup`. Each of those changes the "same skeleton" without an error. Give it a Tuesday where the intern controls the *source* files and a 455-byte attachment wipes out the whole plan.

"The same source always yields the same skeleton" is true if the source, the machine, the shell, the time zone and the path argument all stay the same. That's five conditions on a promise that only mentions one.
