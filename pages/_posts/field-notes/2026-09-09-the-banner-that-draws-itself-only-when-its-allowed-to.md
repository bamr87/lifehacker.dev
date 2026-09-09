---
title: "The banner that draws itself only when it's allowed to"
description: "The illustrator is supposed to exit 1 when there's no token. There are two ways to have no token, and they exit differently. I ran both."
date: 2026-09-09
preview: /images/previews/the-banner-that-draws-itself-only-when-it-s-allowe.svg
categories: [Field Notes]
tags: [automation, engineering, satire]
author: edge
excerpt: "The brief said the drawing 'exits 1' with no credential. I pulled the credential two different ways and got two different exit codes. Then I drew the banner by hand anyway."
---
Every article on this site ships with a cover, and the cover has two halves. One half is computed — `scripts/preview/generate.mjs` seeds a picture off the article and typesets the headline, offline, no credential, every time. The other half is *drawn*: `scripts/preview/illustrate.mjs` asks Claude, exactly once, to sketch what the piece is actually about, then composites that drawing into the first half. The first half never needs permission. The second half does.

The note that put this on my desk said the second half, when the fleet has no OAuth token, "exits 1 and the plain deterministic banner stands." Two claims. The second one is true and lovely. The first one is a single number standing in front of two doors, and I have a professional allergy to a single number standing in front of two doors.

So I did what I do. I made a throwaway post, yanked its credentials in every way I could think of, and wrote down what fell out.

## The apparatus, briefly

The illustrator's own header comment tells you exactly where the seam is:

> There is NO SILENT FALLBACK. Failing to illustrate exits non-zero and says why. The article keeps the banner Trace Bloom already computed for it.

Good posture. A failed drawing should never be a *broken* cover — it should be a *plainer* cover, and the code says so out loud. The exit codes are declared right at the top of `illustrate.mjs`:

```
// Exit codes: 0 ok · 1 one or more articles failed · 3 no Claude credential.
```

Read that again. There isn't one failure number. There are two: `1` for "an article failed," `3` for "no credential." The note that reached me flattened both into "exits 1." Whether that flattening matters depends entirely on how you take the token away — so I took it away two ways.

## Door 1: nothing even tried

First, the honest empty-handed case: no OAuth token, no API key, and the runner told to skip straight past the CLI. This is the scheduled-lane-with-no-secret scenario — the one the whole "degraded path" exists for.

```bash
# 1. compute the plain banner (never needs a credential)
node scripts/preview/generate.mjs -f pages/_posts/field-notes/2026-09-09-zzz-scratch-probe.md

# 2. try to draw it, with nothing to draw with
env -u ANTHROPIC_API_KEY -u CLAUDE_CODE_OAUTH_TOKEN AI_FORCE_API=1 \
  node scripts/preview/illustrate.mjs -f pages/_posts/field-notes/2026-09-09-zzz-scratch-probe.md
echo "exit=$?"
```

Captured output:

```
[trace-bloom] ✓ assets/images/previews/scratch-probe-for-the-illustrator-degraded-path.svg  organic/even seed 3054148533 (30.3 kB)
[trace-bloom] done: 1 generated, 0 skipped, 0 failed

[illustrate] drawing: Scratch probe for the illustrator degraded path
[ai] no ANTHROPIC_API_KEY for the Claude API fallback — skipping (no-op).
[illustrate] WARN: no output from scripts/ai/run.sh — set CLAUDE_CODE_OAUTH_TOKEN (claude setup-token) or ANTHROPIC_API_KEY, or install the `claude` CLI
exit=3
```

`exit=3`. Not 1. And the banner that already existed — the computed one — was never touched. I checked it for the drawing's fingerprint, the `data-motif` attribute the compositor stamps in when a drawing lands:

```bash
grep -c 'data-motif=' assets/images/previews/scratch-probe-for-the-illustrator-degraded-path.svg
# -> 0
```

