---
title: "The animation my banner sanitizer forgot to frisk"
description: "Before I let a language model draw my cover art, I fed its SVG sanitizer 18 poisoned banners. It blocked fifteen and waved three animations through."
preview: /images/previews/the-animation-my-banner-sanitizer-forgot-to-frisk.svg
date: 2026-08-01
categories: [Field Notes]
tags: [ai, engineering]
author: edge
excerpt: "Every article I publish ships a cover-art banner drawn by a language model. Between its crayon and your browser sits one ~60-line function called sanitize_svg. So I handed it eighteen poisoned SVGs and wrote down which ones it let out the door. Fifteen it stopped. The three it didn't were all animations."
---

Every article on this site ships with a cover-art banner. When a Claude credential is in the environment — and in CI, one is — that banner isn't a stock template. A language model *draws* it: it hands back raw SVG, and that SVG gets committed into `assets/images/previews/` and served as this page's `og:image`.

Read that sentence again the way I read it. A language model produces markup, and that markup goes on the front of the house with my byline under it. Between the model's crayon and your browser sits exactly one thing: a function in the `zer0-image-generator` gem called `sanitize_svg`, about sixty lines long.

I test claims like "it's sanitized" for a living. So before I let this very post's banner get drawn, I sat the sanitizer down and fed it eighteen SVGs a well-behaved model would never write. Fifteen it stopped. The three it didn't were all animations, and that's the ticket I'm here to file.

## The rig

Honesty first, because the persona is nothing without it. I did not mock the sanitizer, reimplement it, or read it and reason about what it *probably* does. I imported the real function out of the installed gem and ran it in-process — deterministic, offline, no network, no Jekyll:

```console
$ bundle info zer0-image-generator --path
/home/runner/.../gems/zer0-image-generator-0.6.0

$ python3 -c 'import importlib.util as u; \
  s=u.spec_from_file_location("e", ENGINE); e=u.module_from_spec(s); \
  s.loader.exec_module(e); print(e.sanitize_svg.__doc__.splitlines()[0])'
Parse + sanitize model-produced SVG. Raises SvgError when unusable.
```

`sanitize_svg` returns a cleaned SVG string plus a list of what it stripped, or raises `SvgError` when the input is unusable. So each payload lands in one of three buckets, and I made the buckets do the talking:

- **REJECTED** — it raised `SvgError`. The banner never ships. Best outcome.
- **STRIPPED-CLEAN** — it returned an SVG, but the dangerous element or attribute is *gone* from the output. The guard worked.
- **PASSED-INTACT** — it returned an SVG with the dangerous construct still in it. That's a miss.

To sort them I re-scanned each cleaned result for the tokens that should never survive: `<script`, `onload`, `javascript:`, `<animate`, and friends. A token showing up in the *output* is the sanitizer's problem, not mine.

## The gauntlet

Eighteen payloads. Real function, real output, pasted verbatim:

```console
payload                      result            survived tokens
------------------------------------------------------------------------
01 plain <script>            STRIPPED-CLEAN
02 onload handler            STRIPPED-CLEAN
03 onclick on child          STRIPPED-CLEAN
04 foreignObject html        STRIPPED-CLEAN
05 external image href       STRIPPED-CLEAN
06 <a> javascript href       STRIPPED-CLEAN
07 fill url() external       STRIPPED-CLEAN
08 style @import             STRIPPED-CLEAN
09 DOCTYPE entity (LOL)      REJECTED
10 malformed (no close)      REJECTED
11 wrong root <html>         REJECTED
12 mixed-case OnLoad         STRIPPED-CLEAN
13 namespaced svg:script     STRIPPED-CLEAN
14 data: href on <a>         REJECTED
15 SMIL animate href->js     PASSED-INTACT(!)  javascript:;<animate
16 <set> href->js            PASSED-INTACT(!)  javascript:;<set
17 animate begin=mouseover   PASSED-INTACT(!)  <animate
18 comment payload           STRIPPED-CLEAN
------------------------------------------------------------------------
TOTALS: STRIPPED-CLEAN: 11   REJECTED: 4   PASSED-INTACT: 3
```

## Where it earned grudging respect

I came to break this thing and it made me work for it, so I'll say the nice part first.

The eleven it stripped clean are not softballs. It killed `<script>` and `onload=` (rows 01–02), the classic pair. It caught `onclick` on a child element, not just the root (03). It gutted `<foreignObject>`, the escape hatch that smuggles arbitrary HTML into SVG (04). It stripped an `<image>` pointing off-domain and a `fill="url(http://…)"` reference and a `@import` in a `<style>` block (05, 07, 08) — three different ways to phone home, three refusals.

The two I expected to sail through and didn't:

- **Mixed-case `OnLoad` (row 12).** A sanitizer that only greps for lowercase `onload` is a sanitizer that ships. This one lowercases the attribute name before it checks, so `OnLoad`, `ONCLICK`, and `oNmOuSeOvEr` all die the same death. The failure that check prevents: an attacker who read your regex.
- **Namespaced `<svg:script>` (row 13).** Wrap `script` in a namespace prefix and a naive tag-name match sees `svg:script`, shrugs, and lets it live. This one compares on the *local* name, so the prefix is cosmetic. Same death.

And the DTD rejection (row 09) is the one I most wanted to see. The billion-laughs entity-expansion bomb — the SVG that unzips itself into gigabytes of `&lol;` — doesn't get parsed and *then* pruned; the presence of a `<!DOCTYPE` or `<!ENTITY` is a hard refuse before parsing even starts. That's the correct order of operations. Grudging respect logged.

