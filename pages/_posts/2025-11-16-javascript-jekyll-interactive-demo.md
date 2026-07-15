---
title: "The 'Interactive' Jekyll Demo That Forgot to Include the Demo"
description: "A Jekyll post promised an interactive JavaScript demo above the fold, then shipped without one. Here is what layering JS on a static site actually takes."
preview: /images/previews/the-interactive-jekyll-demo-that-forgot-to-include.png
date: 2025-11-16
categories: [Field Notes]
tags: [jekyll, javascript, static-sites, progressive-enhancement, documentation]
author: amr
excerpt: "I inherited a post that says 'try the interactive demo above.' There is no demo above. There is no demo anywhere. So let's talk about the gap."
---

I was handed an old post to bring over to this site, and it opened with a confident line: *the interactive demo above is your playground.*

There was no demo above. There was no demo below. There was a heading that said "Interactive Features Showcase," followed by a bulleted list of features the showcase was going to show, followed by an instruction to go play with the showcase that did not exist. The post described a widget the way a menu describes a meal — vividly, and without feeding anyone.

I want to be honest about that up front, because the easy move was to quietly build the missing demo, embed it, and pretend the original always had one. I did not do that. I reproduced no live widget. What you are reading is the post the original was trying to be: an argument about what it actually costs to put JavaScript on a Jekyll page, written by someone who just watched a post fail to do it.

## The tell of a demo that was never wired up

Here is the structure I inherited, paraphrased only slightly:

- "This comprehensive demo showcases the perfect marriage between static generation and dynamic scripting."
- A list of categories the demo covers: DOM manipulation, dynamic content generation, performance demonstrations.
- "The demo below includes several interactive components."
- "The interactive demo above is your playground."

Count the directions. The components are simultaneously *below* and *above*. That is not a typo; it is the fingerprint of a page where the prose was written for a widget that was always going to be added "later," and later never arrived. The copy got committed. The `<script>` did not.

This happens because the words are the cheap part. Describing five interactive features takes a paragraph. Building one that survives a static-site build, a CDN cache, and a reader with JavaScript disabled takes an afternoon and a couple of decisions you cannot un-make. The post optimized for the cheap part and called it comprehensive.

## What "JavaScript on Jekyll" actually means

The original's one true sentence was that Jekyll layouts can hold JavaScript. They can. A Jekyll page is HTML by the time it reaches the browser; nothing stops you from putting a `<script>` in a layout or a post. The marriage the post kept toasting is real. It is just less of a wedding and more of a handoff: Jekyll builds the page once, at deploy time, on a server you will never see again; JavaScript runs every time, on a machine you do not control, after the static part has already shipped.

That handoff is the entire subject, and it is the thing the missing demo would have had to respect. Two facts fall out of it:

**Jekyll has no idea your JavaScript exists.** Liquid runs at build time. `{% raw %}{% if page.interactive %}{% endraw %}` is decided once, on the build server, and baked into flat HTML. Your `addEventListener` runs later, in the browser, on that flat HTML. They never meet. A demo that blurs this line — that expects Liquid and JS to cooperate at the same moment — is describing a framework Jekyll is not.

**The reader might have JS off, or it might just not load.** A static site's whole pitch is that the HTML is the product. If your "interactive demo" is the only content in a section, and the script 404s or the reader blocks it, the section is empty. Which, in the post I inherited, it was — permanently, for everyone, because the script was never written at all. That is the disabled-JavaScript failure mode, except achieved through pure ambition.

## Progressive enhancement, said plainly

The original gestured at progressive enhancement and then, in the same breath, printed this as the "base functionality":

```javascript
// Base functionality (works without JS)
<button onclick="alert('Hello!')">Click me</button>
```

That is not base functionality. It is an inline JavaScript handler inside a JavaScript code block. If JS is off, that button does nothing. Calling it the no-JS baseline is the exact mistake the section was warning against — the page enhanced itself right past the floor it was supposed to stand on.

Progressive enhancement on a static site means something stricter and more boring: **the page is useful as flat HTML, and JavaScript makes it nicer, not possible.** A search box that's a real form posting to a results page, then upgraded to filter live. A details/summary that toggles with no script, then animates with one. The test is brutal and simple: turn JavaScript off and reload. If a section vanishes, that section was never enhanced. It was load-bearing JS wearing a hat.

I did not capture a screenshot of this working, because there is nothing working to capture — and a screenshot of a widget I built just for the post would be exactly the fabrication I'm refusing to commit. The honest artifact here is the absence.

## The "performance demonstration" that demonstrated nothing

The post promised "execution timing," "memory management," and "optimization strategies," then demonstrated none of them. It listed them. There is a difference between a benchmark and a table of contents for a benchmark, and the difference is whether a number ever appears.

If you want to actually time DOM work in a static page, the tool is unglamorous and already in the browser:

```javascript
const t0 = performance.now();
buildTheList();        // the thing you're measuring
const t1 = performance.now();
console.log(`built in ${(t1 - t0).toFixed(1)}ms`);
```

That's it. No framework, no "performance monitoring layer," no comprehensive showcase. A measurement is two timestamps and a subtraction. The post used the word "performance" five times and produced zero milliseconds. I am not going to invent a number to fill the gap, because a benchmark I didn't run is worth exactly as much as the demo that wasn't there.

## What I kept, and why this is a Field Note and not a tutorial

I kept the genuinely true skeleton: Jekyll layouts can carry JavaScript; the build/runtime split is the thing to design around; progressive enhancement is the discipline that keeps a static site static. I cut the infomercial — the "perfect marriage," the "cutting edge," the five tiers of features that were headings with nothing under them — because every one of those was a promise the file did not keep.

This is a Field Note instead of a how-to because I cannot in good conscience write the step-by-step the original implied. There is no verified live widget to walk you through. Reproducing one and presenting it as the recovered demo would make me the second author in a row to describe a playground nobody can use. One was enough.

The lesson the original was reaching for, stated without the confetti: **on a static site, prose is free and behavior is expensive, so the prose drifts ahead of the behavior unless you make it pay rent.** The way you make it pay rent is to write the words last — after the `<script>` runs, after you've turned JS off and confirmed the page survives, after a real timestamp prints a real number. The post I inherited wrote the words first and shipped before the bill came due.

If I ever do build that demo, it will arrive as its own page, with the script in the repo, working with JavaScript off in a degraded-but-real form, and a number I actually measured. Until then, the truthful unit of work was to tell you the demo was never there — and then not pretend otherwise.
