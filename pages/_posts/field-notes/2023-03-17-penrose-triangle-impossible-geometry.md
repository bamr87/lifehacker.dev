---
title: "Drawing the Impossible: A Penrose Triangle in Hand-Written SVG"
description: "I tried to hand-code a Penrose triangle in raw SVG. The obvious version is two crossing triangles, not an impossible object — here's what the illusion needs."
date: 2023-03-17
categories: [Field Notes]
tags: [jekyll]
author: amr
excerpt: "I thought I could type an impossible shape into a text editor. The shape had opinions about that."
preview: /assets/svg/penrose-amr.svg
---
![Drawing the Impossible: A Penrose Triangle in Hand-Written SVG](/assets/svg/penrose-amr.svg)

The Penrose triangle is the shape your eye agrees to before your brain checks the receipt. Three beams, each one passing in front of the next, around a loop that never closes the way it pretends to. It is on the [Wikipedia page for impossible objects](https://en.wikipedia.org/wiki/Penrose_triangle) and on roughly every album cover that wants to look clever. I wanted one. I wanted to type it, in raw SVG, like a person who knows what they're doing.

I do not know what I'm doing. That's the post.

## The version that should have worked

Here is the first thing I wrote. Two triangles, a gradient fill, a clip-path to keep it tidy. It looks, in the editor, like the kind of thing that draws a Penrose triangle.

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <defs>
    <linearGradient id="gradient" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#FF7F00" />
      <stop offset="100%" stop-color="#FF00FF" />
    </linearGradient>
    <clipPath id="clip">
      <polygon points="0,400 400,400 200,0" />
    </clipPath>
  </defs>
  <g clip-path="url(#clip)">
    <rect x="0" y="0" width="400" height="400" fill="url(#gradient)" />
    <polygon points="200,300 350,150 50,150" fill="none" stroke="#FFFFFF" stroke-width="10" stroke-linejoin="round" />
    <polygon points="200,100 350,250 50,250" fill="none" stroke="#FFFFFF" stroke-width="10" stroke-linejoin="round" />
  </g>
</svg>
```

It does not draw a Penrose triangle.

Read the two polygons by their coordinates and you'll see it before any browser does. The first points down: `200,300` is the bottom tip, `350,150` and `50,150` are the upper corners. The second points up: `200,100` is the apex, `350,250` and `50,250` are the lower corners. Two triangles, one inverted, sharing the middle. That's a hexagram — a Star of David — not an impossible object. Then the clip-path (a single big triangle, apex at top, base along the bottom) crops off the parts that stick out, so you don't even get the clean star. You get a gradient blob with some white lines in it and a story you told yourself about beams.

I'd written the outline of a different shape and labeled it with the name of the one I wanted. The label was doing all the work.

## Why the easy version can't work

The thing that makes a Penrose triangle impossible is the thing that makes it hard to type: there is no consistent 3D object behind it. Each beam has to read as *in front of* the next one, all the way around the loop, which means the illusion lives entirely in the overlaps — in which line stops short so another can pass over it. You can't get that from two closed `<polygon>` outlines. A closed polygon has no opinion about what's in front of what. The depth is a lie you have to draw on purpose, joint by joint, with little gaps where one beam ducks behind the next.

So the real construction isn't "two triangles." It's three thick L-shaped or chevron beams, each drawn as its own filled path, stacked in a deliberate order so the seams line up into a loop that the eye closes and the geometry doesn't. The version sitting at the top of this post — the one in the front matter, the little icon — is built that way: separate filled paths in Inkscape, nudged by hand until the three corners hand off to each other. It's the same logic, done with shapes that can carry the deception. The two-triangle snippet was me hoping the illusion would emerge from simplicity. It doesn't. The illusion *is* the complexity.

## What I kept, and what I'm leaving in

I'm leaving the broken snippet in, because the broken snippet is the lesson. A shape can validate, render, fill, and clip perfectly and still not be the shape you named. SVG will faithfully draw exactly what you said, which is a problem when what you said and what you meant are two different figures. The compiler for geometry is your own eyes, and they'll wave a hexagram through if you've already decided it's a triangle.

A few honest notes on the rest:

- **I have not rendered the snippet here.** I read its coordinates and reasoned out the figure; I didn't rasterize it in this writeup, so take "hexagram, partly clipped" as a claim about the math, not a screenshot.
- **The hero image is real.** That icon is a hand-built Inkscape file (`penrose-amr.svg`), the same one that's flown over on the sister site for a while. It's vector, it scales, and it took a lot more than two polygons.
- **Inkscape did the heavy lifting.** I started in a text editor out of pride and finished in a GUI out of necessity, which is roughly the arc of every "I'll just hand-code it" afternoon.

The Penrose triangle works because it makes a promise — *these three beams connect* — that no single viewing angle can keep, and your visual system signs off anyway. Typing one taught me the same thing on a smaller scale: the cleanest-looking code is the easiest place to hide a shape that isn't there.
