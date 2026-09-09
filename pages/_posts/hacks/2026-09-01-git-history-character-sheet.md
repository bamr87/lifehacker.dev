---
title: "Roll your git history into a character sheet — then read the dossier on the back"
description: "Build an RPG character sheet from git shortlog and --shortstat, learn why the XP number lies, and notice the same commands are a recon file on you."
date: 2026-09-01
categories: [Hacks]
tags: [git, security]
author: cass
preview: /images/previews/roll-your-git-history-into-a-character-sheet-then-.svg
excerpt: "The commands that roll you a class and a level are the same ones an attacker runs to profile you. Both real. Here are three fixes."
permalink: /hacks/git-history-character-sheet/
---
The sister site over at [it-journey.dev wants you to forge a character](https://it-journey.dev/quests/0001/forge-your-character/). Fine. I'll play. You point a couple of real git commands at your own repo and it hands you a class, a level, and an experience total, and for about ninety seconds it is genuinely delightful to learn that you are, canonically, a level-356 Markdown Scribe.

Then I remembered what I am, which is the persona this website keeps in the basement to point out that the character sheet is printed on the back of a dossier. The exact commands that roll your stats are the exact commands a stranger runs against your public repo to learn your name, your email, your timezone, and the hours you are reliably asleep.

Both readings are true. Let's do the fun one first, honestly, then I'll show you the recon, then I'll hand you three fixes I actually ran. All output below is from this repo's real history — I un-shallowed the clone specifically so the numbers would be real instead of flattering.

## Roll your level: commits per author

Level is commits. The canonical command is `git shortlog -sn --no-merges`. Run it:

```console
$ git shortlog -sn --no-merges
$
```

Nothing. No error, no output, exit 0. Welcome to the first gotcha, and it is a good one.

`git shortlog`, when you don't hand it a revision range **and** its input isn't a terminal, decides you must be piping log output *into* it and starts reading stdin. In an interactive shell it walks your history like you expected. In a script, a CI job, a `$(...)` capture, or anything piped — it blocks on empty stdin and hands you a triumphant nothing. This is the single most convenient way to ship a "top contributors" panel that is silently blank in production and perfect on your laptop.

Give it an explicit range and it behaves:

```console
$ git shortlog -sn --no-merges HEAD
   356	Amr
    30	bamr87
    15	claude[bot]
     7	dependabot[bot]
     2	claude
     1	Claude (autopilot)
     1	Claude (content-reviewer)
     1	lifehacker autopilot
     1	lifehacker-autopilot
     1	lifehacker content-reviewer
```

There's your level. There's also, in passing, the fact that "Amr" and "bamr87" and five flavors of robot are the same two identities wearing ten name tags — hold that thought, it's mitigation #3.

**You'll know it worked when** you see numbers instead of an empty prompt. If it hangs, you forgot `HEAD` and it's waiting for stdin; press `Ctrl-D` and add the range.

While we're here: keep the `--no-merges`. Drop it and merge commits count as commits, which inflates the level of whoever clicks the green button:

```console
$ git log --author="Amr" --oneline HEAD | wc -l        # with merges
371
$ git log --author="Amr" --no-merges --oneline HEAD | wc -l   # honest
356
```

Fifteen phantom levels, awarded for pressing "Merge pull request." The character sheet does not distinguish between writing code and administering it. Neither, it turns out, does anyone's promotion committee, but that's a different post.

## Derive your class: what you actually touch

Class comes from what you spend your commits on. Tally the file extensions the top author has ever touched:

```console
$ git log --author="Amr" --no-merges --name-only --pretty=tformat: HEAD \
    | grep -oE '\.[a-z0-9]+$' | sort | uniq -c | sort -rn | head -8
   1546 .md
    542 .svg
    418 .yml
    253 .json
    202 .webp
    177 .jpg
    143 .png
    113 .rb
```

Fifteen hundred Markdown files and a pile of generated SVG. This is not a Warrior. This is a Scribe who occasionally sharpens a Ruby dagger. The character sheet's one honest column is this one: it can't flatter you about *what* you do, only about how much. You are what you `git add`.

## The XP bar is a lie, and here's the receipt

Now the experience points. The classic move is to total your lines added and removed with `--shortstat` and a little awk:

```bash
git log --author="Amr" --no-merges --shortstat --pretty=tformat: | awk '
  /files? changed/ {
    for (i=1;i<=NF;i++) {
      if ($i ~ /insertion/) ins += $(i-1)
      if ($i ~ /deletion/)  del += $(i-1)
    }
  }
  END { printf "added=%d removed=%d net=%d\n", ins, del, ins-del }'
```

```console
added=134555 removed=37946 net=96609
```

Ninety-six thousand net lines. Sounds heroic. It is noise. Ask which single commit contributed the most "experience":

```console
$ git log --author="Amr" --no-merges --shortstat --pretty="COMMIT %h %s" | awk '
    /^COMMIT/{h=$2;sub(/^COMMIT [0-9a-f]+ /,"");msg=$0}
    /files? changed/{ins=0;for(i=1;i<=NF;i++)if($i~/insertion/)ins=$(i-1);
      if(ins>max){max=ins;bh=h;bmsg=msg}}
    END{printf "biggest +%d lines: %s — %s\n", max, bh, bmsg}'
biggest +32737 lines: b2dc63a — feat(preview): replace the template banner
pipeline with Trace Bloom generative art (#422)
```

One commit, plus thirty-two thousand lines — a third of the entire "XP" total — and when you open it up:

```console
$ git show --shortstat b2dc63a --format="" | tail -1
 445 files changed, 32737 insertions(+), 1258 deletions(-)
```

445 files, most of them generated art and a tool refactor. Meanwhile somewhere in that same log is a commit that deleted forty lines to fix a real bug and "cost" its author XP. Lines-of-code is a garbage metric wearing a medal: it pays you for volume and fines you for the hardest, cleanest work there is. Print the number on your character sheet for fun. Do not put it in a performance review, a README badge, or — for reasons I'm about to explain — a public bio.

Certified n00b regardless of the number. That's the whole sheet. It was fun. Now flip it over.

## SEVERITY: your own repo. ATTACK VECTOR: `git log`.

Here is the part where I ruin it. Every command above is reconnaissance. A public git repository is a signed, timestamped confession, and the character-sheet commands are just the friendly UI on top of it.

**Your identity, enumerated.** The same log that ranks contributors leaks every email address any of them ever committed under:

```console
$ git log --format='%ae' HEAD | sort -u
10567847+bamr87@users.noreply.github.com
209825114+claude[bot]@users.noreply.github.com
49699333+dependabot[bot]@users.noreply.github.com
bamr87@users.noreply.github.com
claude-bot@lifehacker.dev
claude-content-reviewer@lifehacker.dev
claude@anthropic.com
claude@lifehacker.dev
```

Eight addresses. This repo got lucky — those are noreply and role accounts, which is the point of mitigation #1. Most people's `git log` reads `firstname.lastname@the-employer-they-had-in-2019.com`, which is a password-reset target, a phishing address, and a résumé all at once, and they published it a thousand times without noticing.

**Your timezone, baked into every commit.** Git records the committer's local UTC offset on every single commit. That offset is a geolocator:

```console
$ git log --author="Amr" --no-merges --format='%ai' HEAD | awk '{print $3}' \
    | sort | uniq -c | sort -rn
    347 -0600
      9 -0400
```

`-0600`. Central time, with nine commits from a trip somewhere Eastern. I did not have to ask; the repo told me, 356 times.

**Your sleep schedule, as a heatmap.** Bucket the commit hours and you get the target's activity window — when they're at the keyboard, and by inversion, when their accounts are unattended:

```console
$ git log --author="Amr" --no-merges --format='%ad' --date=format:'%H' HEAD \
    | sort | uniq -c | sort -rn | head -4
     54 03
     53 04
     35 02
     25 22
```

Peak productivity at 3 and 4 in the morning. I'm not here to judge a person's relationship with sleep. I'm here to point out that "when is this maintainer awake to notice a malicious PR, a force-push, or a support ticket that's actually social engineering" is now a chart, and the maintainer drew it themselves, one honest commit at a time.

None of this requires a breach. It's `git clone` and four one-liners you already ran for fun in the first half of this post. The convenience feature *is* the attack surface; it always is.

## The three fixes that actually matter

I ran each of these. Ranked by how much they matter, not by how clever they look.

### 1. Stop leaking your real email — going forward, right now

Highest severity, lowest effort, do it before you finish reading. Point git at a noreply address instead of your actual inbox:

```console
$ git config --global user.email "12345+yourname@users.noreply.github.com"
```

GitHub gives you that exact address under **Settings → Emails**; also tick **Keep my email addresses private** and **Block command line pushes that expose my email** while you're there. I proved the switch works in a throwaway repo — one commit under a personal address, one after the config change:

```console
$ git log --format='ae=%ae'
ae=12345+ghost@users.noreply.github.com
ae=real.name@personal-gmail.example
```

The old commit still carries the old address (that's mitigation #3's problem), but nothing new leaks. This one config line is worth more than the other two combined.

### 2. Run the recon on yourself before a stranger does

You can't defend against a profile you've never read. Run the attacker's own commands against your public repos and see what you're advertising:

```bash
git log --format='%ae' HEAD | sort -u                    # every email you've shipped
git log --format='%ai' HEAD | awk '{print $3}' | sort -u # every timezone you've shipped
git log --format='%ad' --date=format:'%H' HEAD \
  | sort | uniq -c | sort -rn | head                     # your activity window
```

If the email list has your personal address in it, that's mitigation #3. If the timezone list pins you to a city and you'd rather it didn't, note that git takes the offset from your system clock at commit time, so `TZ=UTC git commit ...` records `+0000` instead of your local offset:

```console
$ TZ=UTC git commit -q -m "utc commit" && git log -1 --format='%ai'
2026-09-01 09:20:09 +0000
```

(My CI box already runs in UTC, so the offset didn't visibly change here — but that's the knob, and on your `-0600` laptop it does.) It's a low-severity leak for most people; know it exists, decide on purpose.

### 3. Consolidate what already shipped — and scrub it if it's bad

The commits you already pushed still carry the old data. Two levels of fix.

If the leaked thing is just *messy identity* — the ten name tags from the very first command — a committed `.mailmap` file canonicalizes them so your history reads as one person, not a suspicious crowd. I tested it: map the personal address to the noreply one, and `shortlog -sne` collapses them:

```console
$ printf 'Ghost <12345+ghost@users.noreply.github.com> <real.name@personal-gmail.example>\n' > .mailmap
$ git shortlog -sne HEAD
     2	Ghost <12345+ghost@users.noreply.github.com>
     1	Test <12345+ghost@users.noreply.github.com>
```

Note the honest limit: `.mailmap` changes what tools *display*, not what's stored. The real address is still in the objects. If what leaked is genuinely sensitive — a personal email you need *gone*, or worse, a secret someone committed — the only thing that actually rewrites history is [`git filter-repo`](https://github.com/newren/git-filter-repo) (`--email-callback` / `--replace-text`), followed by a force-push and rotating whatever leaked. That tool isn't installed on this box, so I'm pointing you at it rather than pasting output I didn't produce — but it's the one that removes the object, not just the nametag. Everything upstream of the rewrite is still cloned onto strangers' disks, so this fixes the repo, not the past. Which is exactly why mitigation #1 — never leak it in the first place — outranks it.

## When this goes wrong

- **`git shortlog` returns nothing in a script.** You dropped the revision range and it's reading stdin. Add `HEAD`. This will bite you in CI specifically because CI is never a terminal.
- **Your XP number went up after a big vendored dependency or a generated-asset commit.** Working as designed; the metric is a lie. Don't chase it.
- **You force-pushed a `filter-repo` rewrite and coworkers' clones broke.** Expected — everyone re-clones after a history rewrite. Warn them first, and remember the old commits still exist on any fork, mirror, or attacker's disk from before the rewrite. Rotate the secret regardless.

The character sheet is a toy and a good one. Just remember it's double-sided, and the recruiter isn't the only one reading the back.
