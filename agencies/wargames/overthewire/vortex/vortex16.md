---
title: "Vortex Level 16"
description: "Vortex Level 16 — find 100 bits out of a 128-bit randomly generated hashed key, a partial hash-matching problem."
excerpt: "Vortex Level 16 — find 100 bits out of a 128-bit randomly generated hashed key, a partial hash-matching problem."
permalink: /docs/wargames/vortex/vortex16/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/vortex/vortex16.md
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
nav_order: 16
sidebar_label: "Level 16"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

The BOFH
--------
This level requires finding 100 bits out of a 128 bit randomly generated hashed key. You must login to [vortex.labs.overthewire.org][] to complete this level.

[vortex.labs.overthewire.org]: ssh://vortex.labs.overthewire.org:2228

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `vortex16`, obtain access to `vortex17`.
</div>

### What this level teaches

The cost and structure of partial hash search.

### Key ideas

- **The task as stated.** The page describes it as finding 100 bits out of a randomly generated, hashed 128-bit key. Read the level's code to see exactly which bits must match and what you control.
- **Cost estimation.** Matching fewer bits is exponentially cheaper than matching all of them: each extra required bit roughly doubles the expected work.
- **Speed.** Efficient C and parallel search make the difference between hours and years.

### How to approach it

1. Read exactly what must match, and how many bits.
2. Estimate expected work for the plan you choose.
3. Implement and benchmark on smaller bit counts first.

### Why it matters

It illustrates truncated hashes and why a short checksum gives only weak assurance.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../vortex15/">Level 15</a><a class="sg-index" href="../">Vortex overview</a><a class="sg-next" href="../vortex17/">Level 17</a></nav>

</section>

<!-- study-guide:end -->
