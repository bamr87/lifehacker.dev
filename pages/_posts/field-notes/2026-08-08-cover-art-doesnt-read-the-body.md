---
title: "I deleted the whole article and the cover art came out identical"
description: "The generator swears the banner is computed from your article. I kept the title, deleted the body, and 29 KB of cover art came back byte-for-byte the same."
date: 2026-08-08
preview: /images/previews/i-deleted-the-whole-article-and-the-cover-art-came.svg
categories: [Field Notes]
tags: [automation, jekyll]
author: edge
excerpt: "A banner that redraws itself when you change one letter of the title, and doesn't blink when you delete every word of the body, is a banner that reads the headline and skims the rest."
---
Last month I broke the tool that *names* my cover art and caught it giving two posts one face. This month I came back for the tool that *paints* it. The generator's own header file makes a bold claim — the art is "COMPUTED from your article" — and I do not believe claims with the word COMPUTED in capital letters. Capitalizing a verb is what you do when you want it believed instead of checked. So I checked.

The question a QA report has to answer is narrow and testable: when the tool says it computes the banner from *your article*, how much of your article does it actually read? I ran the real generator (`node scripts/preview/generate.mjs`, no keys, no network — it has none) enough times to find out. Every number below is a number the tool printed.

## The one line that decides everything

The seed for the entire picture is set in a single expression in the generative core:

```javascript
const seed = fnv1a(slug || title);
```

`slug` is the title, lowercased, non-alphanumerics turned to dashes, cut to fifty characters. That hash seeds a `mulberry32` generator, and from that one generator the tool draws *everything* geometric: which of three lattices, how dense, how many probes, how much drift, the palette by section, and the position of every node in the field. The body of your post is not in that expression. It is not in that function. It enters the picture exactly once, later, as a "mood nudge":

```javascript
const corpus = `${title} ${tags.join(' ')} ${body.slice(0, 1200)}`;
const urgent = (corpus.match(URGENT) || []).length;
const steady = (corpus.match(STEADY) || []).length;
const tilt = clamp((urgent - steady) / 8, -1, 1);
decay = clamp(decay + tilt * 0.12, 0.16, 0.44);
```

That's the whole contribution of your prose: it counts a couple dozen scare-words and calm-words in the first **1,200 characters**, nets them, and nudges one scalar — `decay` — by at most ±0.12. One dial out of ten, moved a little, read from the first paragraph. Everything else is the headline. Four scenarios fall out of reading it. I ran all four.

## The gauntlet

| # | What I changed | Seed | `decay` | tone | Result |
|---|---|---|---|---|---|
| 1 | Same title, body deleted vs. a paragraph of unrelated words | unchanged | unchanged | unchanged | ❌ byte-identical banner |
| 2 | Same title, 12 disaster words in the first 1,200 chars | unchanged | 0.302 | urgent | ✅ the body registered |
| 3 | Same title, those same 12 disaster words pushed *past* char 1,200 | unchanged | 0.182 | even | ❌ invisible |
| 4 | One letter added to the title | **new** | new | new | ✅ a completely different picture |

Two passes, two failures, and the two failures are the whole post.

## Row 1: I deleted the article and nothing happened

I wrote two files with the identical title — *The deploy queue backed up on a quiet afternoon* — and gave one an empty body and the other a paragraph about gardens, rivers, the printing press, bread, and the arctic tern, chosen so not one word overlapped. Then I dumped the computed scene for each and diffed them:

```console
$ node scripts/preview/generate.mjs --scene -f a1.md   # empty body
  "params": { "seed": 4235578401, ..., "decay": 0.23020472967065872, "tone": "even" }
$ node scripts/preview/generate.mjs --scene -f a2.md   # full paragraph, zero shared words
  "params": { "seed": 4235578401, ..., "decay": 0.23020472967065872, "tone": "even" }

$ diff <(scene a1.md) <(scene a2.md)   # 84,127-byte scenes
$                                       # (no output — identical)
```

Same seed, same decay, same tone. So I rendered the actual `.svg` for each and checked the bytes on disk:

```console
$ md5sum out1/*.svg out2/*.svg
185cd633e09ccd6c7ae4267c37180907  out1/the-deploy-queue-backed-up-on-a-quiet-afternoon.svg
185cd633e09ccd6c7ae4267c37180907  out2/the-deploy-queue-backed-up-on-a-quiet-afternoon.svg
```

Two posts sharing nothing but a headline, and 29,435 bytes of cover art came back with the same MD5. The failure this names: **a writer who substantially rewrites a post, re-runs the generator, and expects the cover to reflect the new piece gets the old picture back — no warning, no diff, no tell.** The body could be a shopping list. The banner can't see it.

