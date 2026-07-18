---
title: "Hide Your Navbar on Scroll Down, Bring It Back on Scroll Up"
description: "A navbar that hides when you scroll down and slides back when you scroll up — in CSS and ~15 lines of JS, plus the two bugs that bite everyone who tries it."
date: 2019-08-22
categories: [Hacks]
tags: [jekyll, web-dev]
author: amr
excerpt: "Reclaim the top of the viewport on scroll down, get the nav back on scroll up — and the one-pixel jiggle that breaks the naive version."
preview: /images/previews/hide-your-navbar-on-scroll-down-bring-it-back-on-s.png
permalink: /hacks/auto-hide-navbar/
---
The pitch for an auto-hiding navbar is that it gives readers back the strip of screen the nav was hogging. The reality is that it's three lines of CSS, a dozen lines of JavaScript, and three bugs that every first attempt hits in roughly the same order.

We'll do the working version. Then we'll leave both bugs in, because skipping them is how you ship the version that throws a console error and a navbar that never moves.

## The CSS: a class that lifts the nav out of view

Give the navbar an id, and write one class that pushes it up by its own height. The transition goes on the navbar itself — not the hide class — so it animates both directions.

```css
#navbar {
  position: sticky;
  top: 0;
  transition: transform 0.3s ease;
}

.hide-navbar {
  transform: translateY(-100%);
}
```

`translateY(-100%)` slides the bar up by exactly its own height, so it tucks out of view no matter how tall it is. Adding `.hide-navbar` lifts it; removing the class drops it back. The `transition` lives on `#navbar` so the slide plays whether the class is going on or coming off.

You'll know the CSS is right when you add `class="hide-navbar"` to the nav by hand in the browser's element inspector and the bar slides up smoothly. Delete the class in the inspector and it slides back down.

## The JavaScript: which way are you scrolling?

The whole trick is comparing the current scroll position to the last one. Bigger means you scrolled down; smaller means up.

```javascript
document.addEventListener('DOMContentLoaded', function () {
  const navbar = document.getElementById('navbar');
  let lastScrollTop = 0;

  window.addEventListener('scroll', function () {
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    if (scrollTop > lastScrollTop) {
      navbar.classList.add('hide-navbar');     // scrolling down -> hide
    } else {
      navbar.classList.remove('hide-navbar');  // scrolling up -> show
    }
    lastScrollTop = scrollTop;
  });
});
```

That `if (scrollTop > lastScrollTop)` is the entire decision. To check the logic without a browser, you can pull it out as a pure function and run it against a sequence of scroll positions. Here it is, the direction call extracted and fed a scroll session — down, down, up, up, then a tiny jiggle at the bottom:

```javascript
// scroll-logic.js — run with: node scroll-logic.js
function decide(scrollTop, lastScrollTop) {
  return scrollTop > lastScrollTop ? "add hide-navbar (going down)"
                                   : "remove hide-navbar (going up)";
}
let last = 0;
for (const y of [0, 120, 340, 200, 60, 62, 61]) {
  console.log(`scrollTop=${String(y).padStart(3)}  last=${String(last).padStart(3)}  -> ${decide(y, last)}`);
  last = y;
}
```

We ran that on Node. The real output:

```
scrollTop=  0  last=  0  -> remove hide-navbar (going up)
scrollTop=120  last=  0  -> add hide-navbar (going down)
scrollTop=340  last=120  -> add hide-navbar (going down)
scrollTop=200  last=340  -> remove hide-navbar (going up)
scrollTop= 60  last=200  -> remove hide-navbar (going up)
scrollTop= 62  last= 60  -> add hide-navbar (going down)
scrollTop= 61  last= 62  -> remove hide-navbar (going up)
```

The first five lines are exactly what you want. The last two are the part where it broke — hold that thought.

You'll know the JS works when you scroll down on the real page and the bar slides away, then scroll up a hair and it slides back.

## The first bug: `Cannot read properties of null`

The naive version puts the script in the `<head>` or near the top of the body and skips `DOMContentLoaded`. The browser greets you with:

```
Uncaught TypeError: Cannot read properties of null (reading 'classList')
```

`document.getElementById('navbar')` ran before the `<nav>` existed, so it returned `null`, and `null.classList` is the error. The fix is already in the code above: wrap the whole thing in `DOMContentLoaded` so the lookup waits until the nav is on the page. (Putting the `<script>` tag immediately before `</body>` works too — same idea, the element exists before you reach for it.)

You'll know it's fixed when the console is clean on reload and `navbar` is a real element, not `null`.

## The second bug: `top: -100px` does nothing

The other common first attempt hides the bar with `top` instead of `transform`:

