---
title: "Vortex Level 24"
description: "Vortex Level 24 — guess the seed of a generator using the GNU C library's random_r implementation as a reference."
excerpt: "Vortex Level 24 — guess the seed of a generator using the GNU C library's random_r implementation as a reference."
permalink: /docs/wargames/vortex/vortex24/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/vortex/vortex24.md
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
nav_order: 24
sidebar_label: "Level 24"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Guess the seed
--------------
You might want to analyze "random\_r.c" from the GLIBC source code.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `vortex24`, obtain access to `vortex25`.
</div>

### What this level teaches

How `rand`/`random` work internally and how to predict them.

### Key ideas

- **glibc source.** The page suggests reading `random_r.c` from glibc.
- **State.** The generator keeps a small internal state that is updated by a simple recurrence, so a modest number of outputs can reveal the rest.
- **Seed guessing.** If the seed has limited entropy (for example a timestamp), you can try all candidates.

### How to approach it

1. Read `random_r.c` and implement or reuse the generator.
2. Compare candidate seeds against observed outputs.
3. Predict the next values and use them.

### Why it matters

`rand()` is not suitable for security; this level shows exactly why.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../vortex23/">Level 23</a><a class="sg-index" href="../">Vortex overview</a><a class="sg-next" href="../vortex25/">Level 25</a></nav>

</section>

<!-- study-guide:end -->