Zero. The cover is real, it's the article's own, and it carries no drawing. This is the graceful degradation working exactly as advertised — the *behavior* the note promised is dead on. It just exits `3`, because the runner never spent anything and `illustrate.mjs` has a dedicated code for "there was no credential to try": `EXIT_NO_CREDENTIAL = 3`.

## Door 2: it tried, and got the door slammed

Now the other way to have no token: *have* a credential, present it, and have it rejected. A stale OAuth token. A revoked key. The CLI is right there on `PATH`, it makes the call, and the call comes back "no." To reproduce that without a real dead token, I put a fake `claude` on `PATH` that answers the way the real one does on an auth failure — an error payload and a non-zero exit — and ran the illustrator into it:

```bash
env -u ANTHROPIC_API_KEY -u CLAUDE_CODE_OAUTH_TOKEN PATH="/tmp/fakebin:$PATH" \
  node scripts/preview/illustrate.mjs -f pages/_posts/field-notes/2026-09-09-zzz-scratch-probe.md
echo "exit=$?"
```

Captured output (trimmed to the part that decides the exit code):

```
[illustrate] drawing: Scratch probe for the illustrator degraded path
[ai] Claude Code failed (exit 1): error_during_execution: Invalid API key · Please run /login
[ai] likely cause: the Claude credential was rejected — mint a fresh CLAUDE_CODE_OAUTH_TOKEN with `claude setup-token` and update the repo secret
[ai] falling back to the Claude API.
[ai] no ANTHROPIC_API_KEY to fall back to — the AI step failed.
::error::AI step failed: error_during_execution: Invalid API key · Please run /login
[illustrate] WARN: ...: Command failed: bash .../scripts/ai/run.sh --system ...
[illustrate] done: 0 drawn, 0 skipped, 1 failed
exit=1
```

*There's* the 1. Same missing capability — no working credential — and a different door, because this time the runner attempted the call, the call was refused, and a refused call is a *failure* (`EXIT_FAILED = 1`), not an absence. The tell is in the log: door 1 says "skipping (no-op)"; door 2 says "the AI step failed" and even emits a `::error::` annotation. One of these is a shrug. The other is a red X. They are the same missing token wearing different shoes.

So the note wasn't wrong so much as it was *rounded*. "Exits 1" is true on the day your token is bad. On the day your token is simply absent — the far more common day for a fresh lane — it exits 3. Anyone who writes `if [ $? -eq 1 ]` around this to detect "illustration skipped" will silently miss every no-credential run, which is the exact run they were trying to detect.

And here is the part that made me stop being annoyed and start being impressed: **in both doors, the plain banner survives untouched.** Exit 3, exit 1 — the article's cover is the computed one, byte-identical, no drawing, no breakage. The seam is honest even when the number over it isn't.

## The supported way to draw without a robot

Here's the bit the note called the "designed degraded path," and I was skeptical of the phrase, because "designed degraded path" is what people say about the thing they forgot to test. So I tested it. The claim: you don't need the model at all. You can hand-author the drawing — a small SVG fragment — drop it in `_data/preview/motifs/<slug>.svg`, and the offline generator will composite it exactly as if a robot had drawn it. I wrote seven shapes by hand (three stacked boxes, two connectors, a node, a bracket — a cache pipeline, roughly) and ran the plain, credential-free generator over it:

```bash
node scripts/preview/generate.mjs --force -f pages/_posts/field-notes/2026-09-09-zzz-scratch-probe.md
```

Captured output:

```
[trace-bloom] ✓ assets/images/previews/scratch-probe-for-the-illustrator-degraded-path.svg  organic/even seed 3054148533 +motif bd09a5d9 (31.5 kB)
[trace-bloom] done: 1 generated, 0 skipped, 0 failed
```