```css
.hide-navbar {
  top: -100px;   /* does nothing on a sticky/fixed navbar */
}
```

On a `position: sticky` (or `fixed`) navbar, `top` is already pinned to `0` and the offset is fought by the sticky behavior — the bar sits there unmoved while you scroll, class or no class. `transform: translateY(-100%)` moves the element in the paint layer regardless of its positioning, which is why the working CSS above uses it. If your nav refuses to budge, this is almost always why.

You'll know you hit this one when the class is clearly being added (you can see `hide-navbar` appear in the inspector) and the bar still doesn't move.

## The part where it broke, for real: the one-pixel jiggle

Look again at the last two lines of that test output:

```
scrollTop= 62  last= 60  -> add hide-navbar (going down)
scrollTop= 61  last= 62  -> remove hide-navbar (going up)
```

A two-pixel scroll down hid the bar; a one-pixel drift back up showed it again. On a trackpad or a phone, your scroll position twitches by a pixel or two constantly even when you think you're holding still — and `scrollTop > lastScrollTop` fires on every twitch. The result is a navbar that flickers in and out while you're trying to read. The source version never catches this because it only ever tested big, deliberate scrolls.

The fix is to ignore moves smaller than a few pixels, and to force the bar visible near the very top of the page (where a hidden nav is only annoying):

```javascript
document.addEventListener('DOMContentLoaded', function () {
  const navbar = document.getElementById('navbar');
  const DELTA = 5;        // ignore scroll moves smaller than this
  const TOP_ZONE = 80;    // always show the nav near the top
  let lastScrollTop = 0;

  window.addEventListener('scroll', function () {
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    if (Math.abs(scrollTop - lastScrollTop) <= DELTA) return;  // too small, ignore
    if (scrollTop < TOP_ZONE) {
      navbar.classList.remove('hide-navbar');                  // near top, force show
    } else if (scrollTop > lastScrollTop) {
      navbar.classList.add('hide-navbar');                     // down -> hide
    } else {
      navbar.classList.remove('hide-navbar');                  // up -> show
    }
    lastScrollTop = scrollTop;
  });
});
```

Run the same scroll session through the fixed decision and the jiggle stops mattering:

```javascript
// scroll-logic-fixed.js — run with: node scroll-logic-fixed.js
function decide(scrollTop, lastScrollTop, delta) {
  if (Math.abs(scrollTop - lastScrollTop) <= delta) return "no change (move too small)";
  if (scrollTop < 80) return "remove hide-navbar (near top, force show)";
  return scrollTop > lastScrollTop ? "add hide-navbar (going down)"
                                   : "remove hide-navbar (going up)";
}
let last = 0;
for (const y of [0, 120, 340, 200, 60, 62, 61]) {
  console.log(`scrollTop=${String(y).padStart(3)}  last=${String(last).padStart(3)}  -> ${decide(y, last, 5)}`);
  last = y;
}
```

We ran that on Node. The real output:

```
scrollTop=  0  last=  0  -> no change (move too small)
scrollTop=120  last=  0  -> add hide-navbar (going down)
scrollTop=340  last=120  -> add hide-navbar (going down)
scrollTop=200  last=340  -> remove hide-navbar (going up)
scrollTop= 60  last=200  -> remove hide-navbar (near top, force show)
scrollTop= 62  last= 60  -> no change (move too small)
scrollTop= 61  last= 62  -> no change (move too small)
```

The two real direction changes still register. The one- and two-pixel twitches at the bottom now resolve to "no change," so the bar stays put. And the move that lands inside the top 80 pixels forces the nav back on screen instead of leaving it hidden at the top of the page.

You'll know the delta is doing its job when you can rest a finger on the trackpad, watch the scroll position quiver by a pixel, and the navbar doesn't react.

## When this goes wrong

A few honest caveats from the parts that don't show up in a quick demo:

- **The handler runs on every scroll event**, which can be dozens of times a second. The work here is cheap (a subtraction and a class toggle), so it's fine, but if you pile heavier logic into the same handler you'll want to throttle it or move the toggle into `requestAnimationFrame`.
- **The pure-function tests above check the decision, not the rendering.** They prove the direction logic is correct; they do not prove the CSS animates, the `<script>` is wired up, or the id matches. The id in your HTML (`id="navbar"`) and the id in `getElementById('navbar')` have to be identical, and a typo there reproduces the `null` error from earlier.
- **`window.pageYOffset` is the old name for `window.scrollY`.** Both still work; `scrollY` is the modern spelling if you'd rather not look it up later.

That's the whole hack: one CSS class, one delta-guarded scroll handler, and the three failures — the null element, the dead `top`, and the pixel jiggle — that stand between the naive version and one that doesn't flicker.
