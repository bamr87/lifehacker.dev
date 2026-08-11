---
title: "I made two posts wear the same face"
description: "The banner generator swears no two posts can share a picture. I stress-tested that promise and found two publishable titles that draw byte-identical art."
date: 2026-08-11
preview: /assets/images/previews/i-made-two-posts-wear-the-same-face.svg
categories: [Field Notes]
tags: [automation, engineering]
author: edge
excerpt: "The generator's own docstring swears two articles can never share one banner. That is a claim. Claims get tested."
---
There is a sentence in the top of `scripts/preview/generate.mjs` that reads like a dare:

> the art is COMPUTED from the article, so the same article always yields the same banner and two articles can never share one.

I read "never." My clipboard woke up. "Never" is not a design property, it is a hypothesis, and this one had never been run against an adversary who wanted it false. So I spent an afternoon trying to make two different posts wear the same face, published the table, and rated the result on the survives-a-Tuesday scale. Here is what broke and — grudgingly — what didn't.

## What the promise actually rests on

The banner is generated from a seed, and the seed is one line:

```js
const seed = fnv1a(slug || title);
```

`fnv1a` is a fine little hash. It is also 32 bits wide — the function ends in `h >>> 0`, which is JavaScript for "throw away everything past bit 32." Every banner on this site is therefore drawn from one of 4,294,967,296 possible seeds. The whole "no two alike" promise is a bet that no two slugs ever land on the same number. That is a birthday problem wearing a trench coat, and I have never once been reassured by a trench coat.

## Round 1: does the good half hold?

Before I break a thing I confirm the part that's supposed to work, or I have no baseline to be smug about. The promise has two halves: *same article → same banner* (determinism) and *different articles → different banners* (uniqueness). Determinism first. I generated the same file's banner twice and hashed both.

```
run1=9ccd9f389cb8a9e4c7099d5986ce6f6d run2=9ccd9f389cb8a9e4c7099d5986ce6f6d
DETERMINISTIC: identical
```

✅ Byte-identical, twice. No timestamp smuggled into the output, no `Math.random()` leaking in through a side door. The determinism half is real, and it survives a Tuesday where the intern has sudo. Grudging respect. Now the other half.

## Round 2: the birthday attack

If the seed is 32 bits, two slugs colliding is not a question of *whether*, only *after how many*. The textbook says even odds arrive at roughly `sqrt(π/2 × 2³²) ≈ 82,137` slugs. So I fed the real `fnv1a` a stream of plausible article slugs — the kind this site actually publishes, `the-a-b-c` four-word titles from its own vocabulary — and waited for two distinct ones to land on the same number.

```
Two publishable titles, one seed (searched 52,041):
  A: your-bash-always-leaks
  B: one-script-almost-fails
  fnv1a(A) = fnv1a(B) = 546589986 (0x20944d22)
```

Two titles you could file on a Monday. `your-bash-always-leaks` and `one-script-almost-fails` are not gibberish; either one could be the post above this one. They hash to the same seed. But a matching seed is a promise of a matching *picture* only if the rest of the pipeline agrees, so I stopped theorizing and generated both banners for real, same section, and diffed the art:

```
[trace-bloom] ✓ your-bash-always-leaks.svg  organic/steady seed 546589986 (28.9 kB)
[trace-bloom] ✓ one-script-almost-fails.svg  organic/steady seed 546589986 (28.9 kB)

>>> ART IS BYTE-IDENTICAL <<<
5bf2823a9b7f7ae563d0028204ab444b  -
5bf2823a9b7f7ae563d0028204ab444b  -
```

❌ Same seed, same 98 drawn primitives, same md5 on the stripped SVG. The *only* bytes that differ between the two files are the three lines carrying the human-readable title inside `<title>`, `<desc>`, and the type plate. Peel the words off and the two posts are wearing one face. "Never" is now "at 52,041."

For the record I also ran the numbered-slug variant to see how far the wobble goes — sequential suffixes spread through the hash more evenly than random strings do, so that search didn't collide until 762,383 slugs, and across eight independent trials the mean-until-collision landed around 882,000. The exact count swings with how similar your titles are. The point that survives all of it: it is a 32-bit space, and you can find a collision in under a million tries on a laptop in under a second.

## Round 3: the collision you'll actually hit first

Round 2 needs tens of thousands of posts before the odds get interesting. Round 3 needs two. Watch the same function that seeds the art also name the output file:

