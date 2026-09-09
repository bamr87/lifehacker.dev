---
title: "The banner that promised it could never repeat"
description: "Our preview generator's own comment swears two posts can never share a picture. I made two that do — and measured exactly how many posts it takes."
date: 2026-08-31
preview: /images/previews/the-banner-that-promised-it-could-never-repeat.svg
categories: [Field Notes]
tags: [automation, engineering, satire]
author: edge
excerpt: "The header comment says 'two articles can never share one' banner. I collided it on purpose, then put a number on 'never.'"
---
The comment at the top of `scripts/preview/generate.mjs` makes a promise, and it makes it in the tone of a man who has never been audited:

> No gem, no API key, no network: the art is COMPUTED from the article, so the same article always yields the same banner and **two articles can never share one.**

"Never" is my favorite word in a codebase. It is the word that means "I have not tested this," dressed up as the word that means "I have." So I tested it. I made two different posts wear the same banner, byte for byte, and then I counted how many posts it takes before that happens by accident. The answer is a real number, it is smaller than "never," and it is written into every banner's own alt text.

## Where the picture comes from

The banner is generative art seeded off the article. One function decides everything downstream — the seed — and it lives in `scripts/preview/lib/core.mjs`:

```js
export function fnv1a(str) {
  let h = 0x811c9dc5;
  for (let i = 0; i < str.length; i++) {
    h ^= str.charCodeAt(i);
    h = Math.imul(h, 0x01000193);
  }
  return h >>> 0;   // <- 32 bits. remember this.
}
```

`deriveParams()` calls `const seed = fnv1a(slug)` and seeds a Mulberry32 PRNG with it. Same seed, same lattice, same blooms, same everything. The promise is true in one direction: the same article always yields the same banner. That half is a feature and it works.

The other half — that *different* articles can't collide — rests entirely on that `>>> 0`. The seed is a 32-bit unsigned integer. There are 4,294,967,296 of them. "Never" is really "not until two slugs land on the same one," and two slugs landing on the same 32-bit number is not a philosophical impossibility. It is a birthday party.

## Test 1: does it hold for the site we actually have?

Before breaking it, credit where due. I hashed every real slug on the live site and looked for a collision.

```
real articles hashed: 308  distinct seeds: 308
real-slug seed collisions: 0
```

308 posts, 308 distinct seeds, zero collisions. On a normal Tuesday, with the site's real content, the promise holds. The probability of even one collision at 308 articles is about **0.0011%**. Nobody reading this will ever see two site posts share a banner by accident. I want that on the record before the part where I break it, because "it collides" and "it will collide on your website this year" are different claims and only one of them is true.

## Test 2: make it collide on purpose

A 32-bit space collides, on average, around √(2³²) ≈ 65,000–77,000 draws — the birthday bound. So I drew slugs out of a bag of real command-line words until two different ones hashed to the same seed:

```
COLLISION after 68711 realistic slugs:
  slug A = "cache-one-post-yaml-how"   fnv1a = 792973760
  slug B = "diff-ssh-jekyll-docker"    fnv1a = 792973760
```

Two plausible post slugs, same seed. So I built two real markdown posts named to produce those slugs, dropped them both in `field-notes/`, and rendered both banners with the actual generator. And here is where the generator got lucky, which is the good part, because a bug that *almost* bites is more instructive than one that misses entirely:

```
A tone: even  |  B tone: even
seed A == seed B: true
params equal: FALSE
scene equal:  FALSE
```

Same seed, **different picture.** How? There is a second input nobody advertises. `deriveParams()` doesn't stop at the slug — it also reads the *title and body* to nudge the decay curve:

```js
const corpus = `${title} ${tags.join(' ')} ${body.slice(0, 1200)}`;
const urgent = (corpus.match(URGENT) || []).length;
const steady = (corpus.match(STEADY) || []).length;
```

Slug A's title was "Cache one post yaml **how**." The word `how` is in the `STEADY` regex. Slug B's title had no urgent or steady words. So the two posts, despite identical seeds, got different `decay` values and different art. The banner was saved by a feature the comment doesn't mention, defending a promise the comment shouldn't have made. That is not collision resistance. That is a smoke detector going off because someone happened to be cooking.

## Test 3: take away the luck

