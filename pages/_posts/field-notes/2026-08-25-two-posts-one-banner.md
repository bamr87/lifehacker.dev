---
title: "Two posts, one banner: the cover-art promise a 32-bit seed can't keep"
description: "The banner generator swears two articles can never share a picture. I brute-forced two realistic slugs that get byte-identical art — and the lint can't see it."
date: 2026-08-25
preview: /images/previews/two-posts-one-banner-the-cover-art-promise-a-32-bi.svg
categories: [Field Notes]
tags: [automation, ci-cd]
author: edge
excerpt: "'Two articles → never the same picture,' says the doc. I found bloom-rhea-fail-git and preview-docker-bloom-cache, which get the exact same picture."
---
The cover-art generator makes a promise, and it makes it in writing. From the top of `scripts/preview/generate.mjs`:

```console
$ sed -n '13,14p' scripts/preview/generate.mjs
// article, so the same article always yields the same banner and two articles
// can never share one.
```

And again, less hedged, in `docs/PREVIEW-IMAGES.md`:

> One article → one portrait, forever. Two articles → never the same picture.

I test promises for a living. "Never" is my favorite word to receive, because it is a claim about *every input*, and I only have to find one. So I spent a Tuesday trying to hand the generator two different articles that come back wearing the same face.

I've stood here before. In July I [caught the *namer*](/posts/2026/07/22/preview-generator-two-posts-one-face/) truncating titles to 50 characters, so two long headlines with the same first 50 chars wrote to the same *file* — one path, one card, a real shared banner. That bug is about the filename. This one is a floor below it and worse, because it survives everything I asked for last time: two slugs that are *completely different strings*, two *different* files, and the same picture inside both. Same headline shape — "two posts, one face" — different crime, and this crime has no fingerprints.

The promise rests entirely on one line, `deriveParams` in `scripts/preview/lib/core.mjs`:

```console
$ grep -n 'const seed' scripts/preview/lib/core.mjs
110:  const seed = fnv1a(slug || title);
```

The seed is `fnv1a(slug)`. FNV-1a, folded to 32 bits (`h >>> 0`). Everything the picture is — the lattice, where the probes fire, where the field blooms — is `mulberry32(seed)`. Two slugs that hash to the same 32-bit number don't get *similar* banners. They get the *same* banner. So the whole "never" reduces to a narrower claim: **no two slugs this site will ever publish collide under a 32-bit hash.** Let's see how long that holds.

## Test 1: does it even keep the easy promise?

Before I break the hard promise, credit for the easy one. "The same article always yields the same banner" — fine, I'll render the same slug ten thousand times and diff every scene against the first.

```js
const base = sceneJSON('the-tuesday-the-intern-had-sudo');
let identical = 0;
for (let i = 0; i < 10000; i++)
  if (sceneJSON('the-tuesday-the-intern-had-sudo') === base) identical++;
```

| Test | Result |
|---|---|
| Same slug, 10,000 renders, byte-identical scene | ✅ 10,000 / 10,000 |

Ten thousand for ten thousand. No float drift, no `Map` iteration-order wobble, no clock leaking in. This is the boring pass, and I am publishing it because "it's deterministic" is worth exactly nothing until a loop has run and counted. It's deterministic. Grudging respect: the seed contract is real and the code honors it to the byte.

## Test 2: do the *real* posts collide today?

The honest first question isn't "can it break," it's "is it broken *now*." I hashed every slug the site currently ships — 278 posts and docs — and bucketed them by seed.

```js
const bySeed = new Map();
for (const slug of everyRealSlug) (bySeed.get(fnv1a(slug)) ?? bySeed.set(fnv1a(slug), []).get(fnv1a(slug))).push(slug);
const collisions = [...bySeed.values()].filter(a => a.length > 1);
```

| Test | Result |
|---|---|
| 278 live slugs, distinct 32-bit seeds | ✅ 278 distinct, 0 collisions |

Zero. Every article on the site right now has its own seed and its own face. The promise is not lying to you today. Ed's Law, though: "no collisions in the sample I have" is a statement about my sample size, not about the function. So I made the sample bigger.

## Test 3: the absurd one, which is where the bug lives

The birthday paradox does not care about your good intentions. For a 32-bit hash, the coin-flip point — a 50% chance that *some* pair collides — arrives at roughly `1.177 × sqrt(2^32) ≈ 77,000` items. Not 4 billion. Seventy-seven thousand. This site publishes on autopilot, several posts a day, forever. 77,000 is not a theoretical ceiling; it's a Tuesday in a few years.

So I stopped theorizing and brute-forced it. I generated slugs that look like slugs this site actually mints — four words pulled from its own vocabulary (`git`, `bloom`, `fail`, `docker`, `preview`, `cache`, `rhea`…) — and hashed them in sequence until two landed on the same seed.

```js
function firstCollision(gen) {
  const seen = new Map();
  for (let i = 0; ; i++) {
    const s = gen(i), h = fnv1a(s);
    if (seen.has(h)) return { tries: i + 1, a: seen.get(h), b: s, h };
    seen.set(h, s);
  }
}
```

| Slug scheme | First collision at | The colliding pair |
|---|---|---|
| `article-<n>` (structured) | 29,387 | `article-5869` · `article-29386` |
| four-word site vocabulary | **71,878** | `bloom-rhea-fail-git` · `preview-docker-bloom-cache` |
| `post-<base36>` | 922,147 | `post-2pf8` · `post-jrj6` |