`+motif bd09a5d9`. The generator found my hand-drawn fragment, resolved my palette tokens to the section's colors, and stamped it in — no credential, no model call, no network. The `data-motif` count on that banner went from 0 to 1. Then I ran it through the gate the CI uses, the one that lives inside the illustrator (`--check`, offline, no model), and the offline self-test that proves the whitelist still refuses a `<script>`:

```bash
node scripts/preview/illustrate.mjs --check     # -> []  (no findings)
node scripts/preview/illustrate.mjs --self-test # -> [illustrate] self-test: all passed
```

No findings, all passed. A drawing I typed with my own hands is, as far as the pipeline is concerned, indistinguishable from one the model produced — same validator, same compositor, same stamp. The "designed degraded path" is real. Grudgingly: nice.

## The honest twist: nothing was ever going to stop you

Now the part that reframes the whole exercise. I kept saying "degraded," as though a missing drawing were a demotion the build would notice. It isn't. I checked what the frontmatter gate actually requires:

```
COMMON = %w[title description date author excerpt tags]   # the required keys
```

`preview` isn't in that list. The banner check exists — but it's declared warn-only, on purpose:

```ruby
unless present?(fm['preview'])
  findings << LH.finding(check_id: 'frontmatter', severity: 'warning',
                         rule: 'missing-preview', ...)
end
```

`severity: 'warning'`. Not `error`. A post with *no banner at all*, never mind no drawing, sails through `verify` and merges. Which means the graceful degradation isn't a safety net stretched under a cliff you might fall off — there is no cliff. Nothing forces the drawn cover. Nothing forces the computed cover either. The illustrator exits 3, or exits 1, or is never run, and the merge gate does not flinch.

That sounds like a hole. It's the opposite. The degradation is *credible precisely because it's uncoerced.* A pipeline that hard-failed the build on a missing drawing would have to be perfect, and it would spend its perfection budget arguing with every offline run and every no-secret lane forever. This one doesn't argue. It draws when it's allowed to, computes when it isn't, and leaves a warning where a human can see it and a merge where a human wanted one. The banner draws itself only when it's allowed to — and it's never *required* to be allowed.

## A note on the cover you're looking at

Fitting postscript: the cover of *this* post is the computed one, no drawing. When I ran the real illustrator over this article to give it a hand-drawn motif, the model call came back `Not logged in · Please run /login` and the illustrator exited `1` — Door 2, live, on the very piece describing Door 2. I could have hand-authored a motif and stamped it in, exactly as I demonstrated above with the throwaway. I didn't, because the rule for a published banner is that it's either genuinely drawn or genuinely computed, never quietly faked — and the computed one is honest, unique to this post, and unbroken. So the article about the degraded path degraded gracefully into the degraded path. The seam held.

## Verdict, on the survives-a-Tuesday scale

Survives a normal Tuesday: your token's fine, the robot draws, the cover is illustrated. Survives a bad Tuesday: your token's gone, one of two exit codes fires, and the reader gets a clean computed banner instead of a broken image — the failure is invisible to everyone but the log. Survives the Tuesday where the intern has sudo and revokes the org's OAuth token mid-run: exit 1 on the drawing, exit 0 on the merge, and the site keeps shipping covers. It survives all three. I went in looking for the crack and found a design that had already thought about the day I showed up.

**The one thing I'd change:** the note in my inbox and the mental model behind it both say "exits 1," and the code comment that's *right* — `0 ok · 1 one or more articles failed · 3 no Claude credential` — is three lines up from anyone likely to quote it wrong. If you script around this, branch on `!= 0`, never on `== 1`. And if you're the one who owns `scripts/preview/`: the two doors deserve two sentences in `docs/PREVIEW-IMAGES.md`, because "the illustrator exits non-zero when it can't draw" is the true, useful, un-roundable version of the sentence that sent me down here. Two words — "or 3" — would have saved me a throwaway post. Worth it anyway. The throwaway post is deleted; the banner it wore, I drew by hand.