## Row 3: the mood detector stops reading at 1,200 characters

Row 1's posts had no mood words, so of course they matched. The interesting question is whether the body *ever* matters — and it does, but only for a little while. I took twelve genuine disaster words (`fail crash broken bug leak outage panic deadlock corrupt regress stale flaky`) and put them in the first 1,200 characters of one file, and the exact same twelve words *after* character 1,200 in another:

```console
$ scene before.md | grep -E 'decay|tone'   # disasters up front
  "decay": 0.3021533533465117, "tone": "urgent"
$ scene after.md  | grep -E 'decay|tone'   # same disasters, pushed past 1200
  "decay": 0.18215335334651173, "tone": "even"

$ diff <(scene after.md) <(scene calm.md)  # calm.md has NO disaster words at all
$                                           # identical
```

A post that opens calm and then describes a five-alarm outage in its second half is, to this tool, a calm post. `body.slice(0, 1200)` is a horizon, and everything past it is decoration the painter never looks at. The failure it names is small but real: the one editorial signal the art claims to carry — is this a war story or a steady-state guide? — is decided by your opening paragraph and nothing else. Bury the lede and the cover buries it too.

## Row 4: one letter is a new universe

For contrast, here's how loudly the *title* speaks. Two posts, identical bodies, headlines differing by a single letter — *...took down checkout* versus *...took down checkouts*:

```console
$ scene checkout.md  | grep -E 'seed|probes|density'
  "seed": 829466659, "probes": 4, "density": 17
$ scene checkouts.md | grep -E 'seed|probes|density'
  "seed": 609809904, "probes": 3, "density": 23
```

Different seed, one fewer probe, six more grid columns, and every node in a new place — the summed x-coordinate of the whole field moved from 169,692 to 317,773. Add one `s` to your headline and you get a picture with no atoms in common with the old one. Delete every word of your body and you get the same picture down to the byte. That asymmetry *is* the finding.

## How much of the real site is painted blind

A lab result is a parlor trick until you point it at production. So I ran the derivation for all 243 posts on the site twice — once with the real body, once with the body blanked to an empty string — and counted how many came out identical:

```console
$ node audit.mjs
posts with a banner: 243
identical rendered scene with body deleted: 55 (23%)
```

**Fifty-five posts — 23% of the site — would render a byte-identical cover with their entire body deleted.** Those are the ones whose first 1,200 characters net to zero mood, so the one dial the body controls never moves. The headliner among them is *The Plugin That Isn't a Plugin*, which carries **11,272 characters** of body that contribute exactly nothing to its cover art. The other 77% aren't safe either — their body moves one clamped scalar, `decay`, across at most ±0.12 of its 0.16–0.44 range, and touches no other thing in the frame.

## The pass I have to give it

Here is where I eat my hat, because the body-blindness is not a bug — it's the load-bearing wall. The whole generator exists because 200-odd posts once shared four stock images, and the fix was to make the picture a pure function of the article so no two could collide and no network call could fail. Purity means determinism: same input, same output, forever, offline. Seeding from the slug is exactly what guarantees a post can never wake up wearing another post's face — the thing I caught the *namer* doing last month. The painter refuses to do it by construction. Grudging respect: the tool is honest about being a fingerprint of your headline. It's the *marketing* that isn't.

## Verdict, on the survives-a-Tuesday scale

- **A normal Tuesday:** survives, easily. You write a post, the title is distinct, you get a unique, legible, reproducible banner nobody else has. This is the tool doing its actual job well.
- **A bad Tuesday:** survives. You revise a typo, re-run the generator, and the cover is stable instead of randomly churning — which is what you want from a deterministic renderer.
- **The Tuesday you gut-rewrite a post and expect a new face:** fails quietly. The cover is bolted to the fifty-character headline and skims your opening paragraph for a mood; the rest of your article is not invited.

The fix isn't code and it isn't mine to ship — this is generator tooling, not content, and the determinism is a feature I'd fight to keep. The cheapest honest fix is one word of documentation: the skill's promise that the art is "computed from your article" should read *computed from your headline, tinted by its opening mood.* That sentence survives every Tuesday I just threw at it. The current one doesn't. I've left the specifics for whoever owns `scripts/preview/` in this PR rather than reaching over to edit the claim myself.

A painter gets one honest job: paint what's in front of it. Mine paints the headline beautifully, glances at the first paragraph, and signs its name to the whole article. I deleted the article to be sure. The signature didn't change.
