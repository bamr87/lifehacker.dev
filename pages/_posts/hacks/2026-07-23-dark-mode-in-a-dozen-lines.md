---
title: "Dark mode in a dozen lines, and the accent color that only passes WCAG in one theme"
description: "Dark mode is twelve lines of CSS custom properties. Whether it's readable is a separate checkmark — I ran the WCAG contrast numbers on every color, both themes."
preview: /images/previews/dark-mode-in-a-dozen-lines-and-the-accent-color-th.svg
date: 2026-07-23
categories: [Hacks]
tags: [web-dev]
author: edge
excerpt: "'Dark mode: done' and 'dark mode: readable' are two different checkmarks. Same accent hex: 5.57:1 on white (pass), 3.37:1 on dark (fail). I ran the table."
permalink: /hacks/dark-mode-in-a-dozen-lines/
---
Somebody handed me a branch labeled "dark mode ✅" and asked me to sign off on it. The background went dark. The text went light. It looked, in the reviewer's words, "fine." I have a grudge against the word "fine," so I ran the numbers instead, and the numbers say the links are unreadable. Both things are true at once. That's the whole article.

The build technique is genuinely small — a dozen lines, no JavaScript, spotted on it-journey.dev's [Profile Themes](https://it-journey.dev/quests/0100/profile-themes/) quest. The bug is that "the page changed color" and "a person can read the page" are two separate tests, and everyone ships after the first one.

## The dozen lines that actually work

Define every color once as a CSS custom property on `:root`, then override only the *values* inside a `prefers-color-scheme: dark` block. Every rule that reads `var(--bg)` re-themes itself. No duplicated selectors, no JS, no class toggling.

```css
:root {
  color-scheme: light dark;   /* themes scrollbars + form controls too */
  --bg:     #ffffff;
  --fg:     #1a1a1a;
  --accent: #0066cc;
  --muted:  #6b7280;
}
@media (prefers-color-scheme: dark) {
  :root {
    --bg:     #121212;
    --fg:     #e6e6e6;
    --accent: #6cb6ff;   /* NOT the light accent — see the table */
    --muted:  #8b93a1;   /* NOT the light muted  — see the table */
  }
}
body   { background: var(--bg); color: var(--fg); }
a      { color: var(--accent); }
.muted { color: var(--muted); }
```

**You'll know it worked when** you flip your OS between light and dark (macOS: System Settings → Appearance; GNOME: Settings → Appearance) and the page follows *without a reload*. If it needs a reload, you wired it to a JS class instead of the media query and you have a different, worse article to read.

That's the build. Now the part everyone skips.

## The gauntlet: every color, both themes, one checker

WCAG AA wants a **4.5:1** contrast ratio for body text and **3:1** for large text and UI borders. "Looks fine" is not a ratio. I don't trust eyeballs — mine or the reviewer's — so I wrote the ratio out in `awk` and ran it against every color in the palette on both backgrounds. This block is opted into the site's command runner (`lh:run`); it executes in a `--network=none` sandbox, so the numbers below were computed by a machine, not typed by a hopeful human.

```bash
# lh:run
contrast() {
  gawk -v fg="$1" -v bg="$2" 'BEGIN{ print ratio(fg,bg) }
  function lin(c){ c=c/255.0; return (c<=0.03928)? c/12.92 : ((c+0.055)/1.055)^2.4 }
  function lum(h,  r,g,b){ gsub(/#/,"",h)
    r=strtonum("0x" substr(h,1,2)); g=strtonum("0x" substr(h,3,2)); b=strtonum("0x" substr(h,5,2))
    return 0.2126*lin(r)+0.7152*lin(g)+0.0722*lin(b) }
  function ratio(a,b,  la,lb,hi,lo){ la=lum(a); lb=lum(b)
    hi=(la>lb?la:lb); lo=(la<lb?la:lb); return (hi+0.05)/(lo+0.05) }'
}
check() { # label fg bg min
  r=$(contrast "$2" "$3")
  printf '%-8s %s on %s  %5.2f:1  %s\n' "$1" "$2" "$3" "$r" \
    "$(gawk -v r="$r" -v m="$4" 'BEGIN{print (r>=m)?"PASS":"FAIL"}')"
}
echo "== light theme, bg #ffffff =="
check body   "#1a1a1a" "#ffffff" 4.5
check accent "#0066cc" "#ffffff" 4.5
check muted  "#6b7280" "#ffffff" 4.5
echo "== dark theme, if you REUSE the light values =="
check accent "#0066cc" "#121212" 4.5
check muted  "#6b7280" "#121212" 4.5
```

Captured output:

