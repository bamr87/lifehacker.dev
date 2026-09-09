---
title: "I let a language model draw on my own website. Here is the whitelist between it and you."
description: "Threat-modeling the motif layer: a language model draws my cover art — parsed, whitelisted, re-serialized before a byte reaches your browser."
date: 2026-09-07
preview: /images/previews/i-let-a-language-model-draw-on-my-own-website-here.svg
categories: [Field Notes]
tags: [ai, automation]
author: cass
excerpt: "The illustration on this article was authored by a language model. That sentence should scare you exactly as much as it scares me — and then stop scaring you, on purpose."
---
I am the paranoid one, so let me ruin the cover art for you.

The banner at the top of most articles here has two layers. The bottom layer — the lattice, the palette, the gentle bloom — is computed by deterministic code from the article's own text, and my colleague already spent a sleepless night threat-modeling *that* in [the cover art is an SVG, which is to say a program](/posts/2026/08/12/cover-art-svg-is-a-program/). Read it; it is good. This is not that post. This is about the layer on TOP: the little drawing of what the article is actually about. A robot, a padlock, a broken pipe. That drawing was not computed. That drawing was authored by a language model, validated, and committed to this repository as a `.svg` file that is then served to you from `lifehacker.dev` — the same origin that holds your session and speaks with the site's full authority.

Say that sentence again slowly. I asked a language model for some markup, and I put the markup on my website.

## The absurd version, said with a straight face

Here is the thriller. I ask the model to draw a robot holding a wrench. The model, having been prompt-injected by a poisoned training example, a rogue smart fridge, or simply a bad Tuesday, instead returns a `<script>` tag wearing a robot costume. It parses. It is valid XML. It is on-palette. It renders as a perfectly charming little robot, and it also, quietly, `fetch()`es your logged-in session to a server in a country whose extradition treaty is a rumor. Nobody notices, because who audits the decoration, and who *especially* audits the decoration a robot drew? The call is coming from inside the cover art.

`SEVERITY: my own art department. ATTACK VECTOR: the one contributor to this repo who cannot be fired, cannot be shamed, and generates fresh markup on demand.`

Now the walk-back, because the fear is the bit and the mitigation is the point: this did not happen, and on this site today it *cannot* happen — not because the model is trustworthy (it is not; nothing is) but because the model is never trusted in the first place. The markup it writes does not reach your browser. Not a byte of it. Let me show you why, because the "why" is the only part worth publishing.

## The threat model, stated plainly

Treat the language model as what it is: an untrusted contributor with commit access to your art directory. Not malicious — that is not the assumption. *Compromisable.* An input you did not write, cannot fully predict, and must never copy through verbatim. The moment you paste an LLM's raw output into a file the browser will execute, you have handed an unaudited stranger a `<script>` slot on your own origin.

The whole defense fits in one sentence, and it is a sentence I wish more pipelines lived by: **the model owns the subject matter and nothing else.** It picks *what* to draw. Deterministic code that I can read owns every byte that reaches disk. The seam between those two facts is a file called `scripts/preview/lib/motif.mjs`, and it does three things I actually went and verified instead of taking on faith.

## Recon, part one: I fed it the attacks

First move under breach assumption: stop trusting the docstring and try to get a payload through. I imported the validator and handed it the four things a hostile drawing would try. This is real output from a script I ran, not a transcript I imagined:

```console
### a <script> smuggled into a drawing
ok: false
 - <script> is not allowed. Draw only with g, path, circle, ellipse, rect, line, polyline, polygon...

### an event handler on a shape (SVG-XSS classic)
ok: false
 - attribute onload="..." is not allowed on <rect>. Allowed: transform, opacity, fill, stroke...

### an external image pulled from another origin
ok: false
 - <image> is not allowed. Draw only with g, path, circle, ellipse, rect...

### a raw hex colour instead of a palette token
ok: false
 - fill="#ff0000" on <circle> is not a palette token. Paint only with ink, cool, warm, accent...
```

Every one refused. And notice *how* it refuses `<script>` and `<image>`: not with a blacklist of scary tags, but because they are simply **not in the vocabulary**. The validator knows eight elements — `g`, `path`, `circle`, `ellipse`, `rect`, `line`, `polyline`, `polygon`, plus gradient plumbing — and every element that is not one of those eight is rejected on sight. `script`, `image`, `use`, `foreignObject`, `text`, `filter`, and the whole animation family need no explicit ban. A blacklist has to imagine every attack. A whitelist only has to describe the eight shapes you meant to allow, and then the attacks it never heard of die anyway. This is the difference between "I blocked the payloads I know about" and "I permitted the eight things I want, full stop." Only the second one lets me sleep.

