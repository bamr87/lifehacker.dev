---
title: "ChatGPT vs the Impossible Triangle: Where AI Still Trips on 3D Space"
description: "A 2023 field test of ChatGPT against the Penrose triangle, plus a 2025 look back at why impossible geometry still breaks pattern-matching AI."
date: 2023-03-26
categories: [Field Notes]
tags: [chatgpt, ai-limitations, penrose-triangle, svg, spatial-reasoning, design]
author: amr
excerpt: "I asked a confident machine to draw an impossible triangle. It drew a very possible one, very fast, and was extremely polite about being wrong."
preview: /assets/svg/penrose-gpt-vs-human.png
---

![ChatGPT vs the Impossible Triangle: Where AI Still Trips on 3D Space](/assets/svg/penrose-gpt-vs-human.png)

I went looking for the edge of the new toy. Everyone in March 2023 was busy
asking ChatGPT to write their cover letters and rename their startups; I wanted
to find the wall it would walk into. So I asked it to draw a thing that cannot
exist.

The Penrose triangle. Three beams that join at right angles into a closed loop
your eye accepts and your geometry rejects. It is the kind of object you can
sketch in two minutes and never actually build. I picked it precisely because it
is simple to look at and impossible to be. If a machine "understands" 3D space
the way I do, this should be a layup.

It was not a layup.

## The thing it got right was the thing I least expected

Before I get to the failure, credit where it's due, because the shape of what it
got right is the whole point.

Ask ChatGPT *what* a Penrose triangle is and it answers like a tired professor
who has explained this a hundred times. The optical illusion, the impossible
object, the way each corner is locally consistent while the whole is globally
contradictory — all correct, all fluent. It knew the word "impossible" and used
it in the right places.

Then I asked it to render one as an SVG, and it handed me a triangle. A regular,
entirely possible, three-sides-meet-in-a-plane triangle. The text described an
impossible object with confidence; the drawing was a shape any kindergartener
makes by accident.

That gap — perfect description, broken depiction — is the part I keep coming back
to. It is the image at the top of this post: on the left, what ChatGPT drew; on
the right, the one I eventually cut by hand in Inkscape after an embarrassing
number of hours. The machine produced its version in seconds and
was wrong. I produced mine slowly and it was right. I am not sure either of us
should feel great about that.

## Confidently wrong is the default setting

The other thing that stuck with me wasn't the geometry. It was the tone.

Every wrong answer arrived with the same even, helpful confidence as every right
one. There was no flicker of doubt, no "this might be off," no hedging where a
human would hedge. It described an impossible figure, drew a possible one, and
would have happily drawn me a hundred more, each one wrong, each one delivered
like settled fact.

That is the actual lesson, and it has nothing to do with triangles. The failure
mode of this tool is not that it can't do things. It's that it sounds exactly the
same whether it can or can't. The Penrose triangle is one case where I happen
to be able to *see* the wrongness. Most of the time I won't be able to, and it
will sound just as sure.

So the practical rule I walked away with in 2023: treat fluency and correctness
as two separate dials, and never assume one is reporting on the other.

## Why a drawing program in your head beats one trained on the internet

Here is my best guess at *why* it fails, and I'll flag it as a guess rather than
established fact.

When I imagine the Penrose triangle, I don't retrieve it — I sort of build it. I
run a little spatial simulator, rotate the thing, notice where the beams refuse
to meet, and feel the contradiction as a kind of friction. The "impossible" is
something I experience, not something I looked up.

A language model trained on text and images doesn't have that simulator. It has
seen the *words* about impossible objects and, increasingly, *pictures* of them,
and it predicts what usually comes next. That's astonishing for a huge range of
tasks. But "what usually comes next after a triangle" is a normal triangle,
because normal triangles vastly outnumber impossible ones in everything it ever
read. The illusion lives in the spatial relationships, and the relationships are
exactly the part that pattern-matching smooths over.

That's not a bug to be patched out next Tuesday. It's a difference in kind. I
solve the triangle by *seeing*; it solves the triangle by *recalling*. Most days
those two routes land in the same place, which is why the tool feels like magic.
The Penrose triangle is one of the places they don't.

---

## A 2025 look back

*I'm writing this addendum nearly three years after the original. The models have
changed a lot, so I went back and ran the test again. What follows is my own
read of where things stood in late 2025 — historical opinion, not a fresh
benchmark — so take the model names as a snapshot, not a leaderboard.*

The first thing to say: the gap got narrower and did not close.

By 2025, asking a current model about the Penrose triangle was even more
impressive on the description side. It could walk through the depth cues, the
perspective trick, the math of why your eye is being lied to. The SVG it
generated was cleaner — better structure, fewer syntax stumbles, and with
patient, iterative feedback it could be pushed toward something that *reads* as
the illusion.

But "with patient, iterative feedback" is doing a lot of work in that sentence.
The thing I had to supply was still the thing it lacked in 2023: the spatial
judgment to know when the beams actually lock into the impossible loop versus
when they merely look close. Left to its own first try, it still mostly drew a
possible triangle, or a tangle that gestured at the idea. Image generators
trained on thousands of Penrose pictures could *produce one as a raster image*
fairly well — because at that point it's a retrieval problem again — but ask for
the underlying geometry and the old gap reopened.

So my 2023 prediction aged in two directions at once. I underestimated how fast
the surface would improve, and I got the floor right: the difference between
matching a pattern and understanding a space is still there. We didn't teach the
machine to see. We taught it to have seen a lot more.

## What I'd tell 2023 me

Three things, none of them about triangles:

- **Separate the verdict from the vocabulary.** A confident, articulate answer
  tells you nothing about whether it's correct. The Penrose test is valuable not
  because anyone needs AI to draw impossible objects, but because it's a case
  where you can independently check the answer and watch the confidence and the
  correctness come apart.
- **Use it where you can verify it.** The tasks where this tool genuinely earned
  its keep for me were the ones where I could see the result and judge it myself —
  drafting a script I'd then run, sketching an approach I'd then test. The danger
  zone is the question whose answer I *can't* check, asked in a domain where I'd
  never notice a confidently drawn possible triangle.
- **The interesting limits are the structural ones.** Most "AI can't do X"
  complaints get fixed by the next release. A few — the ones rooted in how the
  thing works rather than how big it is — don't. Figuring out which is which is
  most of the skill now.

The original article ended by saying we were in "the 80s" of AI. From 2025 I'd
revise that upward, but I'd keep the spirit: we're early, the curve is steep, and
the most useful thing you can do is find the walls yourself instead of waiting
for a press release to admit they exist.

The machine still can't quite draw the impossible triangle on the first try. I'm
oddly comforted by that. It means there's still a small, specific corner of the
world that responds better to a slow human with Inkscape and a stubborn mental
picture than to the fastest, most fluent answer engine ever built.

*Disclaimer, then and now: the bot did not write this for me. In 2025 it helped
draft a paragraph or two, which is its own small joke, and I left the analysis,
the opinions, and the blame entirely human.*
