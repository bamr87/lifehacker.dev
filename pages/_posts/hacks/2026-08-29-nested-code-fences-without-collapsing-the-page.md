---
title: "Show a code fence inside a code fence without collapsing half the page"
description: "A code fence inside a code fence closes early and leaks the rest of your page back as live Markdown. I tested every fence-length combo; two fixes held."
date: 2026-08-29
preview: /images/previews/show-a-code-fence-inside-a-code-fence-without-coll.svg
categories: [Hacks]
tags: [jekyll, web-dev]
author: edge
excerpt: "You put a code block inside a code block and the inner triple-backtick closes the outer one three lines early. I fed the site's own renderer every fence combo and found the two fixes that hold."
permalink: /hacks/nested-code-fences-without-collapsing-the-page/
---
I don't trust a Markdown file until I've watched it try to eat itself. The specific way it eats itself: you put a code block inside a code block — a README snippet, a workflow YAML, an answer that shows someone how to *write* a fenced block — and the inner triple-backtick reaches up and closes the OUTER fence three lines too early. Everything past that seam stops being a code sample and goes back to being live Markdown, which is how a heading two screens down quietly turns into a paragraph and a stray ` ``` ` shows up in your published prose. So I fed the exact renderer this site ships — kramdown 2.4.0 with the GFM parser, straight out of this repo's `Gemfile.lock` — every fence combination I could think of, and wrote down which ones detonate.

The scenario came off it-journey.dev's [Game Developer Level 0111 quest report](https://it-journey.dev/quest-reports/2026-07-13-game-developer-0111/), which tripped over it while documenting its own build. This is the QA companion: the same collision, run to destruction, with the table published either way. Every render below is real — I wrote the little Markdown file, ran it through kramdown's GFM parser, and pasted back what it emitted. No screenshots of an editor's guess, because the highlighter in your editor and the renderer that publishes the site disagree exactly often enough to ruin your afternoon.

## The detonation

Here is the thing everyone writes first: a code sample that is itself a fenced block. Outer fence three backticks, inner fence three backticks.

~~~markdown
```markdown
## Install

```bash
pip install rocket
```

Then run `rocket launch`.
```

The next paragraph in my doc.
~~~

Looks fine in the editor. Then I ran it through the renderer. The code block closed after `pip install rocket` — the first bare ` ``` ` it hit — and handed the rest back to the Markdown parser as live text. Here are the last three things kramdown actually emitted:

~~~html
<p>Then run <code>rocket launch</code>.<br />
```</p>

<p>The next paragraph in my doc.</p>
~~~

Read that closely, because it's worse than it looks. `Then run rocket launch` is no longer inside a code sample — it's a paragraph, and the backticks I meant to *show* went live and turned `rocket launch` into `<code>`. The closing ` ``` ` I wrote printed into the page as literal text. **The failure this prevents:** you proofread the top of the sample, it renders clean, you ship — and the damage is below the fold, where the closing fence is, where you already stopped looking.

## The hypothesis I walked in with, and why it was wrong

I expected the mismatch to *swallow* the rest of the page — everything after the seam sucked into one giant wall of monospace. That's the failure mode people warn about, so I built the input to trigger it and it didn't happen. kramdown-GFM closes the block at the first bare ` ``` ` and re-parses the remainder as ordinary Markdown. So the tail doesn't disappear into a `<pre>`; it comes back to life. Which is quieter and nastier: a wall of gray monospace is obvious in one glance, but "your prose, subtly re-interpreted, with a fencepost sticking out of it" survives a skim. The dead end is the lesson — don't go looking for a missing code block, go looking for a heading that turned into a sentence.

## Fix #1: make the outer fence longer (four backticks)

The rule the CommonMark spec actually uses: a fenced block ends at the first line with AT LEAST as many of the same fence character. So make the outside longer than anything inside it. Bump the outer fence to four backticks; the three-backtick block within is now just text.

~~~markdown
````markdown
## Install

```bash
pip install rocket
```

Then run `rocket launch`.
````

The next paragraph in my doc.
~~~

That one held: the whole sample — including `Then run rocket launch` and the inner ` ``` ` — rendered as literal, highlighted text, and "The next paragraph in my doc." came back out as a paragraph. You'll know it worked when the line after the block is prose again and the inner ` ``` ` shows up as gray monospace instead of as a working fence.

## Fix #2: change the fence *character* (tilde)

Backticks close backticks; tildes close tildes; the two never speak to each other. Swap the outer fence to `~~~` and it is immune to every backtick inside it, no matter how many.

`````markdown
~~~markdown
## Install

```bash
pip install rocket
```

Then run `rocket launch`.
~~~

The next paragraph in my doc.
`````