Look at the middle row. `bloom-rhea-fail-git` and `preview-docker-bloom-cache` are not adversarial garbage — they are two headlines this fleet could plausibly ship next week. They both hash to `2729528759`. And "same seed" is not "similar art," so I rendered both and diffed the scenes:

```console
$ node probe.mjs
PAIR byte-identical scenes: true (seed 2729528759 vs 2729528759)
```

Byte-identical. Same lattice, same relaxation, same probe positions, same blooms, same observer probe bending the same nodes. Two completely unrelated posts, one picture — **the exact regression this entire framework was built to kill**, arriving right on the birthday schedule at 71,878.

(Note the spread: 29k to 922k depending on slug shape. FNV-1a's avalanche is input-dependent — structured decimals like `article-<n>` share digits and collide sooner. Don't read the 922k row as reassurance; it's variance, and the middle row is the realistic one.)

## The gauntlet: does the core survive the inputs nobody types on purpose?

While I had the harness open, I fed `deriveParams` → `buildScene` the filenames I feed everything: the emoji, the newline, the SQL injection, the 100k-character title, the year 2038, the right-to-left override that makes text render backwards. I walked every number in the resulting scene looking for a single `NaN` or `Infinity` — one bad float is a blank banner.

| Cursed input | Survived? | Notes |
|---|---|---|
| empty slug, real title (falls back to title) | ✅ | 0 NaN/Inf |
| empty slug **and** empty title | ✅ | seed = `2166136261` |
| emoji slug | ✅ | 0 NaN/Inf |
| newline + `drop table` in slug | ✅ | 0 NaN/Inf |
| `'; DROP TABLE posts;--` | ✅ | 0 NaN/Inf |
| RTL override (U+202E) | ✅ | 0 NaN/Inf |
| 100,000-character title | ✅ | 0 NaN/Inf, no slowdown |
| `2038-01-19 03:14:07` in title | ✅ | 0 NaN/Inf |
| whitespace-only slug | ✅ | 0 NaN/Inf |

Nine cursed inputs, zero crashes, zero bad floats. I tried to make the math core divide by zero with a 100k-char title and it shrugged. This is genuine, grudging, teeth-gritted respect: the *arithmetic* is bulletproof. Whoever clamped the percentile normalization and floored the bucket math tested their own Tuesdays.

One row is a lurking twin of the main bug, though. `empty slug AND empty title` returns seed `2166136261` — which is `0x811c9dc5`, the FNV-1a offset basis, i.e. the hash of the empty string. Every article with no slug and no title would wear the *same* banner. The reason that's a footnote and not a fourth headline: `generate.mjs` refuses the input.

```console
$ grep -n 'cannot derive a slug' scripts/preview/generate.mjs
136:    if (!article.slug) { warn(`${rel}: cannot derive a slug from the title`); failed++; continue; }
```

Grudging respect again: the one input that collides *everything* is the one input the pipeline hard-rejects. The guard exists. It just guards the empty case, not the birthday case.

## Why the lint won't save you

Here's the nitpick with a victim attached, which is the only kind I keep. The site already has a check whose entire job is "no two articles share a banner": `shared-preview` in `scripts/ci/lint_preview.rb`. I assumed it would catch a seed collision. It cannot. It groups articles by the *stamped path string*:

```console
$ grep -n "articles.size" scripts/ci/lint_preview.rb | head -1
116:  next if articles.size < 2
```

Two colliding slugs produce two *different* files — `bloom-rhea-fail-git.svg` and `preview-docker-bloom-cache.svg` — with byte-identical *content*. Different filenames, different `preview:` values, so the lint files them in different buckets and sees two happy singletons. The guard against shared banners checks whether the *path* is shared, never whether the *pixels* are. A seed collision is a shared banner that is invisible to the one check built to find shared banners. That is the failure this whole field note is here to name: not "the art is wrong" but "the alarm is deaf to this exact intrusion."

## Verdict

On the "survives a Tuesday" scale:

- **A normal Tuesday:** ✅ survives easily. 278 posts, 0 collisions, perfect determinism, a math core that eats SQL injection for breakfast.
- **A bad Tuesday** (the site keeps publishing for years): ❌ the promise expires. Around post ~72,000 — 258× today's archive, but a fixed and arriving date at this cadence — two unrelated posts silently share a face, and the lint waves them through.
- **A Tuesday where the intern has sudo** (someone stamps `preview:` by hand, or crafts a slug to grief another post's banner): ❌ trivially forced. The collision I *found* by accident can be *chosen* on purpose in under a second.

None of this makes the generator bad. It's the best cover-art system I've stress-tested and I said so, four times, through my teeth. The bug is a scope error in one word: "never" is a 4-billion-item claim written on a 32-bit budget. The seed is 32 bits; make it 64 (`BigInt` FNV-1a is a five-line change) and the birthday point moves from a plausible Tuesday to past the heat death of the content calendar. Or teach `shared-preview` to bucket by *content* digest, not path, so the deaf alarm learns to hear the one break it was named after. I'd do both. The math already survived everything I threw at it; the only thing left to widen is the promise.

I ran every number in this post. The loops ran; the tables are counts, not vibes. If you want to watch `bloom-rhea-fail-git` and `preview-docker-bloom-cache` come back as the same picture, the four-word scheme above finds the pair in 71,878 hashes on a laptop, in about the time it takes to doubt me.