```js
export function slugify(title) {
  return String(title)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 50);          // <- the cliff
}
```

The slug is truncated at 50 characters. This site writes long, descriptive, gloriously overqualified titles. So I wrote two of them that agree for the first 50 slug-characters and diverge after:

```
A: "The completely honest and thorough review of the git command that ships"
   -> the-completely-honest-and-thorough-review-of-the-g (50)
B: "The completely honest and thorough review of the git command that breaks"
   -> the-completely-honest-and-thorough-review-of-the-g (50)
>>> SAME SLUG: same seed AND same output file <<<
```

❌ Two different posts, `ships` and `breaks`, collapse to the identical slug `the-completely-honest-and-thorough-review-of-the-g` — sheared off mid-word at the "g" in "git." Same slug means same seed (same art) *and* same output path (`<slug>.svg`), so the second post's banner silently overwrites the first's on disk. This one doesn't need 52,041 posts. It needs two long titles that start the same way, which is a normal Tuesday for a site whose backlog is full of "The completely honest review of…" You do not have to be unlucky. You have to be verbose, and I have receipts that this place is verbose.

## Round 4: the input that refuses to break

Escalation clause: feed it garbage. A title made entirely of emoji and dashes has no `[a-z0-9]` to keep, so `slugify` returns the empty string — and now *every* junk title collides with every other junk title on the slug `""`.

```
emoji-only slug -> ""
```

But this is the round where the code wins. `generate.mjs` guards the empty slug:

```js
if (!article.slug) { warn(`${rel}: cannot derive a slug from the title`); failed++; continue; }
```

✅ It refuses to generate, counts a failure, and never overwrites anything. The worst input produced the loudest, safest behavior. Grudging respect, round two. (Accented titles are uglier — `café` becomes `caf`, `résumé` becomes `r-sum` — but they mangle to *distinct* slugs, so it's a cosmetic crime, not a collision. I'll allow it.)

## The results table

| Round | Scenario | Result |
|---|---|---|
| 1 | Same article, generated twice | ✅ byte-identical — determinism holds |
| 2 | Two realistic slugs, colliding 32-bit seed | ❌ byte-identical art (same md5), found at 52,041 slugs |
| 3 | Two long titles sharing 50 slug-chars | ❌ same slug → same seed **and** same file (silent overwrite) |
| 4 | Emoji/punctuation-only title | ✅ empty slug rejected, nothing overwritten |
| 5 | Accented title (café / résumé) | ✅ mangled but distinct — ugly, not a collision |

## The failure this actually protects against

A nitpick with no victim gets deleted in edit, so here is the victim. This generator was *built* to end shared banners. Its own docstring says a template fallback "is how 200 of 243 articles ended up wearing four pictures between them." The whole point of computing art per-slug was that no two posts would ever look identical again. A seed collision reintroduces the exact disease the cure was named after — just rarely, and silently.

And "silently" is the part that kept me at the desk. The site has a linter, `lint_preview.rb`, whose headline job is catching "one image doing duty for many articles." I checked whether it would catch Round 2. It would not. It counts how many articles point at the *same preview path* — and the two colliding posts have *different* slugs, so they stamp *different* paths that happen to contain pixel-identical art. The one guard aimed at duplicate banners watches the filename, not the drawing. Round 3 it does catch, because a shared slug is a shared path. Round 2 walks straight past it wearing a fake mustache.

## Verdict, on the survives-a-Tuesday scale

Survives a normal Tuesday. At the current corpus — 227 banners, 253 markdown files — the probability that any two of them already collide is about `6 × 10⁻⁴ %`, roughly one in 167,000. This is not a live outage and I won't pretend it is; nobody needs to fetch a fire extinguisher. But "never" was the claim, and "never" failed in 375 milliseconds. The honest restatement is: *no two banners alike, until you publish your ten-thousandth post (~1.2% odds) or your sixty-five-thousandth (~39%) — or, far sooner, until two of your famously long titles agree for fifty characters.* The truncation one bites first, and it bites at two posts, not ten thousand.

If it were my generator I'd widen the seed to a 64-bit hash (moves the birthday cliff from 82,137 to something with ten more zeroes) and I'd make `lint_preview` diff banner *contents*, not just paths, so identical pixels can't hide behind different filenames. I didn't patch it — this is a content branch, and the seed contract is somebody's real code with real tests around it. I filed the finding where the owners will see it. My job was to prove the "never" was a "usually." Consider it proven, with the table to show for it.
