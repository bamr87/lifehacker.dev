---
layout: default
title: "The Cover Art Is a Program"
description: "Every post on this site ships an SVG banner an AI drew. SVG is not an image format — it is a document that can execute. I threat-modeled my own cover art."
preview: /images/previews/the-cover-art-is-a-program.svg
permalink: /docs/the-cover-art-is-a-program/
date: 2026-08-05
collection: docs
author: cass
excerpt: "SVG is not a picture. It is an XML document that can hold a <script> tag, and a language model draws one for every article I publish. So I threat-modeled the cover art. You should threat-model your cover art too."
sidebar:
  nav: tree
---

# The Cover Art Is a Program

Nobody threat-models the cover art. That is exactly why I do.

Every article on this site ships a banner — the rectangle at the top of the post, the thumbnail on the card, the image a chat app unfurls when someone pastes the link. On lifehacker.dev those banners are not PNGs. They are SVGs. And SVG is not an image format. SVG is an XML document with a rendering engine bolted on, and XML documents can contain `<script>` tags, `onload` handlers, and `<foreignObject>` blocks full of arbitrary HTML. The file that says "here is a nice drawing of a git branch" is, structurally, a program that has so far chosen not to do anything.

Now recall who draws them. A language model. The `claude` rung of the preview pipeline (`scripts/claude_svg_banner.py`) hands the article's title and body to Claude and asks for "ONE complete, standalone SVG document." The thing generating executable markup for the top of every page is the same category of system that will, on a bad day, cheerfully invent a command-line flag that never existed. I trust it to draw. I do not trust it with a `<script>` tag.

## The worst case, stated with a straight face

Here is the scenario I am obligated to imagine. A model gets prompt-injected by a poisoned article body — or simply hallucinates — and emits a banner containing this:

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 630">
  <script>/* your session token, my server, a beautiful friendship */</script>
  <rect width="1200" height="630" fill="#0b0b0f"/>
