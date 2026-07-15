---
title: "60 lines of inline nanobar became one config-driven Jekyll include (and the footer finally reaches the edges)"
description: "A hardcoded progress bar across three Jekyll files becomes one config-driven include, plus why four nested Bootstrap containers stop a dark footer short."
preview: /images/previews/60-lines-of-inline-nanobar-became-one-config-drive.png
date: 2026-04-19
categories: [Field Notes]
tags: [jekyll, bootstrap, refactoring, css, zer0-mistakes]
author: amr
excerpt: "Sixty lines of inline progress bar in three files, one stray P character, and a footer that wouldn't touch the edges. Two bugs, one sitting."
---

The page-loading progress bar — the thin strip that crawls across the top while a page loads — lived in three different files. About sixty lines of HTML, CSS, and JavaScript, inlined directly into `head.html`, with the color, height, and animation steps as magic numbers sprinkled across `head.html`, `header.html`, and a vendored `nanobar.min.js`.

Changing the bar's color meant editing HTML. Moving it meant editing markup. And the vendored library had a stray `P` character prepended to it — a copy-paste scar — which meant the whole thing failed silently and nobody had noticed, because a progress bar that doesn't appear looks exactly like a fast page load.

This is the story of folding all of that into one include, and the footer bug I found by accident while I was in there.

## The part where it was already broken

Here is the inventory before anyone touched anything:

| File | What it held |
|------|--------------|
| `head.html` | ~60 lines: an inline `<style>`, an inline `<script>`, the config as literals |
| `header.html` | A hardcoded `<div class="nanobar" id="top-progress-bar">` jammed inside the navbar |
| `nanobar.min.js` | The third-party library, with a stray `P` at byte zero |

The stray `P` is the one that stings. It was a real, shipped JavaScript parse error. The browser hit it, gave up on the file, and the bar quietly never ran. No red console wall, no failed build — just a feature that wasn't there and a `Uncaught SyntaxError` you only see if you open DevTools and go looking. The bar had been decorative dead weight in the page source for who knows how long.

So before any clever refactor, the actual fix was deleting one character. The rest is making sure it never scatters like that again.

## The shape: one file owns the whole subsystem

The pattern is config-driven single-include. All the knobs live in `_config.yml`; one include reads them and renders everything.

```text
_config.yml (values) → nanobar.html (CSS + JS bridge) → rendered page
```

The config block replaces every literal that used to be buried in markup:

```yaml
# _config.yml
nanobar:
  enabled       : true
  color         : "var(--bs-primary)"
  background    : "transparent"
  height        : "3px"
  position      : "navbar"        # top | bottom | navbar
  z_index       : 9999
  steps         : [20, 55, 85, 100]
  step_delay_ms : 180
  classname     : "nanobar"
  id            : "top-progress-bar"
```

Twenty-two lines of YAML that you can actually find, versus sixty lines of HTML you had to go spelunking for.

## The one trick worth keeping: Liquid writes the CSS variables, CSS reads them

The bridge between "config at build time" and "styles at render time" is CSS custom properties. Liquid stamps the values into `:root` once, at build; the stylesheet consumes them forever after without knowing or caring where they came from.

{% raw %}
```liquid
<style id="nanobar-theme">
  :root {
    --nanobar-color:  {{ site.nanobar.color | default: "var(--bs-primary)" }};
    --nanobar-bg:     {{ site.nanobar.background | default: "transparent" }};
    --nanobar-height: {{ site.nanobar.height | default: "3px" }};
    --nanobar-z:      {{ site.nanobar.z_index | default: 9999 }};
  }
</style>
```
{% endraw %}

The `| default:` filters matter more than they look. If the config key is missing, you get a working fallback instead of a CSS variable set to the literal string `""`, which silently breaks the rule it lives in. Liquid will happily render an empty value; CSS will happily ignore the whole declaration. Belt and suspenders.

The JS side gets the same treatment — a small bridge object so the initializer reads config, not hardcoded literals:

{% raw %}
```liquid
<script>
  window.zer0Nanobar = {
    position:  "{{ site.nanobar.position | default: 'top' }}",
    steps:      {{ site.nanobar.steps | default: "[20,55,85,100]" }},
    stepDelay:  {{ site.nanobar.step_delay_ms | default: 0 }},
    id:        "{{ site.nanobar.id | default: 'top-progress-bar' }}"
  };
</script>
```
{% endraw %}

Note `steps` has no quotes — it's injected as a raw JS array, not a string. Quote it and you'll be parsing `"[20,55,85,100]"` at runtime wondering why the animation does nothing.

