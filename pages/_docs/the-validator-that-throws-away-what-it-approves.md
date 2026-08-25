---
layout: default
title: "The Validator That Throws Away the Drawings It Approves"
description: "A model draws the cover art here; a whitelist re-draws every submission from scratch before it ships. I spent a Tuesday trying to smuggle a script past it."
preview: /images/previews/the-validator-that-throws-away-the-drawings-it-app.svg
permalink: /docs/the-validator-that-throws-away-what-it-approves/
date: 2026-08-25
collection: docs
author: edge
excerpt: "The illustration layer lets a language model draw one thing per banner and then rebuilds it byte for byte from a whitelist. I fed it fourteen drawings nobody sane would submit. Here is the table."
sidebar:
  nav: tree
---
# The Validator That Throws Away the Drawings It Approves

The first thing you learn testing this thing is that "your drawing passed" and "we used your drawing" are two different sentences, and the gap between them is the whole point.

Here is the setup. Every article on lifehacker.dev ships a banner. The banner is computed — shapes, palette, animation, the safe band the headline sits in — by deterministic code that never phones anyone. But the code cannot know what your article is *about*. So there is exactly one job a language model is allowed to do in the whole pipeline: draw the subject. A little vector illustration inside a 1000×1000 box — a git branch, a padlock, a broken build — that gets composited into the art half of the banner. Cass already threat-modeled the version this replaced, [the whole-SVG rung that asked a model for a complete document](/docs/the-cover-art-is-a-program/) and got a file that could hold a `<script>` tag. This is the thing that took its place: `scripts/preview/lib/motif.mjs`, the validator that only lets the model own subject matter and nothing else.

Cass's job was to imagine the worst drawing. Mine is to *submit* it. Fourteen times, on purpose, with a straight face. Every string below is a real string the validator printed when I fed it the bad input — I imported `parseFragment` and `validateTree` straight out of `motif.mjs` and ran them. The violations are written as instructions because they aren't for me; they get pasted straight back to the model as its next turn. So when I quote one, I'm quoting the exact sentence the machine tells the artist to fix.

## The gauntlet

| # | The drawing I submitted | Verdict |
|---|---|---|
| 1 | A `<script>` tag next to a circle | ❌ rejected |
| 2 | An `<image href="http://evil/x.png">` | ❌ rejected |
| 3 | A circle painted `fill="#ff0000"` | ❌ rejected |
| 4 | A full-bleed `<rect>` covering the frame | ❌ rejected |
| 5 | Six dots making a 3%-wide emblem | ❌ rejected |
| 6 | A path running from −400 to 1600 | ❌ rejected |
| 7 | A `<circle>` with an `onload=` handler | ❌ rejected |
| 8 | `transform="url(#x)"` | ❌ rejected |
| 9 | A `<use href="#x">` reference | ❌ rejected |
| 10 | A `<![CDATA[…]]>` payload | ❌ threw |
| 11 | Unbalanced `<g><circle></g>` | ❌ threw |
| 12 | A real 8-shape, 3-colour illustration | ✅ passed |
| 13 | The same, with hairline strokes | ✅ passed (clamped) |
| 14 | The same, hashed two ways | ✅ stable |

Zero got through that shouldn't have. That never happens. I want to be clear that it made me suspicious, so I went scenario by scenario looking for the one that lied.

## The ones that get refused

The `<script>` tag (row 1) doesn't get stripped, sanitized, or escaped. The element simply isn't in the vocabulary, so it comes back:

> `<script> is not allowed. Draw only with g, path, circle, ellipse, rect, line, polyline, polygon (gradients via defs/linearGradient/radialGradient/stop). No text, no images, no scripts, no filters — the headline is typeset separately.`

Same treatment for `<image>` (row 2), `<use>` (row 9), and — this is the tell of a real whitelist — anything else you can think of. There is no list of banned tags to keep up to date. `<foreignObject>`, `<animate>`, `<text>`, `<filter>`: none of them are named anywhere in the code, and none of them need to be, because the only elements that survive are the nine drawing primitives plus gradients. A blacklist is a promise to remember every bad thing forever. This is the opposite, and QA trusts the opposite.

Row 3, the raw hex, is the same principle aimed at colour. You cannot paint `#ff0000`:

> `fill="#ff0000" on <circle> is not a palette token. Paint only with ink, cool, warm, accent, grid, muted, bg0, bg1 (e.g. fill="cool"), "none", or url(#id) for a gradient you defined. Raw hex, rgb(), and named CSS colours are refused so the art stays on-palette for every section.`

The failure that prevents: a hack motif and a wire motif drawn a month apart looking like they came off two different websites. You draw with tokens; the section decides what colour a token is. Nice.

Row 7 is the one I was proud of. Put the payload on an element that *is* allowed — a plain `<circle>` — and hang an `onload` handler off it:

> `attribute onload="..." is not allowed on <circle>. Allowed: transform, opacity, fill, stroke, stroke-width, stroke-opacity, fill-opacity, fill-rule, stroke-linecap, stroke-linejoin, stroke-dasharray, stroke-miterlimit, cx, cy, r.`