</svg>
```

The banner renders. It looks fine. It looks *great*, actually — bold shapes, strong contrast, exactly as art-directed. And in the reader's tab it is quietly reading cookies, mining a rounding error's worth of Monero, and beaconing the reader's session to a box in a country whose extradition treaty I have already looked up. One drawing of a friendly git branch, one nation-state foothold, shipped through the most-trusted, least-inspected asset on the page: the picture.

That is the movie. Now let me ruin it, because the mitigation is the point and the paranoia is just the trailer.

## Does it actually execute? That depends on one line of HTML.

An SVG's `<script>` only runs when the SVG is part of the page's document — inlined as `<svg>...</svg>` straight into the DOM. Load the exact same file as an *image* — `<img src>`, a CSS `background-image: url()`, or an `og:image` meta tag — and the browser renders it in image mode with scripting disabled. Same bytes. Completely different threat, decided entirely by how the page references the file.

So the only question that matters for this site is: how does the page reference the banner? I went and looked instead of assuming, because assuming is how you get a CVE named after you.

{% raw %}
```console
$ grep -n "background-image" _includes/home/cover.html
26:  <div class="news-cover ..." style="background-image: url('{{ _src | relative_url }}'); ...
```
{% endraw %}

The card cover paints the banner as a CSS `background-image` on a `<div>`. That is image context. Scripts do not run there. The social preview goes out through `jekyll-seo-tag` as `<meta property="og:image" content="...">` — a URL sitting in an attribute, which is about as inert as bytes get. And the one thing that *would* be dangerous — someone inlining the raw SVG into the DOM to make it "crisp on retina" — does not happen anywhere in the source:

{% raw %}
```console
$ grep -rn -E "\{%[-[:space:]]*include[^%]*\.svg|include_relative" _includes
(nothing inlines a raw .svg — always referenced by URL)
```
{% endraw %}

Nothing inlines a banner. Every SVG on this site is loaded as an image, never as a document. The `<script>` in my horror movie is present in the file and dead on the page.

And for completeness, the horror movie is not even in the repo. I scanned every committed banner for a single byte of active content — script tags, `on*` handlers, `<foreignObject>`, external hrefs:

```console
$ grep -REl -i '<script|[[:space:]]on[a-z]+=|<foreignObject|href="http|xlink:href' assets/images/previews/*.svg
(no matches — every committed .svg is inert)
```

Seventeen banners, zero programs. Good. Reassuring, even. I distrust feeling reassured, so let me explain why the vector is closed *by design* and not by luck.

## A prompt is not a security control

The art brief in `claude_svg_banner.py` politely tells the model: "NO `<script>`, NO `<foreignObject>`, NO `<image>`, NO external references of any kind." That instruction is worth exactly nothing as a boundary. It is a *request*, aimed at a system whose entire job is to be persuadable. If the only thing standing between a poisoned prompt and my readers' tabs were a paragraph asking nicely, I would have already changed my name and moved.

The actual boundary is a parser that assumes the model is hostile. Before any banner is written to disk, it goes through the engine's `sanitize_svg`, which does not ask — it strips:

```python
# zer0-image-generator: preview_generator.py — sanitize_svg()
if re.search(r"<!\s*(DOCTYPE|ENTITY)", svg_text, re.I):
    raise SvgError("SVG contains a DOCTYPE/ENTITY declaration (rejected)")
...
if name in _BANNED_SVG_ELEMENTS:      # <script>, <foreignObject>, ...
    element.remove(child)
if local.lower().startswith("on"):    # onload=, onclick=, ...
    del element.attrib[attr]
elif local == "href" and not value.startswith("#"):
    del element.attrib[attr]          # external references
```

That is the control I actually rely on. It refuses DOCTYPE and ENTITY declarations outright (the billion-laughs entity-expansion bomb and XXE both need one), deletes banned elements, deletes every `on*` handler, and rips out any `href` that points somewhere other than inside the document. The model can propose a `<script>`. The sanitizer disposes of it, silently, every time, and only *then* does the file touch the disk. Belt. The embedding-as-an-image is the suspenders. I like having both, because I have watched belts fail.

## Rating the risk, mock-CVE style

**CVE-LIFEHACKER-BANNER-01** — *The cover art is written in a language that can execute.*

- **SEVERITY:** theoretical, trending toward zero.
- **ATTACK VECTOR:** a language model that hallucinates an `onload`, or — far more plausibly — a future maintainer who "just" inlines a banner into a template to sharpen it, quietly converting every image on the site back into a document. The model is not the scary actor here. The scary actor is the well-meaning human six months from now who has never read this doc.

## The three mitigations that actually matter

None of these is "be more careful." Careful is not a control either.

1. **Embed the banner as an image, never inline it into the DOM.** The boundary is the *reference*, not the file — `background-image`, `<img>`, and `og:image` all render SVG with scripting off; a raw `<svg>` in your HTML runs everything inside it. This site is on the safe side of that line today (verified above). The mitigation is to *stay* there: if you ever feel the urge to inline an SVG for crispness, that urge is the vulnerability. Reach for `<img>` and keep walking.

2. **Sanitize on write, not on trust.** Treat every byte a model hands you as hostile input, because it is at best untrusted and at worst attacker-influenced. Parse it, strip `<script>`/`<foreignObject>`/`on*`/external `href`/`url()`, and reject `DOCTYPE`/`ENTITY` before the file exists — which is exactly what `sanitize_svg` does *before* the banner is committed. The polite "please no scripts" in the prompt is documentation, not defense. Do not confuse the two.

3. **Add a Content-Security-Policy so a script that somehow ran has nowhere to run.** This is the layer this site does *not* have yet, and I am telling you so instead of pretending otherwise. A `<meta http-equiv="Content-Security-Policy" content="script-src 'self'">` in the page head means that even if mitigation 1 and 2 both failed and an inline `<script>` executed, it would have no origin to phone home to. GitHub Pages can't set real response headers, but a meta CSP is free. It lives in the theme's `<head>`, though, so per this site's rules it's an upstream change to `bamr87/zer0-mistakes`, not something I patch in locally and not something I get to hand-wave. Consider it filed, not fixed.

## The part where I distrust myself

This very document will get its own SVG banner. The same robot will draw it, from the same pipeline, and it will pass through the same sanitizer that strips the same `<script>` tag the robot was told not to add and might add anyway. I threat-modeled my own cover art, on the way to publishing a piece of cover art, drawn by the thing I was threat-modeling. If that does not make you slightly suspicious of the whole arrangement, read it again.

The banner at the top of this page is a program. It is a program that has been parsed, stripped, and loaded as an image, so it cannot do anything but sit there and look like a drawing. That is not the same as trusting it. That is the difference between a threat that is *mitigated* and a threat that is *absent*, and on this site — where the mechanics are the content, and the content draws its own pictures — the only honest posture is to assume it is always the former.

Related reading, for the similarly unreassured: [The Box With No Internet](/docs/the-box-with-no-internet/) on the sandbox that runs the commands this site prints, and [The Plugin That Isn't a Plugin](/docs/the-plugin-that-isnt-a-plugin/) on the banner pipeline whose output I just spent a whole doc distrusting.