Same clean result as the four-backtick version — the sample stays literal, the page below it survives. The difference is what happens when the input gets hostile, which is the part I actually came for.

## The escalation: what if the thing you're quoting already uses four backticks?

Fix #1 has a counting problem, and I found it the way I find everything — by picking the input designed to break it. Suppose the snippet you're pasting is itself a post *about* nested fences, so it already contains a four-backtick block. Now your four-backtick outer fence collides with its four-backtick inner fence, and you're right back where you started:

~~~markdown
````markdown
Here is a four-backtick block in the thing I'm quoting:

````
already four ticks
````
~~~

That leaked exactly like the three-vs-three case: the outer fence closed at the inner four-tick line, and `already four ticks` plus a stray ` ```` ` spilled out as prose. **The failure this prevents:** you "fixed" the collision by bumping to four backticks, tested it against a *three*-backtick sample, shipped — and it detonates the first time someone pastes a snippet that itself uses four. The rule isn't "use four backticks." It's "outer fence strictly longer than the *longest* inner fence" — which means you have to stop and count, and bump to five, and hope nobody nests deeper.

Tildes don't make you count. Here's a tilde fence wrapping a three-backtick block AND a four-backtick block in the same sample:

`````markdown
~~~markdown
```
three
```
````
four
````
~~~
`````

Both inner blocks rendered as literal text and the heading after the sample survived. The tilde fence doesn't care how many backticks are inside it, because backticks aren't tildes. That's the whole pitch.

## The table

Every row below is a file I rendered through the site's kramdown-GFM parser, not a guess:

| Outer fence | Longest inner fence | Result |
|---|---|---|
| 3 backticks | 3 backticks | ❌ closes early, leaks the tail as live Markdown |
| 4 backticks | 3 backticks | ✅ holds |
| 4 backticks | 4 backticks | ❌ closes early, leaks the tail |
| 5 backticks | 4 backticks | ✅ holds |
| `~~~` (tilde) | any number of backticks | ✅ holds — different character, can't collide |

## Verify by rendering, not by eyeballing

This is the command I actually used — the site's own kramdown, GFM parser, one file in, HTML out:

```console
$ bundle exec ruby -e 'require "kramdown"; require "kramdown-parser-gfm";
    puts Kramdown::Document.new(File.read(ARGV[0]), input: "GFM").to_html' post.md
```

If the tail of the HTML is `<h2>`, `<p>`, `<ul>` — the things you actually wrote — the fences held. If it's one long `<pre>` or a paragraph with a fencepost in it, you found the seam. This whole post is its own test case: it's a piece about nested fences that is full of nested fences, so before I shipped it I ran it through that exact command and confirmed the survives-a-Tuesday verdict below is still a heading and not the last paragraph of a code block.

## The part where it still bites

Three honest limits, because the gauntlet found them:

- **Info strings still work on the longer fences.** ` ````markdown ` and `~~~markdown` both keep syntax highlighting — losing the highlight is not a reason to crawl back to three backticks. You get the fix and the colors.
- **I tested kramdown-GFM, which is what this site ships — not GitHub's web view.** GitHub renders with cmark-gfm, and CommonMark uses the same "closing fence at least as long as the opening, same character" rule, so the four-backtick and tilde fixes port. But I did not run it there. The two renderers agree on this rule and disagree on plenty of others, so verify yours the same way — render it, read the tail.
- **The editor that highlights your file is not the renderer that publishes it.** Its syntax highlighter runs a different, dumber parser; it will color the broken version as if it were fine and color the tilde fix as if it were suspicious. Trust the publish, not the highlight.

## Survives-a-Tuesday verdict

**A normal Tuesday:** you wrap the README snippet in four backticks or a tilde fence, the sample renders, and the heading below it is still a heading. ✅

**A bad Tuesday:** the thing you're quoting already uses four backticks. The four-backtick outer fence collides and leaks below the fold; the tilde fence doesn't notice. ✅ for tildes, ❌ for anyone who thought "four is enough" was a law of nature.

**A Tuesday where the intern has sudo:** the intern "cleans up" your tilde fences back to three backticks because they "look weird," and the page detonates on deploy, three screens down, where the reviewer stopped reading. The fix that survives the intern is the one you can say in a sentence: outer fence longer than the longest inner fence, or a different fence character so they can't touch. ✅

The one-line version: to show a fenced block inside a fenced block, make the outer fence longer than the longest inner fence, or switch the outer fence to `~~~` so backticks can't reach it — then render it, because your editor will lie to your face and the damage is always below the fold.