Whitelisting elements is common. Whitelisting *attributes per element*, so a circle only gets the fifteen it's allowed and everything else is a named error, is the part people skip because it's tedious. It's the part that catches the clever attack. Row 8, `transform="url(#x)"`, dies the same way — a transform has to match a plain translate/scale/rotate/matrix/skew list or it's refused, so you can't hide a reference inside one.

Then the geometry, which is where the validator stops being a security guard and starts being an art director with a grudge. Row 5 — a tidy little emblem, six dots in the middle of the frame — passes every safety check and still gets thrown out:

> `the drawing fills only 3% x 1% of the frame. Compose it to fill at least 42% of both axes — a small emblem in the middle of a big frame disappears in a 300px card.`

Row 6, the path that runs off the edge, gets its own math read back to it: *"the drawing runs from (−400, −400) to (1600, 1600). Everything must live inside 0..1000 on both axes."* Row 4, the full-bleed background rectangle, gets told to *"leave the background alone — the banner already has one."* None of these are exploits. They're just bad drawings, and the thing that guards the door also refuses to hang a bad drawing. I respect that. It's more than most linters do.

Rows 10 and 11 don't return a verdict at all — they *throw*, before validation even starts. A `<![CDATA[…]]>` block and an unbalanced tag are malformed structure, and the parser refuses to build a tree out of garbage:

> `CDATA, DOCTYPE, and processing instructions are not allowed`
> `unbalanced tag </g>`

Fail closed. The one design choice I check every parser for, and this one has it.

## The twist: it doesn't sanitize, it re-draws

Here's what I found when I went hunting for the lie in row 12 — the drawing that passed. I serialized it back out and diffed it against what I put in. It's not the same file.

The validator never copies the model's markup through. It parses the input into a tree, checks it node by node, and then *re-emits every byte itself* from the whitelist. Your `fill="ink"` comes back as `fill="var(--ink)"`. Your attribute order is normalized. Anything not on the allowed list is gone — not blocked, *absent*, because the serializer only knows how to write the attributes it recognizes. I proved this to myself with the dirty circle from row 7: even holding the rejected tree and serializing it anyway, the output contained no `onload`. There is no code path that writes an attribute the whitelist doesn't name.

That reframes the whole thing. "Passing validation" isn't a permission slip that lets your drawing onto the page. Your drawing never gets onto the page. A *reconstruction* of it does — same shapes, same coordinates, rebuilt in a room the model isn't allowed into. The validator throws away the drawings it approves and keeps a clean-room copy. It just happens to look identical, which is why nobody notices.

## The one mercy: hairlines get fixed, not failed

Row 13 is where I expected pedantry and got judgment instead. I submitted the valid illustration but drew its strokes at `stroke-width="0.5"` and `stroke-width="1"` — hairlines that would vanish when the 1000-unit motif is scaled down into a 300px card. A strict validator rejects those and makes the model redo the whole drawing over a half-pixel line.

This one doesn't reject them. It clamps them up on the way out:

```
input widths:  0.5, 1, 6
output widths:  4,  4, 6
```

The floor is 4 units; anything positive below it is quietly raised, anything at or above it is left alone, and `stroke-width="0"` — which means "no stroke" — is honoured, not clamped. The comment in the code argues its own case: deterministic code owns what must never be wrong, *and that cuts both ways* — if a detail stroke one unit under the floor can just be fixed, fix it, don't burn a whole model round-trip on it. I went in expecting a nitpicker and found one that knows when a nitpick isn't worth the reader's time. Grudging respect. It hurts to type.

Row 14 was my last suspicion: the drawing's identity is a hash, and if the hash changed when you pretty-printed the file versus wrote it on one line, then formatting could silently mint a "new" drawing and trigger re-renders forever. It doesn't. The digest is taken from the unindented serialization on both the way out and the way back in, so the pretty-printed file a human reviews and the flat form the machine hashes resolve to the same identity. Format independence, confirmed by running it both ways and getting the same eight hex digits. Boring. Correct. My favourite combination.

## The failure I could not manufacture

Testing is supposed to end with a bug. I owe you one, so here is the honest edge of what I tested: I exercised the *validator*, not the full illustrator. I fed drawings straight into `parseFragment` and `validateTree`; I did not spend a model call watching `illustrate.mjs` argue with Claude across retries. Everything above is the gate doing its job on inputs I handed it directly — which is exactly the layer a smuggled `<script>` has to cross, so it's the layer worth breaking. I did not break it.

The closest thing to a finding is architectural, and Cass would want it said out loud: this whole guarantee rests on the file being loaded as an *image*, not inlined into the DOM. The validator makes the byte stream clean; the page still has to reference it as `og:image` / `<img src>` / `background-image` for "clean" to mean "inert." That's the same load-bearing line [the cover-art post](/docs/the-cover-art-is-a-program/) already documented, and it lives one layer up from here. Not a bug in the validator. Just the reminder that a strong door only helps if the wall around it is real.

**Verdict on the survives-a-Tuesday scale:** survives a Tuesday where the intern has sudo, a poisoned article body, and a model in a bad mood. It survives them because it doesn't trust the model's output at all — it takes the coordinates and throws the file away. Fourteen drawings in, zero got through that shouldn't have, and the two that passed still didn't make it to disk. That's not a validator being careful. That's a validator that assumes everything it's handed is a forgery and repaints it before hanging it on the wall.

Certified n00b, cleared for production. I'll be back with more filenames it hasn't met.
