---
title: "Vortex Level 11"
description: "Vortex Level 11 — corrupt the heap to gain arbitrary control of a program that uses the phkmalloc allocator."
excerpt: "Vortex Level 11 — corrupt the heap to gain arbitrary control of a program that uses the phkmalloc allocator."
permalink: /docs/wargames/vortex/vortex11/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- vortex
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/vortex/vortex11.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- vortex
author: bamr87
nav_order: 11
sidebar_label: "Level 11"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Chunk Corruption
----------------
You must corrupt the heap in order to gain arbitrary control of this program. Do recall, the application is using phkmalloc.

Reading Material
----------------
- [BSD Heap Smashing][]
- [Once upon a free()][]
- [Advanced Doug Lea's malloc exploits][]
- [Exploiting the Wilderness][]




[BSD Heap Smashing]: http://www.ouah.org/BSD-heap-smashing.txt
[Once upon a free()]: http://www.phrack.org/issues.html?issue=57&id=9#article
[Advanced Doug Lea's malloc exploits]: http://www.phrack.org/issues.html?issue=61&id=6#article
[Exploiting the Wilderness]: http://archive.cert.uni-stuttgart.de/vuln-dev/2004/02/msg00025.html

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `vortex11`, obtain access to `vortex12`.
</div>

### What this level teaches

Heap exploitation against a specific allocator.

### Key ideas

- **The heap.** Dynamically allocated memory managed by an allocator that keeps its own metadata.
- **phkmalloc.** The BSD allocator named in the level; its structure determines which corruptions are useful.
- **Chunk corruption.** Overflowing one allocation into a neighbour's metadata can turn later allocator operations into controlled writes.
- **Reading.** The page lists BSD heap smashing, "Once upon a free()", Doug Lea malloc exploits and "Exploiting the Wilderness".

### How to approach it

1. Read the papers and then the allocator's behaviour in this program.
2. Map how allocations are laid out for a given input.
3. Craft the overflow and confirm its effect in a debugger.

### Why it matters

Heap bugs dominate modern vulnerability reports, and the techniques follow the same ideas.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../vortex10/">Level 10</a><a class="sg-index" href="../">Vortex overview</a><a class="sg-next" href="../vortex12/">Level 12</a></nav>

</section>

<!-- study-guide:end -->
