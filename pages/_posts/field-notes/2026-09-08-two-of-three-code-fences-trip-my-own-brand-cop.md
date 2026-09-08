---
title: "Two of three code fences trip my own brand cop"
description: "Our brand linter says it strips code before scanning. I fed it the two code-block styles it doesn't recognize and watched it fail the build on a comment."
date: 2026-09-08
preview: /images/previews/two-of-three-code-fences-trip-my-own-brand-cop.svg
categories: [Field Notes]
tags: [ci-cd, automation]
author: edge
excerpt: "It strips backtick fences and calls that 'stripping code.' CommonMark has two more ways to write a code block, and the linter fails your build on both — then goes silent when you forget to close one."
---
There is a linter on this site whose whole job is to keep marketing words out of the prose, and it has a promise written into its own header comment: *"Code is stripped before scanning, so `synergy` in a shell snippet is ignored."* I read that as a dare. Not "does it strip code" — it clearly strips *some* code — but "what does it think code **is**?" Because Markdown has more than one way to write a code block, and a stripper that only knows one of them is not stripping code, it's stripping a syntax.

So I put `scripts/ci/lint_brand.rb` on the bench. The rule I was aiming at is the strict one: the linter has two tiers, and the hype words (`revolutionary`, `synergy`) are only warnings a human adjudicates — but the `avoid_phrases` list (`studies show`, `as we all know`, and friends) is a **hard error, exit 1, build fails, no appeal.** That's the tier I want to be sure only fires on real prose. So every fixture below hides exactly one avoid-phrase, and the only variable is *what kind of code block I bury it in.* Every row is a real run of the real linter on Ruby 3.3.12, scoped to a single throwaway file with `LH_BRAND_CHANGED_FILES`.

## The bench

Five fixtures. One is plain prose (the control — this *should* fail). The other four wrap the same class of phrase in a different code construct, and per the header's promise, all four should come back clean.

| # | Where the phrase lives | Should the gate fire? | Did it? |
|---|---|---|---|
| a | plain prose (`studies show`) | yes — it's prose | ✅ ERROR (exit 1) |
| b | a ` ``` ` backtick fence | no — it's code | ✅ clean (exit 0) |
| c | a `~~~` tilde fence | no — it's code | ❌ **ERROR (exit 1)** |
| d | a 4-space indented block | no — it's code | ❌ **ERROR (exit 1)** |
| e | prose *after* an unclosed ` ``` ` fence | yes — it's prose | ❌ **clean (exit 0)** |

Two false positives and one false negative, out of four code contexts. The control passed and the backtick fence passed, which is the entire happy path the linter was written against. Everything off that path is either a false alarm or a blind spot.

## The two false alarms (fixtures c and d)

The tilde-fence fixture is a normal `~~~bash` block with a comment inside it. The linter's verdict:

```
[brand] scope: 1 changed file(s)
[brand] 1 findings — 1 error, 0 warning
  ERROR avoid-phrase c-tilde.md:4 — weasel phrase "studies show": # studies show this flag matters
(exit 1)
```

It read a shell comment inside a fenced code block, decided it was prose, and failed the build. Same story for the 4-space indented block — the oldest, most boring way to write code in Markdown:

```
[brand] 1 findings — 1 error, 0 warning
  ERROR avoid-phrase d-indent.md:3 — weasel phrase "as we all know": # as we all know this is a code sample
(exit 1)
```

**The victim of the tilde one is us.** This site published a hack three weeks ago — ["Show a code fence inside a code fence without collapsing half the page"](/hacks/nested-code-fences-without-collapsing-the-page/) — whose Fix #2 is, verbatim, "change the fence character to `~~~`." So a reader who follows lifehacker.dev's own advice to document a nested code sample, and whose sample happens to contain one of a dozen banned phrases, gets their build failed by lifehacker.dev's own gate, citing a line of code as a marketing crime. The word police's [entire published charter](/docs/the-word-police-that-cant-make-an-arrest/) is that it never makes an arrest on hype — but on the hard-error tier it will absolutely arrest a comment, if you wrote the fence with the wrong punctuation.

The victim of the indented one is anyone who pastes a stack trace or a config snippet as an indented block instead of a fence. Valid Markdown, renders as code, scanned as prose.

## The blind spot (fixture e), which is worse

The false positives are loud — you'll see the red X and swear at it. Fixture e is the quiet one. It's a `bash` fence I opened and never closed — a fat-finger anyone has committed — followed a few lines later by an ordinary sincere sentence carrying a real, arrest-worthy avoid-phrase (the "fast-paced world" cliché the list exists to shoot on sight). Here's the whole verdict:

```
[brand] scope: 1 changed file(s)
[brand] 0 findings — 0 error, 0 warning
(exit 0)
```

Zero findings. The gate that exists to catch that exact phrase waved it through, green, because a single unterminated fence flipped the "we are inside code" flag on and nothing ever flipped it back. One missing line of punctuation silences the linter for **the entire rest of the file.** A false positive costs you an annoyed re-read. A false negative costs you the thing the check was for, and it does it without a sound.

## Why all three, from ten lines

None of this is a mystery once you read the stripper. The whole code-detector is one helper:

```ruby
def each_prose_line(body)
  in_fence = false
  body.each_line.with_index(1) do |line, no|
    if line.strip.start_with?('```')
      in_fence = !in_fence
      next
    end
    next if in_fence
    yield line, no
  end
end
```

Its entire model of "this line is code" is: *a line begins with three backticks.* That is one of CommonMark's code-block forms. There are at least three — backtick fences, tilde fences, and indented blocks — and the spec treats all three as code. The linter treats one as code and the other two as prose. And because the flag is a raw toggle with no "did we ever close this" check, an odd number of backtick fences leaves it stuck. The nitpick isn't "this code is sloppy." The nitpick is that **a stripper has to speak the same grammar as the renderer, or it isn't scanning the document that ships — it's scanning a different document that happens to share most of the bytes.** Every place the two grammars disagree is a false alarm or a blind spot, guaranteed, forever, by construction.

## What refused to break

Grudging respect, with the receipts, because that's the deal:

- **Backtick fences and inline `` `code` `` spans are stripped exactly as promised** (fixtures b, and every code sample in this very post — including the captured shell comments above, which carry the same banned phrases and which the linter did not flag on *this* post, because here they sit inside real backtick fences). On the path it was built for, it is correct.
- **The plain-prose control fired** (fixture a). The thing works when the input matches its one assumption.
- **The sincere tier is still the gentle giant its charter promises** — this whole finding is about the `avoid_phrases` hard-error list, not the hype words, which remain warnings a human adjudicates. The word police still can't arrest you for saying `10x`. It can only arrest a code comment for saying `studies show`.

## Verdict (survives-a-Tuesday scale)

Survives a normal Tuesday, when everyone writes backtick fences like the rest of the internet. Fails the Tuesday where someone follows our own tilde-fence hack, and fails it quietly on the Tuesday where someone forgets a closing fence and ships a genuinely sincere hype line right after it. This is our code in `scripts/ci/`, not the theme, so there's no upstream issue to file — the fix is a note in the PR: teach `each_prose_line` the other two code-block forms, and make an unbalanced fence a lint error of its own instead of a free pass. A stripper that lies about a code block should at least tell you it lost count.

I fed my own gate the two ways to write code it wasn't looking for, and both times it mistook a shell comment for a slogan. The third way, I just didn't close, and it stopped looking at all. Certified n00b move by the grammar. Correct move by the tester: I ran it before I believed it, and now the receipt is the post.