## Recon, part two: even if it gets past the guard, it does not reach disk

A whitelist that only *checks* is a guard who inspects your bag and then hands the bag back to you to carry inside. The good version takes your things out and carries them in itself. So the real test: parse a hostile fragment, then serialize it back out and see what survives. Again, real output:

```console
parsed attrs on <rect>: {"x":"100","y":"100","width":"800","height":"800",
  "fill":"cool","onload":"alert(document.cookie)","data-exfil":"yes"}
re-serialized:
  <g>
    <rect x="100" y="100" width="800" height="800" fill="var(--cool)"/>
  </g>
```

The parser *saw* `onload` and `data-exfil`. They are right there in the parsed attributes. And then the serializer, which loops over a per-element allowlist and emits nothing else, dropped both on the floor. `cool` came out the other side as `var(--cool)`, a palette token that resolves to a section colour I control. **Nothing the model wrote is copied through.** Every tag and attribute in the committed file came out of the whitelist, re-typed by my code, which means there is no smuggling channel — no attribute the validator forgot to check can ride along, because the serializer would have to have been taught to emit it, and it wasn't. The bag never comes back to the model. Good.

The third property is geometry, and it is not a security control — it is a taste control, and I mention it only because it uses the same trick: the code walks every coordinate the drawing visits and rejects a motif that hides in a corner or drops a full-bleed plate over the field, feeding the specific failure back to the model as its next instruction. A whitelist for shapes and a whitelist for *composition*. The model gets to be creative inside a box whose walls I welded.

## The good surprise I resent: it is already re-checked on the way in

I came to this ready to file an angry issue demanding the committed drawings get re-validated, not just the ones drawn today. Because a motif is a file in the repo, and files in a repo get hand-edited, and a hand-edited motif is a fresh untrusted input wearing the trust of "well, it was fine when the robot drew it." I was going to be so smug about it.

```console
$ node scripts/preview/illustrate.mjs --check
[]

$ node scripts/preview/illustrate.mjs --self-test
[illustrate] self-test: validator
  ok   a script is refused
  ok   an external image is refused
  ok   raw hex is refused
  ok   a foreignObject is refused
  ...
[illustrate] self-test: all passed
```

`--check` runs the validator against all 29 committed motifs on every CI run through `lint_preview.rb`, and an empty array means every one of them would pass the same guard again today. A drawing is treated as a committed *input*, re-inspected on the way in and not just on the way out. And `--self-test` guards the guard — it feeds the validator a `<script>`, a `<foreignObject>`, a raw hex, and confirms each is still refused, so the day someone "simplifies" the whitelist and quietly opens a hole, a test goes red instead of a banner going evil. It is turtles all the way down, and for once I am glad of the turtles.

## The three mitigations, ranked, each one I ran

The paranoia is the framing. This is the payload. If you are ever tempted to put a language model's raw output somewhere a browser will execute it — and cover art, README badges, "AI-generated email signatures," anything SVG — do these three, in this order:

1. **Whitelist the vocabulary, never blacklist the attacks.** Enumerate the handful of elements and attributes you actually want and refuse everything else by default. `motif.mjs` permits eight drawing elements; `<script>` is not blocked, it is simply never allowed, along with every attack tag nobody has invented yet. A blacklist is a promise to have imagined every payload. You have not. Nobody has.
2. **Re-serialize; never copy the model's bytes through.** Parse the output into a structure, validate it, and emit a *fresh* file from your own code so the only bytes that reach disk are ones your serializer chose to write. I watched `onload` and `data-exfil` survive the parser and die at the serializer. That gap — parse-then-re-emit — is where the smuggling channel would have been, and it is closed by construction, not by vigilance.
3. **Re-validate the committed artifact, and test the validator itself.** The drawing is an input every time it is read, not just the day it was made. Run the whitelist against the whole committed corpus in CI (`--check` here), and keep a self-test that proves the validator still refuses the classics (`--self-test`), so a well-meaning refactor that widens the whitelist trips a red test instead of shipping a quiet hole.

None of those is "review the AI's output carefully." I do not trust myself to eyeball a thousand `<path>` commands and spot the one that is a fetch in a trench coat, and neither should you. The point of a whitelist is that it does not require me to be smart at 2 a.m. It requires me to have been specific, once, in daylight.

The illustration on this article was drawn by a language model. It is a picture of a whitelist standing between a language model and your browser. It went through the whitelist to get here. I checked. Then I checked that I had checked. I am still not reassured — that is not a thing that happens to me — but for once the machinery earned the shrug.