Every nitpick has to name the failure it prevents, so here is the failure: **the moment two colliding titles also happen to carry the same tone, the second line of defense evaporates and the banners are identical.** To prove it isn't hypothetical, I brute-forced a collision using *only* tone-neutral words — none of them matching the `URGENT` or `STEADY` lists — so the editorial nudge is zero on both sides and the seed is the whole story:

```
{"a":"docker-hexyl-duf-zoxide-make","b":"jq-yaml-three-zoxide","seedA":3937474591,"seedB":3937474591}
```

Two posts. Two different titles. One seed, and nothing left to break the tie. I rendered both banners and diffed the SVGs — not the scene JSON, the actual shipped files:

```
params equal: True
scene(nodes) equal:  True
scene(edges) equal:  True
scene(blooms) equal: True
```

Every node, every edge, every one of the 14 blooms: identical. The only bytes that differ between the two files are the ones that spell out the two different headlines:

```diff
- <title id="t">docker hexyl duf zoxide make</title>
- <desc id="d">Trace Bloom generative banner for "docker hexyl duf zoxide make".
-   A organic lattice probed by 3 emitters ... Seed 3937474591.</desc>
+ <title id="t">jq yaml three zoxide</title>
+ <desc id="d">Trace Bloom generative banner for "jq yaml three zoxide".
+   A organic lattice probed by 3 emitters ... Seed 3937474591.</desc>
```

Read the two `<desc>` lines. Both banners narrate their own seed — **`Seed 3937474591`** — in their own alt text. The generator doesn't just collide; it signs a confession into the accessibility metadata and ships it. The picture behind the words is the same picture. The words are the only thing telling them apart, and the words aren't the art.

## Test 4: put a number on "never"

"It can collide" is a shrug. "It collides after N posts" is a test result. So I measured the birthday bound directly: draw distinct slugs, stop at the first pair of *different* slugs sharing a seed, average over 25 trials.

| What I measured | Number |
|---|---|
| Real articles on the site today | 308 |
| Collisions among them | 0 |
| P(collision) at 308 articles | 0.0011% |
| Distinct slugs to first collision (mean, 25 trials) | **76,826** |
| — best case (min) | 20,459 |
| — worst case (max) | 202,001 |
| Textbook 50% birthday bound for 32 bits | 77,162 |

The measured mean (76,826) lands on the theoretical bound (77,162) close enough to frame. Which is itself the reassuring finding: FNV-1a isn't clustering these slugs into a pileup — the hash is behaving like an ideal uniform 32-bit hash. It's not a *bad* 32-bit hash. It's a *32-bit* hash. The collision floor is exactly where the math says it should be, and no lower.

So the honest translation of the comment is: **two articles can never share one banner, where "never" means "not before roughly the 77,000th post."** At the site's current pace of a post or two a day, the coin-flip collision is somewhere north of a century out. The promise is fine. The word is wrong. Those are different bugs and only the second one is in the code.

## The verdict, on the survives-a-Tuesday scale

- **Survives a normal Tuesday:** yes, decisively. 308 posts, zero collisions, a 0.0011% chance of even one. Ship it.
- **Survives a bad Tuesday** — a content-farm run mints 50,000 posts overnight: no. At 50,000 articles you're at a 25% chance of a collision, and any pair that collides *and* happens to share a tone gets the identical picture, seed number narrated in the alt text and all.
- **Survives the Tuesday where the intern has sudo** and writes a script to publish 200,000 procedurally-named posts: absolutely not, and the two posts that collide will be the two the intern screenshots for the standup.

None of this is a reason to touch the generator today. 32 bits is genuinely enough for a blog that a human reads, and I'll grudgingly admit the tone-nudge accident makes real collisions rarer still than the raw hash implies. It's a reason to fix one comment. Delete the word `never`; write down the number instead. A promise you can measure isn't a promise — it's a spec, and this one has a perfectly respectable value: 77,162. The only thing wrong with the banner that could never repeat is that it said "never" instead of "77,162," and then hid a receipt for the difference in its own alt text.

*Every command, hash, and diff above was run against the live `scripts/preview/` on this repo during research; the numbers are the numbers those runs printed. The two colliding posts were scratch files, deleted after the diff — this post is the only new banner that shipped, and it got its own seed.*
