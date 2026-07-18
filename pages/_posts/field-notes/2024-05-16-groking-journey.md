---
title: "What Grok Made of My Jekyll Site: An AI Site-Review Field Note"
description: "I asked Grok to review my Jekyll site. It described a generic blog it could not have seen, in seven confident bullet points. A note on AI flattery."
date: 2024-05-16
categories: [Field Notes]
tags: [ai, jekyll]
author: amr
excerpt: "An AI reviewed my site without looking at it, praised a banner that doesn't exist, and called it a positive user experience. Here is what that's worth."
preview: /images/previews/what-grok-made-of-my-jekyll-site-an-ai-site-review.png
---
I asked Grok to review my site. I wanted an outside opinion on [it-journey.dev](https://it-journey.dev) — the layout, the navigation, whether the thing read as a real developer blog or a pile of half-finished drafts wearing a theme.

What I got back was warm, fluent, well-organized, and about a site I do not have.

That gap is the whole post. This is not a UX audit — Grok ran no audit, clicked nothing, measured nothing. It is an essay about what an AI says when you point it at a URL and ask it to be helpful, and why "well-organized and confident" is not the same as "true."

## What it told me

I'll quote the model rather than paraphrase, because the texture matters. Asked about the site, Grok produced a tidy summary and then, unprompted, "some of the UI features of this site":

> 1. **Homepage Banner**: The homepage features a banner image, a navigation menu, and a list of blog posts. The banner image sets the tone for the site...
> 2. **Navigation Menu**: ...links to the homepage, an archive of previous posts, and an about page.
> 3. **Blog Post List**: ...the most recent post at the top. Each post includes a title, a brief excerpt, and a link to the full post.
> 4. **About Page**: ...information about the author and their background in the IT industry.
> 5. **Responsive Design**...
> 6. **Clean and Simple Design**...
> 7. **Fast Load Times**...

It closed with a verdict: "These UI features contribute to a positive user experience and effectively showcase the author's expertise in the IT industry."

Read it cold and it sounds like a review. Read it knowing the site and it falls apart.

## The part where it broke

Here is the problem with the banner: there isn't one. My homepage does not open with a hero image. The nav does not have an "archive of previous posts" link — it has a docs tree and a quest log, neither of which appears anywhere in the summary. The "About Page" with "background in the IT industry" is a paraphrase of a stock blog, not mine.

Grok did not look at the site. It could not have — it had a URL and a sentence saying the site uses Jekyll and Bootstrap, and from those two facts it reconstructed the *average* Jekyll-and-Bootstrap blog and handed it back to me as if it had visited. Banner, nav, post list, about page, responsive, clean, fast: that is not a description of it-journey.dev. That is a description of the median result you'd get if you typed "Jekyll Bootstrap personal blog" into an image generator. The model filled in the blanks with the most statistically likely blog, and every blank it filled was a guess wearing the costume of an observation.

I want to be precise about what's wrong here, because "the AI hallucinated" undersells it. Nothing it said was *outrageous*. Every bullet is a thing a Jekyll blog plausibly has. That's exactly what makes it dangerous as a review: it is wrong in the register of being right. A claim like "the banner image sets the tone for the site" is unfalsifiable-sounding flattery that happens to be false, and it is false in a way you'd only catch if you already knew the answer — at which point you didn't need the review.

## "Positive user experience" is doing no work

The closing verdict is the tell. "These UI features contribute to a positive user experience" — measured how? Against what? Grok ran no session recording, watched no user fail to find the nav, timed no load. "Fast load times" is asserted from the *premise* that the site uses a static generator, not from a measurement of the site. The reasoning runs: static sites are usually fast, therefore this site is fast, therefore positive user experience. Each arrow is plausible. None of them touched the actual page.

This is the productivity-tool failure mode in miniature. You ask a machine to save you the work of looking, and it saves you the work of looking by not looking, then reports back in the confident prose of someone who looked. The output is shaped exactly like a review. It has bullet points. It has a summary and a verdict. It has the *form* of having been earned. What it doesn't have is contact with the thing it describes.

## So is it useless?

No — and this is the honest part. The exercise was worth doing, just not for the reason I started it.

What Grok actually gave me was a mirror of the genre. It told me what a generic Jekyll developer blog looks like to a model that has read ten thousand of them. And a few of those generic features were genuinely missing from my site: my "about" page really was thin, my post excerpts really were inconsistent. The model couldn't see my site, so it described the platonic one — and the gap between the platonic blog and mine was a to-do list I hadn't written yet.

That's a real use. Just not the one on the label. "Review my specific site" got me nothing. "Describe the average site of this type, so I can diff against it" got me a backlog. The trick is knowing which question the model is actually answering, which is rarely the one you asked.

## What I'd tell the next person who does this

- An AI given a URL and no real fetch will describe the *category*, not the *page*. Treat the output as a description of the genre until proven otherwise.
- Confidence is free. The model is exactly as fluent when it's guessing as when it knows. Tone carries zero information about accuracy.
- The bug isn't the wrong claim; it's the wrong claim that sounds like every right claim. Verify the parts you could only verify if you already knew them — those are where it's bluffing.
- If you want a real review, paste the real thing: the actual HTML, a screenshot, the rendered page. Don't make it reconstruct your site from a noun.

I kept the transcript. It's a good artifact — a perfectly competent review of a website that does not exist, written about mine. The most human thing the model did all day was answer a question it hadn't done the reading for.

---

*More on the sister site: the actual, non-hallucinated site Grok was supposed to be looking at lives at [it-journey.dev](https://it-journey.dev) — same theme as this one, opposite temperament.*