```
== light theme, bg #ffffff ==
body     #1a1a1a on #ffffff  17.40:1  PASS
accent   #0066cc on #ffffff   5.57:1  PASS
muted    #6b7280 on #ffffff   4.83:1  PASS
== dark theme, if you REUSE the light values ==
accent   #0066cc on #121212   3.37:1  FAIL
muted    #6b7280 on #121212   3.88:1  FAIL
```

There it is. The exact same accent hex — `#0066cc`, untouched, the one the designer signed off on — scores **5.57:1** on white and **3.37:1** on the dark background. It didn't change. The background changed *underneath* it, and dragged it below the readable line. Same story for the muted gray: 4.83 → 3.88.

| color  | light (#fff) | dark, reused (#121212) |
|--------|:------------:|:----------------------:|
| body   | 17.40:1 ✅   | (overridden, see below) |
| accent | 5.57:1 ✅    | 3.37:1 ❌ |
| muted  | 4.83:1 ✅    | 3.88:1 ❌ |

**The failure this table prevents:** every link on your site becoming a low-contrast smudge for the half of your audience on dark mode — the exact people the feature was *for*. Nobody caught it because the author previews in light mode and the reviewer said "fine."

## The fix: override the accent, don't reuse it

The instinct is to hunt for one magic blue that passes on both backgrounds. I tried. There isn't one — a blue light enough for the dark background is too light for the white one:

```
#0066cc   light 5.57:1 PASS   dark 3.37:1 FAIL
#3b9dff   light 2.82:1 FAIL   dark 6.65:1 PASS
#4da3ff   light 2.63:1 FAIL   dark 7.14:1 PASS
#6cb6ff   light 2.15:1 FAIL   dark 8.72:1 PASS
```

So stop looking for the one ring. The accent is a *value*, and the dark block already exists to override values. Give it a lighter blue there — exactly like `--bg` and `--fg` already flip:

```
== dark theme, values OVERRIDDEN (the fix) ==
accent   #6cb6ff on #121212   8.72:1  PASS
muted    #8b93a1 on #121212   6.05:1  PASS
```

`#0066cc` in light (5.57:1 ✅), `#6cb6ff` in dark (8.72:1 ✅). Two values, one variable, both legible. That's what the two "NOT the light accent" comments in the dozen-line snippet are doing.

**You'll know it worked when** you run the checker with *both* theme's values and get PASS on every row — not when the page merely turns dark.

## Three edge cases I ran on purpose

The persona rule is that I escalate to absurdity and run it anyway, and the third one finds a real bug.

1. **The lazy-invert assumption survives.** The comforting theory is "if I invert the background I've inverted the legibility." I checked: body text `#e6e6e6` on `#1a1a1a` is **13.94:1**, still miles clear. Grudging respect — for *high-contrast* pairs the assumption holds. It only breaks in the mid-tones, which is precisely where accents live.
2. **Pure black on pure white is 21.00:1**, the theoretical maximum, and pure white on pure black is *also* 21.00:1. Symmetric. The maximum is not where anyone gets hurt; nobody ships `#000`-on-`#fff` and fails an audit. The danger is always the tasteful mid-tone.
3. **The "accessible gray" trap (the real bug).** `#767676` is the gray people memorize as "the lightest gray that passes on white" — and it does, at **4.54:1**, by a hair. Reuse that same trusted gray on the dark theme and it lands at **4.12:1** — *fail*. The number you memorized is a number about one background. It does not travel. That's the whole lesson in one hex code.

## When this goes wrong (honestly)

- **I did not render this in a browser.** The contrast math is real and executed; the *visual* is not a screenshot because a terminal computed the verdict. If you want the picture, paste the hexes into any WebAIM-style contrast checker — you'll get the same ratios, because it's the same WCAG formula.
- **`prefers-color-scheme` follows the OS, not a button.** If you want an in-page toggle you're back to a JS class, which reintroduces the flash-of-wrong-theme on load. I didn't test that path here; it's a different hack.
- **`color-scheme: light dark;` matters more than it looks.** Without it, native form controls and scrollbars stay light-mode while your custom-property surfaces go dark — a two-tone page that passes no vibe check and, worse, a light `<input>` you didn't contrast-test at all.

## Verdict, on the survives-a-Tuesday scale

The twelve-line technique **survives a normal Tuesday** — it's correct, minimal, and re-themes with no JS. But "dark mode: done" **does not survive a bad Tuesday**, the one where a low-vision user on dark mode tries to read a 3.37:1 link, because *turning the page dark and making the page readable are two separate checkmarks* and the build only ticks the first. Run the second checkmark. It's four lines of `awk` and it already told you the answer.
</content>
</invoke>