Then `head.html` shrinks to one line, which is the entire point:

{% raw %}
```liquid
{% include components/nanobar.html %}
```
{% endraw %}

**You'll know it worked when** the bar appears as a thin strip under the navbar on a slow load, and changing `color:` in `_config.yml` — not in any HTML file — changes the bar. If you can recolor it from config without touching markup, the refactor did its job.

## The footer I broke into by accident

After the nanobar was done, a visual check turned up an unrelated bug: the footer's dark section had pale gaps on both sides. The dark background stopped short of the viewport edges, like a rug that doesn't reach the walls.

First instinct: I just changed a bunch of CSS, so I probably caused this. That instinct was wrong, and the cheapest way to prove it was git, not guessing.

```bash
git log --oneline -5 -- _includes/core/footer.html
```

The footer hadn't been touched in any recent commit. My nanobar work was innocent. That single command saved an hour of staring at the wrong diff — when something looks broken right after your change, the first question is "did my change actually touch this file," and `git log -- <path>` answers it in one line.

So the bug was old. The real cause was four nested Bootstrap `.container` classes that had accumulated over a pile of earlier PRs:

```html
<footer class="bd-footer container-xl border-top">      <!-- max-width -->
  <div class="container row my-3">                       <!-- max-width -->
    <div class="container bg-dark text-light rounded-3"> <!-- max-width -->
      <div class="container">                            <!-- max-width -->
```

Every Bootstrap `.container` (and `.container-xl`) sets a `max-width` and `auto` side margins. Nest four of them and the dark `bg-dark` element — sitting on the third level — can never reach the edge, because three ancestors are already pulling it inward. The background only paints as wide as its box, and the box was capped four times over.

A quick way to count how many width-cappers you're fighting, on a self-contained copy of the markup:

```bash
# lh:run
cd "$(mktemp -d)"
cat > footer.html <<'EOF'
<footer class="bd-footer container-xl border-top">
  <div class="container row my-3">
    <div class="container bg-dark text-light rounded-3">
      <div class="container">
        content
      </div>
    </div>
  </div>
</footer>
EOF
grep -o 'class="[^"]*container[^"]*"' footer.html | wc -l | tr -d ' '
```

That prints `4`. Four containers, four max-widths, one rug that won't reach the wall. (That command actually runs in this site's sandbox — that's the real output.)

## The fix: put the background outside the container, the content inside

The rule for "full-bleed color, centered content" is to split them. The element that paints the background goes full width with no `.container`; a `.container-xl` *inside* it re-centers the content. The container's job is to constrain text, not to constrain paint.

```html
<footer class="bd-footer border-top">          <!-- no container: full width -->
  <div class="container-xl my-3">               <!-- powered-by, centered -->
    <!-- powered-by content -->
  </div>
  <div class="bg-dark text-light py-5">         <!-- full-width dark band -->
    <div class="container-xl">                  <!-- content centered inside -->
      <!-- branding, links, social, subscribe -->
    </div>
  </div>
</footer>
```

What changed, and why each one:

- Dropped `container-xl` from `<footer>` so the element spans the full viewport.
- Moved `bg-dark` onto a full-width band, with a `container-xl` *inside* it to keep the text from sprawling on wide monitors.
- Nesting went from four levels to two.
- Dropped `rounded-3` — a flush, edge-to-edge band shouldn't have rounded corners; they'd just be clipped at the viewport anyway.

**You'll know it worked when** the dark band runs wall to wall with no pale margins, and the footer text stays centered at a readable width on a 4K screen. Resize the window: the color tracks the edges, the text does not.

## When this goes wrong

A few honest ways to faceplant on this exact pattern:

- **Empty config keys render empty CSS.** Skip the `| default:` filters and a missing `_config.yml` key produces `--nanobar-height: ;`, which CSS silently drops. The bar shows up with zero height and you stare at a blank space convinced the JS is broken.
- **Quoting the `steps` array.** Wrap it in quotes and JS gets a string, not an array, and the animation no-ops with no error.
- **Reaching for `container-fluid` instead of removing the container.** `container-fluid` is full width with horizontal padding — which can be what you want, but if you nest it *inside* another `.container` you're right back to a capped width. The fix is fewer containers, not a different one.
- **Assuming your latest change caused an old bug.** Run `git log -- <file>` before you trust the timeline in your head. The footer had been wrong for ages; the nanobar work just turned on the lights.

Two bugs, one sitting: a feature that never ran because of one stray character, and a layout that never reached the edges because of four containers nobody removed. Neither was clever. Both were the kind of thing that hides because the broken state looks fine until you look straight at it.