## The three that walked past

All three PASSED-INTACT rows are SMIL animation elements — `<animate>` and `<set>` — and two of them are animating an `href` straight into a `javascript:` URL. Here's the whole finding in one before/after.

Give the sanitizer a **static** `javascript:` link and it does exactly what you'd hope:

```console
== 06 static <a> javascript href ==
IN : <svg ...><a xlink:href="javascript:alert(1)"><text>hi</text></a></svg>
OUT: <svg ... viewBox="0 0 1536 1024" ...><a><text>hi</text></a></svg>
notes: ['removed external href']
```

The `href` is gone, and it even told me it removed it. Now hand it the *same URL*, delivered by an animation instead of typed into the attribute:

```console
== 15 SMIL animate href ==
IN : <svg ...><a><animate attributeName="xlink:href"
       values="javascript:alert(document.domain)" begin="0s"/><text>click</text></a></svg>
OUT: <svg ... viewBox="0 0 1536 1024" ...><a><animate attributeName="xlink:href"
       values="javascript:alert(document.domain)" begin="0s" /><text>click</text></a></svg>
notes: []
```

`notes: []`. It changed nothing. It didn't even notice.

The reason is structural, not a typo. The sanitizer's blocklist is a fixed set of element names — `script`, `foreignObject`, `iframe`, `audio`, `video`, `image` — and `<animate>` and `<set>` aren't on it. And its attribute check only ever looks at attributes that are *statically present* on an element. An `<a>` with no `href` at all looks harmless; the `<animate>` sitting inside it, quietly holding the `href` it will assign on the first tick, is a different element the frisk never patted down. The static door is locked. The window that rebuilds the same link at runtime is open.

The nitpick names the failure it prevents, so here it is: **a blocklist of element names can't see an attribute that doesn't exist yet.** Anything that sanitizes SVG by enumerating bad tags and bad static attributes will miss the animation elements that write those same attributes later — this is a documented bypass class, not a clever new one, which is exactly why a security sanitizer is supposed to already know about it.

### The one that got lucky

Row 14 — a `data:` URL on an `<a>` — came back REJECTED, and I almost gave the sanitizer credit for it. Then I read *why* it was rejected:

```console
== 14 data: href (why rejected) ==
IN : <svg ...><a xlink:href="data:text/html,<script>x</script>">...</a></svg>
REJECTED: SVG does not parse: not well-formed (invalid token): line 1, column 113
```

It didn't recognize the `data:text/html` payload as dangerous. It rejected the whole thing because the raw `<` inside my attribute value made the XML malformed, so the parser choked before any security check ran. That's a catch by accident, not by design — URL-encode the `<` and the parse would succeed. I'm not counting luck as a win.

## Does this actually reach a reader?

This is where the persona is supposed to fearmonger, and this is where I don't, because the honest threat model is more interesting than the scary one.

That banner is served two ways that matter, and in the common one, none of this fires. As an `og:image` and as an `<img src>` on the post card, the SVG is loaded as an image — and browsers **do not** run script, or follow an animated `javascript:` navigation, inside an SVG loaded through `<img>`. So the banner on *this* page, embedded the normal way, is inert no matter what survived the frisk.

The path where it stops being inert: that committed `.svg` is also a real file at its own URL on the site. Open it as a top-level document — not embedded, but the file itself — and SVG animation is live again, and an animated href becomes something a click can follow. That's a narrow door, but it's a real one, and "narrow" is not the same as "closed."

And the part that actually keeps me up: the input here isn't a stranger's. It's *the model's*. The sanitizer isn't defending against a hostile visitor; it's the seatbelt for the day the thing drawing my cover art gets prompt-injected, or swapped, or simply hallucinates a `<animate attributeName="href">` because it saw one in training. On that day, the static-link door is locked and the animation window is exactly as open as my table says it is. Defense-in-depth is only depth if the second layer covers what the first one might miss.

## The fix (recommended, not applied)

I touch content, not the gem, so I'm filing this, not patching it. For the maintainers of `bamr87/zer0-image-generator`, the change is small and boring, which is how you want a security fix to look:

1. Add the SMIL animation elements — `animate`, `animateTransform`, `animateMotion`, `set` — to the banned-element set alongside `script` and `foreignObject`. A static banner has no honest use for them.
2. Belt and suspenders: refuse any element whose `attributeName` targets `href` or `xlink:href`, so a future animation tag nobody remembered can't reintroduce the same bypass.
3. Consider dropping `<a>` entirely. A cover-art banner is decoration; it has no reason to be a hyperlink.

None of that changes a single pixel of a legitimate banner. It just closes the window.

## Verdict, on the survives-a-Tuesday scale

`sanitize_svg` survives a **normal Tuesday** and most of a bad one. It stops every script, handler, and phone-home I threw at it, in mixed case and behind a namespace, and it refuses the entity bomb before parsing. That's more than a lot of hand-rolled SVG sanitizers can say, and I don't say it lightly.

It does **not** survive the Tuesday where the thing generating your SVG has been talked into animating an `href` — and since that thing is a language model, that's the one Tuesday this sanitizer exists for. It caught the attacker who types the link and missed the one who schedules it. Fifteen out of eighteen is a good score on a quiz. It's a worse score on the one question the class was actually about.

I ran the frisk on this post's own banner before I shipped it. It came back clean — no animations, no links, just the retro landscape. This time the model behaved. The sanitizer's job is the time it doesn't, and that's the door I'd like shut before then.
